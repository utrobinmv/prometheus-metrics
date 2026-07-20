#!/usr/bin/env bash
# Генерирует конфиги из .env и запускает Prometheus + Grafana.
#
# ИСПОЛЬЗОВАНИЕ:
#   ./start.sh              # запустить (Ctrl+C для остановки)
#   ./start.sh --pull       # обновить образы перед запуском

set -euo pipefail
cd "$(dirname "$0")"

# Загрузка .env
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

# Дефолтные значения
VLLM1_METRICS_HOST="${VLLM1_METRICS_HOST:-192.168.45.10}"
VLLM1_METRICS_PORT="${VLLM1_METRICS_PORT:-30000}"
VLLM2_METRICS_HOST="${VLLM2_METRICS_HOST:-192.168.45.10}"
VLLM2_METRICS_PORT="${VLLM2_METRICS_PORT:-30070}"
LITELLM_METRICS_HOST="${LITELLM_METRICS_HOST:-192.168.45.30}"
LITELLM_METRICS_PORT="${LITELLM_METRICS_PORT:-31003}"
PROMETHEUS_PORT="${PROMETHEUS_PORT:-9090}"
export VLLM1_METRICS_HOST VLLM1_METRICS_PORT VLLM2_METRICS_HOST VLLM2_METRICS_PORT
export LITELLM_METRICS_HOST LITELLM_METRICS_PORT PROMETHEUS_PORT

# Генерация конфигов
envsubst < prometheus/prometheus.yml.tpl > prometheus/prometheus.yml
envsubst < grafana/provisioning/datasources/datasource.yml.tpl \
    > grafana/provisioning/datasources/datasource.yml

# Права на данные
mkdir -p data/prometheus data/grafana
chmod -R 777 data/ 2>/dev/null || true

# Обновить образы?
if [ "${1:-}" = "--pull" ]; then
    docker compose pull
fi

echo "Сервисы:"
echo "  Prometheus: http://localhost:${PROMETHEUS_PORT}"
echo "  Grafana:    http://localhost:${GRAFANA_PORT:-3000}"
echo "  Логин:      ${GRAFANA_ADMIN_USER:-admin} / ${GRAFANA_ADMIN_PASSWORD:-admin}"
echo ""
echo "Ctrl+C для остановки"
echo ""

exec docker compose up
