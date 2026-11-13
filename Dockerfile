
FROM ghcr.io/engigu/baihu:latest

ENV REMOTE_FOLDER="huggingface:baihu"

RUN apt-get update && apt-get install -y \
    jq \
    curl \
    unzip \
    sshpass \
    openssh-client \
    && curl -fsSL https://rclone.org/install.sh | bash \
    && rclone version \
    && ssh -V \
    && sshpass -V \
    && rm -rf /var/lib/apt/lists/*

# ===== 初始化 Node.js 环境 =====
RUN mise use -g node@23.11.1

# ===== 构建阶段预装 PM2 =====
# 使用 Mise 管理的 Node.js 安装最新版 PM2
RUN set -eux; \
    NODE_BIN="$(mise which node)"; \
    NODE_DIR="$(dirname "$NODE_BIN")"; \
    "$NODE_DIR/npm" install -g pm2; \
    "$NODE_DIR/pm2" -v

RUN rclone config -h

COPY ./restore.sh /

# 替换新版 Baihu 启动函数
RUN sed -i 's/^start_baihu_server "\$@"$/sh \/restore.sh/' /app/docker-entrypoint.sh \
    && echo "========== 修改后的 ENTRYPOINT ==========" \
    && tail -n 15 /app/docker-entrypoint.sh \
    && grep -q '^sh /restore.sh$' /app/docker-entrypoint.sh

RUN mise exec python@3.13.12 -- pip install requests
RUN mise use -g python@3.13.12
