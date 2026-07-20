# prometheus-metrics

Мониторинг vLLM и LiteLLM серверов через Prometheus + Grafana с визуализацией в браузере.

Собирает метрики с endpoint `/metrics` ваших серверов, хранит историю и отображает графики в реальном времени через Grafana дашборды.

## Установка

```bash
git clone https://github.com/krapotkin/prometheus-metrics.git
cd prometheus-metrics

# Настроить .env (адреса серверов)
cp .env.example .env
nano .env
```

## Быстрый старт

```bash
# 1. Настроить .env (адреса серверов)
nano .env

# 2. Запустить
./start.sh

# 3. Открыть Grafana
# http://localhost:3000
# Логин: admin / admin
```

## Архитектура

```
vLLM сервер 1 (192.168.45.10:30000)
    |
vLLM сервер 2 (192.168.45.10:30070)
    |
LiteLLM proxy (192.168.45.30:31003)
    |
    |  GET /metrics (Prometheus format)
    v
Prometheus (localhost:9090)
    |  собирает каждые 15 сек
    |  хранит TSDB
    v
Grafana (localhost:3000)
    |  читает из Prometheus
    v
Браузер -- графики, алерты, история
```

## Дашборды

### vLLM Server Metrics (29 панелей)
Вверху дашборда -- dropdown **Server** для выбора одного или обоих серверов.

- **SERVER STATUS** -- running/waiting/swapped requests, KV cache, FLOPs, preemptions
- **THROUGHPUT** -- prompt tokens/s, generation tokens/s, cache hit rates (раздельные графики)
- **LATENCY** -- 8 метрик (TTFT, inter-token, e2e, prefill, decode, queue, inference, time/output-token), p50/p90/p99
- **REQUEST DETAILS** -- prompt tokens, gen tokens, iteration tokens (p50/p95)
- **HTTP + PROCESS** -- HTTP rate/latency, memory, CPU, FDs, GC

### LiteLLM Proxy Metrics (25 панелей)
- **PROXY STATUS** -- request rate, failed rate, success rate, in-flight, callback failures, cooled down deployments
- **TOKENS AND SPEND** -- token rates, cumulative tokens, spend in USD
- **LATENCY** -- total, LLM API, TTFT, per-output-token, overhead, queue time (p50/p90/p99)
- **HTTP + PROCESS** -- HTTP rate/latency, memory, CPU, FDs, GC

## Управление

```bash
./start.sh              # запустить (Ctrl+C для остановки)
./start.sh --pull       # обновить образы + запустить

docker compose down     # остановить
docker compose down -v  # остановить + удалить данные
```

## Порты

| Сервис     | Порт  | URL                              |
|------------|-------|----------------------------------|
| Prometheus | 9090  | http://localhost:9090            |
| Grafana    | 3000  | http://localhost:3000            |

## Данные

Метрики хранятся в `data/` (создаётся автоматически):
- `prometheus/` -- TSDB (временные ряды)
- `grafana/` -- настройки, дашборды, панели

По умолчанию retention: 15 дней или 10 GB (что наступит раньше).
