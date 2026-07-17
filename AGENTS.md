# prometheus-metrics -- AGENTS.md

## Стек

- **Prometheus v3.2.1** -- сбор и хранение метрик (TSDB)
- **Grafana 11.5.2** -- визуализация через браузер
- **Docker Compose** -- оркестрация контейнеров
- **network_mode: host** -- для доступа к внешним IP (vLLM на 192.168.x.x)

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
│       └── vllm-dashboard.json          # дашборд vLLM (16 панелей)
├── start.sh                              # envsubst + docker compose up
├── .venv                                 # stub (Docker проект)
├── README.md
├── INSTALL.md
└── AGENTS.md
```

## Данные

Хранятся в `./data/` (создаётся автоматически `start.sh`):
- `prometheus/` -- TSDB данные (метрики)
- `grafana/` -- Grafana DB (настройки, пользователи)

## Конфигурация

`.env` переменные:
- `VLLM_METRICS_HOST` -- IP vLLM сервера (по умолчанию 192.168.45.10)
- `VLLM_METRICS_PORT` -- порт /metrics (по умолчанию 30000)
- `SCRAPE_INTERVAL` -- интервал опроса (15s)
- `GRAFANA_ADMIN_USER/PASSWORD` -- логин Grafana
- `PROMETHEUS_PORT/GRAFANA_PORT` -- порты на хосте
- `PROMETHEUS_RETENTION_TIME/SIZE` -- хранение данных

## start.sh

1. Загружает `.env`
2. Генерирует `prometheus.yml` и `datasource.yml` из `.tpl` через `envsubst`
3. Создаёт `data/` и ставит права
4. Запускает `docker compose up` (foreground, Ctrl+C для остановки)

Флаг `--pull` -- обновляет образы перед запуском.

## Grafana дашборд

16 панелей в 4 секциях:
1. **SERVER STATUS** -- running/waiting/swapped requests, KV cache, FLOPs, preemptions
2. **THROUGHPUT** -- token rates, success rate, cache hit rates
3. **LATENCY** -- 8 метрик (TTFT, inter-token, e2e, prefill, decode, queue, inference, time/output-token), p50/p90/p99
4. **REQUEST DETAILS** -- prompt tokens, gen tokens, iteration tokens (p50/p95)
5. **HTTP + PROCESS** -- HTTP rate/latency, memory, CPU, FDs, GC

## Важные замечания

- `network_mode: host` -- контейнеры видят хост-сеть напрямую (нужно для доступа к 192.168.x.x)
- Дашборд provision-ится автоматически при первом запуске Grafana
- Prometheus хранит данные на диске -- `docker compose down -v` удалит всё
- `start.sh` генерирует конфиги из .tpl через envsubst (Prometheus не раскрывает переменные в YAML)

## Метрики vLLM

Полный список метрик: см. `vllm-metrics/tests/test_data/full_vllm_metrics.txt` или `vllm-metrics/README.md`.

Типы метрик:
- **gauge**: num_requests_running, num_requests_waiting, kv_cache_usage_perc, avg_prompt_throughput, avg_generation_throughput, num_requests_swapped, time_since_last_ppu_update, process_memory, process_fds
- **counter**: prompt_tokens_total, generation_tokens_total, prompt_tokens_cached_total, request_success_total, num_preemptions_total, estimated_flops_per_gpu_total, prefix_cache_queries/hits, http_requests_total, process_cpu_seconds_total, python_gc_collections_total
- **histogram**: time_to_first_token_seconds, inter_token_latency_seconds, e2e_request_latency_seconds, request_prefill_time_seconds, request_decode_time_seconds, request_queue_time_seconds, request_inference_time_seconds, request_time_per_output_token_seconds, request_prompt_tokens, request_generation_tokens, iteration_tokens_total, request_prefill_kv_computed_tokens, request_max_num_generation_tokens, request_params_max_tokens, http_request_duration_highr_seconds
