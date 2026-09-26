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
git clone https://github.com/utrobinmv/prometheus-metrics.git
cd prometheus-metrics
```

## Шаг 3: Настройка .env

```bash
cp .env.example .env
nano .env
```

Параметры:

```ini
# Адреса серверов (где /metrics доступен)
VLLM_METRICS_HOST=192.168.45.10
VLLM_METRICS_PORT=30000

SGLANG_METRICS_HOST=192.168.45.10
SGLANG_METRICS_PORT=30070

LITELLM_METRICS_HOST=192.168.45.30
LITELLM_METRICS_PORT=31003

# Grafana логин
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=admin

# Порты
PROMETHEUS_PORT=9090
GRAFANA_PORT=3000

# Хранение метрик
PROMETHEUS_RETENTION_TIME=15d
PROMETHEUS_RETENTION_SIZE=10GB
```

## Шаг 4: Проверка доступности метрик

```bash
# vLLM
curl -s http://192.168.45.10:30000/metrics | head -5

# SGLang
curl -s http://192.168.45.10:30070/metrics | head -5

# LiteLLM
curl -s http://192.168.45.30:31003/metrics | head -5
```

Должен вернуться текст вида:
```
# HELP vllm:num_requests_running ...
# TYPE vllm:num_requests_running gauge
vllm:num_requests_running 3
...
```

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

Дашборды появятся автоматически:
- **vLLM Server Metrics** -- в папке "vLLM"
- **SGLang Server Metrics** -- в папке "SGLang"
- **LiteLLM Proxy Metrics** -- в папке "LiteLLM"

## Остановка

```bash
# Ctrl+C в терминале, где запущен start.sh
# Или в другом терминале:
docker compose down
```

## Troubleshooting

### Сервер не виден (target down)
1. Проверить доступность: `curl http://<HOST>:<PORT>/metrics`
2. Проверить логи в терминале start.sh
3. В Prometheus UI (порт 9090) --> Status --> Targets -- статус должен быть "UP"

### Порт 3000 занят
Измените `GRAFANA_PORT` в `.env` на свободный порт, например `3001`.

### Очистка и перезапуск с нуля
```bash
docker compose down -v
./start.sh --pull
```
