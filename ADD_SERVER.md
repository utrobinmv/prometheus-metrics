# Как добавить новый сервер в мониторинг

Пошаговая инструкция для добавления нового сервера с метриками Prometheus.

## Шаг 1: Добавить переменные в `.env`

```ini
# Новый сервер (адрес и порт метрик)
NEW_METRICS_HOST=192.168.45.10
NEW_METRICS_PORT=30000
```

## Шаг 2: Экспортировать переменные в `start.sh`

Добавь строки с дефолтными значениями и экспорт. Пример:

```bash
# Дефолтные значения
NEW_METRICS_HOST="${NEW_METRICS_HOST:-192.168.45.10}"
NEW_METRICS_PORT="${NEW_METRICS_PORT:-30000}"
export NEW_METRICS_HOST NEW_METRICS_PORT
```

## Шаг 3: Добавить scrape config в `prometheus/prometheus.yml.tpl`

```yaml
  - job_name: 'new'
    scrape_interval: 15s
    metrics_path: '/metrics'
    static_configs:
      - targets:
          - '${NEW_METRICS_HOST}:${NEW_METRICS_PORT}'
        labels:
          instance: 'new-server'
```

## Шаг 4: Создать дашборд

Создай файл `grafana/provisioning/dashboards/new-dashboard.json`.

Минимальный шаблон:

```json
{
  "annotations": {"list": []},
  "description": "New server monitoring",
  "editable": true,
  "graphTooltip": 1,
  "id": null,
  "links": [],
  "panels": [
    {
      "collapsed": false,
      "gridPos": {"h": 1, "w": 24, "x": 0, "y": 0},
      "id": 100,
      "title": "SERVER STATUS",
      "type": "row"
    }
  ],
  "preload": false,
  "schemaVersion": 41,
  "tags": ["new", "llm"],
  "templating": {"list": []},
  "time": {"from": "now-1h", "to": "now"},
  "timepicker": {},
  "timezone": "browser",
  "title": "New Server Metrics",
  "uid": "new-server-metrics",
  "version": 1
}
```

### Типы панелей

**Stat (число с цветом):**

```json
{
  "id": 1,
  "title": "Running Requests",
  "type": "stat",
  "gridPos": {"h": 4, "w": 4, "x": 0, "y": 1},
  "datasource": {"type": "prometheus", "uid": "PBFA97CFB590B2093"},
  "fieldConfig": {
    "defaults": {
      "color": {"mode": "thresholds"},
      "thresholds": {"steps": [{"color": "green", "value": null}]},
      "unit": "short"
    },
    "overrides": []
  },
  "options": {
    "colorMode": "background",
    "graphMode": "area",
    "justifyMode": "auto",
    "textMode": "auto"
  },
  "targets": [
    {
      "datasource": {"type": "prometheus", "uid": "${DS_PROMETHEUS}"},
      "expr": "new:metric_name",
      "legendFormat": "__auto",
      "refId": "A"
    }
  ]
}
```

**Time series (график):**

```json
{
  "id": 2,
  "title": "Token Throughput",
  "type": "timeseries",
  "gridPos": {"h": 8, "w": 8, "x": 0, "y": 10},
  "datasource": {"type": "prometheus", "uid": "PBFA97CFB590B2093"},
  "fieldConfig": {
    "defaults": {
      "color": {"mode": "palette-classic"},
      "custom": {
        "drawStyle": "line",
        "lineWidth": 2,
        "fillOpacity": 10,
        "showPoints": "never"
      },
      "unit": "short"
    },
    "overrides": []
  },
  "options": {
    "tooltip": {"mode": "multi"},
    "legend": {"displayMode": "list", "placement": "bottom"}
  },
  "targets": [
    {
      "datasource": {"type": "prometheus", "uid": "${DS_PROMETHEUS}"},
      "expr": "rate(new:tokens_total[5m])",
      "legendFormat": "tokens/s",
      "refId": "A"
    }
  ]
}
```

**Histogram (percentiles p50/p90/p99):**

