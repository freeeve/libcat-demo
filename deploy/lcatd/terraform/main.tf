# Read-only lcatd cataloging demo (tasks/009): a single arm64 Lambda serving the
# libcatalog backend in LCATD_READ_ONLY mode, with the cataloging SPA embedded and the
# BIBFRAME grains bundled in the zip (in-memory doc store -- no DynamoDB, no S3). Fronted
# by an API Gateway v2 HTTP API on a custom subdomain. Writes are rejected by the backend
# (blob store + HTTP 403 guard), so exposing it publicly is safe.

locals {
  # Assemble the LCATD_* environment. Grains extract to /var/task/grains on Lambda.
  lambda_env = merge(
    {
      LCATD_READ_ONLY         = "1"
      LCATD_BLOB_DIR          = "/var/task/grains"
      LCATD_LOCAL_AUTH        = "1"
      LCATD_BOOTSTRAP_ADMIN   = var.demo_admin
      LCATD_LOCAL_SIGNING_KEY = var.local_signing_key
      LCATD_PROVIDER          = var.provider_name
    },
    var.abuse_secret == "" ? {} : { LCATD_ABUSE_SECRET = var.abuse_secret }
  )
}

# --- Lambda execution role: CloudWatch Logs only (grains-in-zip, no AWS data services).
data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "exec" {
  name               = "${var.name}-exec"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

resource "aws_iam_role_policy_attachment" "logs" {
  role       = aws_iam_role.exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_log_group" "fn" {
  name              = "/aws/lambda/${var.name}"
  retention_in_days = var.log_retention_days
}

# --- The function.
resource "aws_lambda_function" "api" {
  function_name    = var.name
  role             = aws_iam_role.exec.arn
  filename         = var.lambda_zip
  source_code_hash = filebase64sha256(var.lambda_zip)
  runtime          = "provided.al2023"
  handler          = "bootstrap"
  architectures    = ["arm64"]
  memory_size      = var.lambda_memory_mb
  timeout          = 30

  environment {
    variables = local.lambda_env
  }

  depends_on = [aws_cloudwatch_log_group.fn]
}

# --- API Gateway v2 HTTP API -> Lambda ($default catch-all proxy).
resource "aws_apigatewayv2_api" "api" {
  name          = var.name
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# --- Custom domain: ACM cert (DNS-validated in the evefreeman.com zone) + API mapping.
resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  zone_id         = var.hosted_zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}

resource "aws_apigatewayv2_domain_name" "domain" {
  domain_name = var.domain
  domain_name_configuration {
    certificate_arn = aws_acm_certificate_validation.cert.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_api_mapping" "map" {
  api_id      = aws_apigatewayv2_api.api.id
  domain_name = aws_apigatewayv2_domain_name.domain.id
  stage       = aws_apigatewayv2_stage.default.id
}

resource "aws_route53_record" "alias" {
  zone_id = var.hosted_zone_id
  name    = var.domain
  type    = "A"
  alias {
    name                   = aws_apigatewayv2_domain_name.domain.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.domain.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}
