# prometheus-metrics -- AGENTS.md

## Стек

- **Prometheus v3.2.1** -- сбор и хранение метрик (TSDB)
- **Grafana 11.5.2** -- визуализация через браузер
- **Docker Compose** -- оркестрация контейнеров
- **network_mode: host** -- для доступа к внешним IP (192.168.x.x)

## Структура

```
prometheus-metrics/
├── docker-compose.yml                    # Prometheus + Grafana
├── .env                                  # конфиг (host, port, passwords)
├── .env.example                          # шаблон .env
├── prometheus/
│   └── prometheus.yml.tpl               # шаблон конфига (envsubst)
├── grafana/provisioning/
│   ├── datasources/
│   │   └── datasource.yml.tpl           # авто-подключение Prometheus
│   └── dashboards/
│       ├── dashboards.yml               # provisioning provider
│       ├── vllm-dashboard.json          # дашборд vLLM (16 панелей)
│       ├── sglang-dashboard.json        # дашборд SGLang (17 панелей)
│       └── litellm-dashboard.json       # дашборд LiteLLM (25 панелей)
├── start.sh                              # envsubst + docker compose up
├── .venv                                 # stub (Docker проект)
├── README.md
├── INSTALL.md
└── AGENTS.md
```

## Мониторинг

Три сервера, три дашборда:

| Сервер | Адрес | Порт | Дашборд | Панели |
|--------|-------|------|---------|--------|
| vLLM | 192.168.45.10 | 30000 | vLLM Server Metrics | 16 |
| SGLang | 192.168.45.10 | 30070 | SGLang Server Metrics | 17 |
| LiteLLM | 192.168.45.30 | 31003 | LiteLLM Proxy Metrics | 25 |

## Данные

Хранятся в `./data/` (создаётся автоматически `start.sh`):
- `prometheus/` -- TSDB данные (метрики)
- `grafana/` -- Grafana DB (настройки, пользователи)

## Конфигурация

`.env` переменные:
- `VLLM_METRICS_HOST/PORT` -- vLLM сервер (по умолчанию 192.168.45.10:30000)
- `SGLANG_METRICS_HOST/PORT` -- SGLang сервер (по умолчанию 192.168.45.10:30070)
- `LITELLM_METRICS_HOST/PORT` -- LiteLLM proxy (по умолчанию 192.168.45.30:31003)
- `GRAFANA_ADMIN_USER/PASSWORD` -- логин Grafana
- `PROMETHEUS_PORT/GRAFANA_PORT` -- порты на хосте
- `PROMETHEUS_RETENTION_TIME/SIZE` -- хранение данных

## start.sh

1. Загружает `.env`
2. Генерирует `prometheus.yml` и `datasource.yml` из `.tpl` через `envsubst`
3. Создаёт `data/` и ставит права
4. Запускает `docker compose up` (foreground, Ctrl+C для остановки)

Флаг `--pull` -- обновляет образы перед запуском.

## Grafana дашборды

### vLLM Server Metrics (16 панелей)
1. **SERVER STATUS** -- running/waiting/swapped requests, KV cache, FLOPs, preemptions
2. **THROUGHPUT** -- token rates, success rate, cache hit rates
3. **LATENCY** -- 8 метрик (TTFT, inter-token, e2e, prefill, decode, queue, inference, time/output-token), p50/p90/p99
4. **REQUEST DETAILS** -- prompt tokens, gen tokens, iteration tokens (p50/p95)
5. **HTTP + PROCESS** -- HTTP rate/latency, memory, CPU, FDs, GC

### SGLang Server Metrics (17 панелей)
1. **SERVER STATUS** -- running/queue requests, token usage, cache hit rate, gen throughput
2. **THROUGHPUT** -- prompt/gen token rates, gen throughput
3. **LATENCY** -- TTFT, e2e latency, time per output token, func latency (p50/p90/p99)
4. **CACHE** -- cache hit rate over time

### LiteLLM Proxy Metrics (25 панелей)
1. **PROXY STATUS** -- request rate, failed rate, success rate, in-flight, callback failures, cooled down deployments
2. **TOKENS AND SPEND** -- token rates, cumulative tokens, spend in USD
3. **LATENCY** -- total, LLM API, TTFT, per-output-token, overhead, queue time (p50/p90/p99)
4. **HTTP + PROCESS** -- HTTP rate/latency, memory, CPU, FDs, GC

## Важные замечания

- `network_mode: host` -- контейнеры видят хост-сеть напрямую (нужно для доступа к 192.168.x.x)
- Дашборды provision-ятся автоматически при первом запуске Grafana
- Prometheus хранит данные на диске -- `docker compose down -v` удалит всё
- `start.sh` генерирует конфиги из .tpl через envsubst (Prometheus не раскрывает переменные в YAML)

## Метрики

### vLLM
Полный список: см. `vllm-metrics/tests/test_data/full_vllm_metrics.txt` или `vllm-metrics/README.md`.

### SGLang
- **gauge**: num_running_reqs, num_queue_reqs, token_usage, cache_hit_rate, num_used_tokens, gen_throughput
- **counter**: prompt_tokens_total, generation_tokens_total
- **histogram**: time_to_first_token_seconds, e2e_request_latency_seconds, time_per_output_token_seconds, func_latency_seconds

### LiteLLM
Полный список: см. `litellm-metrics/AGENTS.md`.
