# syntax=docker/dockerfile:1
FROM enterprise-public-cn-beijing.cr.volces.com/vefaas-public/all-in-one-sandbox:latest

# 1. 使用 root 安装依赖
USER root
RUN npm install -g pnpm edgeone --force --registry=https://registry.npmmirror.com
RUN npm install -g @anthropic-ai/claude-code @musistudio/claude-code-router

# 2. 创建 CCR 所需的配置目录和插件目录
RUN mkdir -p /root/.claude-code-router/plugins

# 3. 设置全局环境变量默认值
ENV JIUTIAN_API_KEY="eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJhcGlfa2V5IjoiNjkzMDFlN2NiODE5YWIwMGZkYjYxYjUxIiwiZXhwIjoxODU1NDQzNTE4NjIwNTEsInRpbWVzdGFtcCI6MTc2NDc2MTI1MX0.VJ68I58MyV4xeSVYnM7-E6MimYimGrd0PA3U40yJfQE"
ENV JIUTIAN_MODELS="kimi-k2-5-thinking,glm-5-fp8,qwen3.5-397B-fp8,jiutian-lan-35b"
ENV ROUTER_DEFAULT="jiutian,qwen3.5-397B-fp8"

# 4. 创建启动脚本以在运行时动态配置
COPY <<'EOF' /entrypoint.sh
#!/bin/bash

# 将逗号分隔的模型列表转换为 JSON 数组格式
if [ -z "$JIUTIAN_MODELS" ]; then
    JSON_MODELS="[]"
else
    # a,b,c -> ["a","b","c"]
    JSON_MODELS="[\"$(echo $JIUTIAN_MODELS | sed 's/,/","/g')\"]"
fi

# 动态生成配置文件
cat <<EOC > /root/.claude-code-router/config.json
{
  "PORT": 3459,
  "LOG": true,
  "LOG_LEVEL": "trace",
  "Providers": [
    {
      "name": "jiutian",
      "api_base_url": "https://jiutian.10086.cn/largemodel/moma/api/v3/chat/completions",
      "api_key": "${JIUTIAN_API_KEY}",
      "models": ${JSON_MODELS},
      "transformer": { "use": ["openrouter"] }
    }
  ],
  "Router": {
    "default": "${ROUTER_DEFAULT}",
    "longContextThreshold": 160000
  }
}
EOF