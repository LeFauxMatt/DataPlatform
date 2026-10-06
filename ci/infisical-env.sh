#!/usr/bin/env bash
# Log in to Infisical as this repo's machine identity (Universal Auth) and export every secret in the
# dataplatform project's prod environment to the job's environment, masked in the logs.
# Needs INFISICAL_URL, INFISICAL_PROJECT_ID, INFISICAL_CLIENT_ID and INFISICAL_CLIENT_SECRET.
set -euo pipefail

: "${INFISICAL_URL:?}" "${INFISICAL_PROJECT_ID:?}" "${INFISICAL_CLIENT_ID:?}" "${INFISICAL_CLIENT_SECRET:?}"

# The credentials go to curl on stdin, never on its command line.
token=$(jq -n --arg id "$INFISICAL_CLIENT_ID" --arg secret "$INFISICAL_CLIENT_SECRET" \
          '{clientId: $id, clientSecret: $secret}' |
        curl -fsS -X POST -H 'Content-Type: application/json' --data @- \
          "$INFISICAL_URL/api/v1/auth/universal-auth/login" | jq -r .accessToken)
echo "::add-mask::$token"

curl -fsS -H @- "$INFISICAL_URL/api/v3/secrets/raw?workspaceId=$INFISICAL_PROJECT_ID&environment=prod&secretPath=/" \
    <<<"Authorization: Bearer $token" |
  jq -r '.secrets[] | "\(.secretKey)\t\(.secretValue)"' |
  while IFS=$'\t' read -r key value; do
    echo "::add-mask::$value"
    echo "$key=$value" >> "$GITHUB_ENV"
    echo "loaded $key"
  done
