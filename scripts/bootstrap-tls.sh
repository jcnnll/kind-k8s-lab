#!/usr/bin/env bash

set -euo pipefail

# =========================
# CONFIG
# =========================
DOMAIN="api.lab"
SECRET_NAME="api-lab-tls"
NAMESPACE="default"

CERT_FILE="$(mktemp)"
KEY_FILE="$(mktemp)"

# =========================
# HELPERS
# =========================
log() {
  echo "[tls-bootstrap] $1"
}

fail() {
  echo "[tls-bootstrap][ERROR] $1" >&2
  exit 1
}

cleanup() {
  rm -f "${CERT_FILE}" "${KEY_FILE}" || true
}
trap cleanup EXIT

# =========================
# DEPENDENCY CHECKS
# =========================
command -v mkcert >/dev/null 2>&1 || fail "mkcert is not installed"
command -v kubectl >/dev/null 2>&1 || fail "kubectl is not installed"

# =========================
# ENSURE LOCAL CA EXISTS
# =========================
log "Ensuring local CA is installed (mkcert)..."
mkcert -install >/dev/null 2>&1 || fail "mkcert CA install failed"

# =========================
# GENERATE CERT (EPHEMERAL)
# =========================
log "Generating ephemeral certificate for ${DOMAIN}"

mkcert \
  -cert-file "${CERT_FILE}" \
  -key-file "${KEY_FILE}" \
  "${DOMAIN}" "*.${DOMAIN}" >/dev/null

[[ -s "${CERT_FILE}" ]] || fail "Cert generation failed"
[[ -s "${KEY_FILE}" ]] || fail "Key generation failed"

# =========================
# APPLY K8S SECRET (IDEMPOTENT)
# =========================
log "Applying Kubernetes TLS secret: ${SECRET_NAME}"

kubectl create secret tls "${SECRET_NAME}" \
  --cert="${CERT_FILE}" \
  --key="${KEY_FILE}" \
  --namespace "${NAMESPACE}" \
  --dry-run=client -o yaml | kubectl apply -f -

# =========================
# VALIDATION
# =========================
log "Validating Kubernetes secret..."

kubectl get secret "${SECRET_NAME}" -n "${NAMESPACE}" >/dev/null ||
  fail "TLS secret not found after apply"

# =========================
# SUCCESS
# =========================
echo ""
echo "[tls-bootstrap] SUCCESS"
echo "----------------------------------"
echo "Domain:    ${DOMAIN}"
echo "Namespace: ${NAMESPACE}"
echo "Secret:    ${SECRET_NAME}"
echo "Source:    ephemeral (/tmp)"
echo "----------------------------------"
