#!/usr/bin/env bash

set -euo pipefail

SERVICE="${1:?Servicio requerido}"
REGION="${AWS_REGION:-us-east-1}"
TAG="${2:?Etiqueta requerida}"

case "$SERVICE" in
  productos|pagos|pedidos|usuarios) ;;
  *) echo "Servicio no permitido"; exit 1 ;;
esac

ACCOUNT_ID=$(aws sts get-caller-identity \
  --query Account --output text)

REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

IMAGE="${REGISTRY}/ms-${SERVICE}:${TAG}"

export DOCKER_CONFIG
DOCKER_CONFIG=$(mktemp -d)

trap 'rm -rf "$DOCKER_CONFIG"' EXIT

echo "Autenticando en Amazon ECR"

aws ecr get-login-password --region "$REGION" |
  docker login --username AWS --password-stdin "$REGISTRY"

echo "Etiquetando imagen Docker"

docker tag "ms-${SERVICE}:${GITHUB_SHA}" "$IMAGE"

echo "Publicando imagen en ECR"

docker push "$IMAGE"

echo "Imagen publicada correctamente"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "image=$IMAGE" >> "$GITHUB_OUTPUT"
fi