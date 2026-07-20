global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'vllm'
    scrape_interval: 15s
    metrics_path: '/metrics'
    static_configs:
      - targets:
          - '${VLLM1_METRICS_HOST}:${VLLM1_METRICS_PORT}'
        labels:
          instance: 'vllm-1'
      - targets:
          - '${VLLM2_METRICS_HOST}:${VLLM2_METRICS_PORT}'
        labels:
          instance: 'vllm-2'

  - job_name: 'litellm'
    scrape_interval: 15s
    metrics_path: '/metrics'
    static_configs:
      - targets:
          - '${LITELLM_METRICS_HOST}:${LITELLM_METRICS_PORT}'
        labels:
          instance: 'litellm-proxy'

  - job_name: 'prometheus'
    scrape_interval: 30s
    static_configs:
      - targets:
          - 'localhost:9090'
        labels:
          instance: 'prometheus-self'