```json
{
  "id": 3,
  "title": "Latency",
  "type": "timeseries",
  "gridPos": {"h": 8, "w": 8, "x": 0, "y": 10},
  "datasource": {"type": "prometheus", "uid": "PBFA97CFB590B2093"},
  "fieldConfig": {
    "defaults": {
      "color": {"mode": "palette-classic"},
      "custom": {
        "drawStyle": "line",
        "lineWidth": 2,
        "fillOpacity": 10,
        "showPoints": "never"
      },
      "unit": "s"
    },
    "overrides": []
  },
  "options": {
    "tooltip": {"mode": "multi"},
    "legend": {"displayMode": "list", "placement": "bottom"}
  },
  "targets": [
    {
      "datasource": {"type": "prometheus", "uid": "${DS_PROMETHEUS}"},
      "expr": "histogram_quantile(0.50, sum by (instance, le) (rate(new:latency_seconds_bucket[5m])))",
      "legendFormat": "p50",
      "refId": "A"
    },
    {
      "datasource": {"type": "prometheus", "uid": "${DS_PROMETHEUS}"},
      "expr": "histogram_quantile(0.90, sum by (instance, le) (rate(new:latency_seconds_bucket[5m])))",
      "legendFormat": "p90",
      "refId": "B"
    },
    {
      "datasource": {"type": "prometheus", "uid": "${DS_PROMETHEUS}"},
      "expr": "histogram_quantile(0.99, sum by (instance, le) (rate(new:latency_seconds_bucket[5m])))",
      "legendFormat": "p99",
      "refId": "C"
    }
  ]
}
```

### Важные правила

- **histogram_quantile** требует `_bucket` суффикс: `metric_bucket`, не `metric`
- **legendFormat** должен быть явным — иначе текст панелей наслаивается
- **`{instance=~"$server"}`** для фильтрации по dropdown (если нужно)
- **`sum by (instance)`** для агрегации при нескольких инстансах
- **`rate(metric[5m])`** для counter метрик
- **`increase(metric[1h])`** для прироста за час
- **`percentunit`** для значений 0-1 (проценты)
- **`s`** для секунд, **`short`** для чисел, **`bytes`** для байт

### Grid layout

- 24 колонки в ширину
- `gridPos: {"h": 8, "w": 8, "x": 0, "y": N}` — 3 панели в ряд
- `gridPos: {"h": 8, "w": 12, "x": 0, "y": N}` — 2 панели в ряд
- `gridPos: {"h": 8, "w": 24, "x": 0, "y": N}` — 1 панель на всю ширину
- `gridPos: {"h": 4, "w": 4, "x": 0, "y": N}` — stat панель (маленькая)

## Шаг 5: Запустить

```bash
./start.sh
```

Дашборд появится автоматически в Grafana.

## Шаг 6: Проверить

```bash
# Таргет UP?
curl -s http://localhost:9090/api/v1/targets | python3 -c "
import sys, json
for t in json.load(sys.stdin)['data']['activeTargets']:
    print(f'  {t[\"labels\"][\"job\"]}: {t[\"health\"]}')
"

# Дашборд загружен?
curl -s -u admin:admin "http://localhost:3000/api/search" | python3 -c "
import sys, json
for d in json.load(sys.stdin):
    print(f'  {d[\"title\"]}')
"

# Проверить конкретную метрику
curl -s 'http://localhost:9090/api/v1/query' --data-urlencode 'query=new:metric_name' | python3 -m json.tool
```

## Чистка данных

Если дашборд не обновился или появились дубли:

```bash
# Остановить
docker compose down

# Удалить данные (пересоздастся при следующем запуске)
docker run --rm -v $(pwd)/data/prometheus:/data --entrypoint sh prom/prometheus:v3.2.1 -c "rm -rf /data/*"
docker run --rm -v $(pwd)/data/grafana:/data --entrypoint sh grafana/grafana:11.5.2 -c "rm -rf /data/*"

# Запустить заново
./start.sh
```

## Список существующих серверов

| Сервер | Job | Instance | Порт |
|--------|-----|----------|------|
| vLLM-1 | vllm | vllm-1 | 30000 |
| vLLM-2 | vllm | vllm-2 | 30070 |
| SGLang | sglang | sglang-server | 30070 |
| llama.cpp | llamacpp | llamacpp-server | 30000 |
| LiteLLM | litellm | litellm-proxy | 31003 |

## Полезные ссылки

- [Prometheus query language](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Grafana panel types](https://grafana.com/docs/grafana/latest/visualizations/)
- [Grafana dashboard JSON](https://grafana.com/docs/grafana/latest/developers/http_api/dashboard/)
