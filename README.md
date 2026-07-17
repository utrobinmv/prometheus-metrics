# prometheus-metrics

Мониторинг vLLM сервера через Prometheus + Grafana с визуализацией в браузере.

Собирает метрики с endpoint `/metrics` вашего vLLM сервера, хранит историю и отображает графики в реальном времени через Grafana дашборд.

## Установка

```bash
git clone https://github.com/krapotkin/prometheus-metrics.git
cd prometheus-metrics

# Настроить .env (опционально)
cp .env.example .env
nano .env
```

## Быстрый старт

```bash
# 1. Настроить .env (адрес vLLM сервера)
nano .env

# 2. Запустить
./start.sh

# 3. Открыть Grafana
# http://localhost:3000
# Логин: admin / admin
```

## Архитектура

```
vLLM сервер (192.168.45.10:30000)
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

## Что мониторит

### SERVER STATUS
- Requests Running / Waiting / Swapped
- KV Cache Usage (с цветовой индикацией: green/yellow/red)
- Estimated FLOPs/GPU
- Total Preemptions
- Engine PPU update time

### THROUGHPUT
- Token throughput (prompt, generation, cached) в токенах/сек
- Request success rate по reason (stop/length/error)
- Average throughput из gauge-метрик vLLM
- Cache hit rates (prefix, external prefix, mm cache)

### LATENCY (Percentiles)
- TTFT (Time to First Token) -- p50/p90/p99
- Inter-Token Latency -- p50/p90/p99
- End-to-End Request Latency -- p50/p90/p99
- Prefill Time -- p50/p90/p99
- Decode Time -- p50/p90/p99
- Queue Time -- p50/p90/p99
- Inference Time -- p50/p90/p99
- Time Per Output Token -- p50/p90/p99

### REQUEST DETAILS
- Prompt tokens per request (p50/p95)
- Generation tokens per request (p50/p95)
- Iteration tokens (p50/p95)

### HTTP + PROCESS
- HTTP requests rate по method/status
- HTTP latency (p50/p95/p99)
- Process memory (RSS/Virtual)
- CPU usage
- File descriptors
- Python GC collections (gen 0/1/2)

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
