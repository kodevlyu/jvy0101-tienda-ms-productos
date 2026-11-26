#!/usr/bin/env bash

set -euo pipefail

SERVICE="${1:?Servicio requerido}"
IMAGE="${2:?Imagen requerida}"
REGION="${AWS_REGION:-us-east-1}"
MANAGER="${SWARM_MANAGER_ID:?Manager requerido}"

case "$SERVICE" in
  productos) PORT=8083; ENDPOINT=productos ;;
  pagos) PORT=8084; ENDPOINT=pagos ;;
  pedidos) PORT=8085; ENDPOINT=pedidos ;;
  usuarios) PORT=8086; ENDPOINT=usuarios ;;
  *) echo "Servicio no permitido"; exit 1 ;;
esac

ACCOUNT_ID=$(aws sts get-caller-identity \
  --query Account --output text)

REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

[[ "$IMAGE" == "$REGISTRY/ms-$SERVICE:"* ]] || exit 1
[[ "$IMAGE" =~ ^[a-zA-Z0-9./:_-]+$ ]] || exit 1

COMMANDS=$(jq -n \
  --arg registry "$REGISTRY" \
  --arg region "$REGION" \
  --arg service "tienda_ms-${SERVICE}" \
  --arg image "$IMAGE" \
  --arg url "http://127.0.0.1:${PORT}/api/${ENDPOINT}" \
  '{
    commands: [
      "set -eu",
      "export DOCKER_CONFIG=$(mktemp -d)",
      "trap '\''rm -rf \"$DOCKER_CONFIG\"'\'' EXIT",
      ("TOKEN=$(/usr/local/bin/aws ecr get-login-password --region " + $region + ")"),
      "test -n \"$TOKEN\"",
      ("printf \"%s\" \"$TOKEN\" | docker login --username AWS --password-stdin " + $registry),
      "unset TOKEN",
      ("docker service update --with-registry-auth --image " + $image + " --update-failure-action rollback --detach=false " + $service),
      ("ACTUAL=$(docker service inspect --format '\''{{.Spec.TaskTemplate.ContainerSpec.Image}}'\'' " + $service + ")"),
      ("case \"$ACTUAL\" in " + $image + "|" + $image + "@sha256:*) ;; *) exit 1 ;; esac"),
      ("curl --fail --silent --show-error --retry 10 --retry-all-errors --retry-delay 5 --max-time 10 " + $url + " > /dev/null"),
      ("docker service ps " + $service),
      "docker service ls",
      "echo Despliegue y endpoint verificados"
    ],
    executionTimeout: ["600"]
  }')

COMMAND_ID=$(aws ssm send-command \
  --instance-ids "$MANAGER" \
  --document-name AWS-RunShellScript \
  --parameters "$COMMANDS" \
  --region "$REGION" \
  --query Command.CommandId \
  --output text)

echo "Comando SSM enviado: $COMMAND_ID"

for attempt in $(seq 1 150); do
  STATUS=$(aws ssm get-command-invocation \
    --command-id "$COMMAND_ID" \
    --instance-id "$MANAGER" \
    --region "$REGION" \
    --query Status --output text 2>/dev/null) || STATUS="Pending"

  case "$STATUS" in
    Success|Failed|Cancelled|TimedOut|Cancelling)
      break
      ;;
  esac

  sleep 5
done

aws ssm get-command-invocation \
  --command-id "$COMMAND_ID" \
  --instance-id "$MANAGER" \
  --region "$REGION" \
  --query '{Estado:Status,Codigo:ResponseCode,Salida:StandardOutputContent,Errores:StandardErrorContent}' \
  --output json

[[ "$STATUS" == "Success" ]] || exit 1

echo "Despliegue completado correctamente"