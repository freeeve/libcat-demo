output "demo_url" {
  description = "Public URL of the read-only cataloging demo."
  value       = "https://${var.domain}/"
}

output "demo_credential" {
  description = "Sign-in shown on the site (read-only, safe to publish)."
  value       = var.demo_admin
}
