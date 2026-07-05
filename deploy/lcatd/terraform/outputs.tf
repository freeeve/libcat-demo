output "demo_url" {
  description = "Public URL of the read-only cataloging demo."
  value       = "https://${var.domain}/"
}

output "api_endpoint" {
  description = "Default execute-api URL (works before DNS/cert propagate)."
  value       = aws_apigatewayv2_api.api.api_endpoint
}

output "demo_credential" {
  description = "Sign-in shown on the site (read-only, safe to publish)."
  value       = var.demo_admin
}
