#!/usr/bin/env bash
# deploy.sh -- build + provision the read-only lcatd cataloging demo (tasks/009).
# Builds the Lambda zip (SPA + bundled grains), resolves the evefreeman.com Route 53
# zone, persists a STABLE signing key + abuse secret to a gitignored tfvars, then
# `terraform apply`. Extra args pass through to apply (e.g. -auto-approve).
#
#   AWS_PROFILE=deeplibby-admin deploy/lcatd/deploy.sh
#
# terraform apply provisions public infrastructure -- run it deliberately.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF="$HERE/terraform"
: "${AWS_PROFILE:=deeplibby-admin}"
export AWS_PROFILE

echo "==> building the deployment zip"
bash "$HERE/build.sh"

# Stable secrets live only in the gitignored tfvars so the signing key (and thus demo
# sessions) survive redeploys. Generate once, reuse thereafter.
VARS="$TF/terraform.tfvars"
if ! grep -q 'local_signing_key' "$VARS" 2>/dev/null; then
  ZONE="${HOSTED_ZONE_ID:-$(aws route53 list-hosted-zones-by-name --dns-name evefreeman.com \
    --query 'HostedZones[0].Id' --output text | sed 's#/hostedzone/##')}"
  {
    echo "hosted_zone_id    = \"$ZONE\""
    echo "local_signing_key = \"$(openssl rand -base64 32)\""
    echo "abuse_secret      = \"$(openssl rand -hex 32)\""
  } >"$VARS"
  echo "==> wrote $VARS (gitignored; stable signing key for $ZONE)"
fi

cd "$TF"
terraform init -input=false
terraform apply "$@"

echo
echo "Demo URL:   $(terraform output -raw demo_url)"
echo "Sign in as: $(terraform output -raw demo_credential)"
echo "(ACM validation + DNS can take a few minutes to go live.)"
