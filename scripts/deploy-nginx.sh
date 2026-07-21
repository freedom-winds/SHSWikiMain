#!/usr/bin/env bash
set -Eeuo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo "请使用 sudo 运行此脚本。" >&2
  exit 1
fi

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SOURCE_DIR="${SOURCE_DIR:-${REPO_ROOT}/site}"
DEPLOY_ROOT="${DEPLOY_ROOT:-/var/www/shswiki}"
RELEASES_DIR="${DEPLOY_ROOT}/releases"
CURRENT_LINK="${DEPLOY_ROOT}/current"
NGINX_CONF="/etc/nginx/conf.d/shswiki.conf"
SERVER_NAME="${SERVER_NAME:-shs.wiki www.shs.wiki}"

if [[ ! -f "${SOURCE_DIR}/index.html" ]]; then
  echo "未找到静态页面：${SOURCE_DIR}/index.html" >&2
  exit 1
fi

if ! command -v nginx >/dev/null 2>&1; then
  echo "未找到 nginx 命令。请先安装并启用 Nginx。" >&2
  exit 1
fi

RELEASE_NAME="$(date -u +%Y%m%dT%H%M%SZ)"
RELEASE_DIR="${RELEASES_DIR}/${RELEASE_NAME}"
TMP_CONF="$(mktemp)"
BACKUP_CONF="$(mktemp)"
HAD_CONF=0

cleanup() {
  rm -f "${TMP_CONF}" "${BACKUP_CONF}"
}
trap cleanup EXIT

install -d -m 0755 "${RELEASE_DIR}"
cp -a "${SOURCE_DIR}/." "${RELEASE_DIR}/"
find "${RELEASE_DIR}" -type d -exec chmod 0755 {} +
find "${RELEASE_DIR}" -type f -exec chmod 0644 {} +

if [[ -f "${NGINX_CONF}" ]]; then
  cp -a "${NGINX_CONF}" "${BACKUP_CONF}"
  HAD_CONF=1
fi

cat > "${TMP_CONF}" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${SERVER_NAME};

    root ${CURRENT_LINK};
    index index.html;
    charset utf-8;

    location = /healthz {
        default_type text/plain;
        return 200 "ok\\n";
    }

    location /assets/ {
        try_files \$uri =404;
        expires 7d;
        add_header Cache-Control "public, max-age=604800, immutable";
    }

    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
EOF

install -m 0644 "${TMP_CONF}" "${NGINX_CONF}"

if ! nginx -t; then
  if [[ ${HAD_CONF} -eq 1 ]]; then
    install -m 0644 "${BACKUP_CONF}" "${NGINX_CONF}"
  else
    rm -f "${NGINX_CONF}"
  fi
  echo "Nginx 配置校验失败，已恢复原配置。" >&2
  exit 1
fi

ln -sfn "${RELEASE_DIR}" "${CURRENT_LINK}"
systemctl reload nginx

echo "已部署到 ${CURRENT_LINK}"
echo "已写入 ${NGINX_CONF}"
