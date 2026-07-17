# INSTALL.md -- Установка prometheus-metrics с нуля

## Шаг 1: Проверка Docker

```bash
docker --version
docker compose version
```

Если Docker не установлен:

```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
newgrp docker
```

## Шаг 2: Клонирование проекта

```bash
git clone https://github.com/krapotkin/prometheus-metrics.git
cd prometheus-metrics
```

## Шаг 3: Настройка .env

```bash
cp .env.example .env
nano .env
```

Параметры:

```ini
# Адрес vLLM сервера (где /metrics доступен)
VLLM_METRICS_HOST=192.168.45.10
VLLM_METRICS_PORT=30000

# Интервал опроса (15s -- баланс между точностью и нагрузкой)
SCRAPE_INTERVAL=15s

# Grafana логин
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=admin

# Порты (если 3000 занят, измените)
PROMETHEUS_PORT=9090
GRAFANA_PORT=3000

# Хранение метрик
PROMETHEUS_RETENTION_TIME=15d
PROMETHEUS_RETENTION_SIZE=10GB
```

ВАЖНО: Если vLLM сервер на той же машине, используйте `127.0.0.1`.

## Шаг 4: Проверка доступности метрик

```bash
curl -s http://192.168.45.10:30000/metrics | head -20
```

Должен вернуться текст вида:
```
# HELP vllm:num_requests_running ...
# TYPE vllm:num_requests_running gauge
vllm:num_requests_running 3
...
```

Если curl не работает -- проверьте:
- vLLM сервер запущен
- Порт 30000 открыт
- Сеть между машинами работает (ping)

## Шаг 5: Запуск

```bash
./start.sh
```

Первый запуск скачает образы (~300 MB для Prometheus + ~600 MB для Grafana).

## Шаг 6: Проверка

```bash
# Контейнеры запущены (в другом терминале)
docker ps

# Логи (в том терминале, где запущен start.sh)
```

## Шаг 7: Открытие Grafana

Откройте браузер: **http://localhost:3000**

- Логин: `admin`
- Пароль: `admin` (из .env)

Дашборд "vLLM Server Metrics" появится автоматически в папке "vLLM".

## Шаг 8: Настройка Grafana (опционально)

### Изменение периода отображения
- Вверху дашборда: "Now-1h" -- измените на 30m, 6h, 24h, 7d

### Добавление своих панелей
- Нажмите "+" --> "Dashboard" --> "Add visualization"
- Выберите datasource "Prometheus"
- Введите PromQL запрос, например: `vllm:kv_cache_usage_perc`

### Экспорт дашборда
- Settings (шестерёнка) --> JSON Model --> скопируйте/сохраните

## Остановка

```bash
# Ctrl+C в терминале, где запущен start.sh
# Или в другом терминале:
docker compose down
```

## Troubleshooting

### Grafana не видит Prometheus
```bash
# Проверить что Prometheus работает
curl http://localhost:9090/api/v1/status/config

# Проверить targets
curl http://localhost:9090/api/v1/targets
```

### Метрики не собираются
1. Проверить доступность: `curl http://<VLLM_HOST>:<VLLM_PORT>/metrics`
2. Проверить логи в терминале start.sh
3. В Prometheus UI (порт 9090) --> Status --> Targets -- статус должен быть "UP"

### Порт 3000 занят
Измените `GRAFANA_PORT` в `.env` на свободный порт, например `3001`.

### Очистка и перезапуск с нуля
```bash
docker compose down -v
./start.sh --pull
```
