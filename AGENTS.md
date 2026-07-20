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
│       ├── vllm-dashboard.json          # дашборд vLLM (29 панелей, multi-instance)
│       └── litellm-dashboard.json       # дашборд LiteLLM (25 панелей)
├── start.sh                              # envsubst + docker compose up
├── .venv                                 # stub (Docker проект)
├── README.md
├── INSTALL.md
└── AGENTS.md
```

## Мониторинг

Два сервера, два дашборда:

| Сервер | Адрес | Порт | Дашборд | Панели |
|--------|-------|------|---------|--------|
| vLLM 1 | 192.168.45.10 | 30000 | vLLM Server Metrics | 29 |
| vLLM 2 | 192.168.45.10 | 30070 | vLLM Server Metrics | 29 |
| LiteLLM | 192.168.45.30 | 31003 | LiteLLM Proxy Metrics | 25 |

**vLLM дашборд поддерживает несколько серверов.** Вверху -- dropdown "Server" для выбора одного или обоих серверов. Метрики обоих серверов отображаются на одних графиках разными цветами.

## Данные

Хранятся в `./data/` (создаётся автоматически `start.sh`):
- `prometheus/` -- TSDB данные (метрики)
- `grafana/` -- Grafana DB (настройки, пользователи)

## Конфигурация

`.env` переменные:
- `VLLM1_METRICS_HOST/PORT` -- vLLM сервер 1 (по умолчанию 192.168.45.10:30000)
- `VLLM2_METRICS_HOST/PORT` -- vLLM сервер 2 (по умолчанию 192.168.45.10:30070)
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

### vLLM Server Metrics (29 панелей)
- **SERVER STATUS** -- running/waiting/swapped requests, KV cache, FLOPs, preemptions
- **THROUGHPUT** -- prompt tokens/s, generation tokens/s, cache hit rates (раздельные графики)
- **LATENCY** -- 8 метрик (TTFT, inter-token, e2e, prefill, decode, queue, inference, time/output-token), p50/p90/p99
- **REQUEST DETAILS** -- prompt tokens, gen tokens, iteration tokens (p50/p95)
- **HTTP + PROCESS** -- HTTP rate/latency, memory, CPU, FDs, GC
- **Variable `server`** -- dropdown для выбора vllm-1 / vllm-2 / All

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
- vLLM дашборд -- multi-instance: один дашборд для обоих серверов, переключение через dropdown

## Метрики

### vLLM
Полный список: см. `vllm-metrics/tests/test_data/full_vllm_metrics.txt` или `vllm-metrics/README.md`.

### LiteLLM
Полный список: см. `litellm-metrics/AGENTS.md`.
