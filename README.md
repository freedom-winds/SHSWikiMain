# SHS Wiki Main

`shs.wiki` 的纯静态入口页，包含龙门楼线稿位图与页面加载动画。

## 部署到 Nginx

在服务器上克隆仓库后执行：

```bash
sudo bash scripts/deploy-nginx.sh
```

脚本会：

- 发布 `site/` 至 `/var/www/shswiki/current`；
- 写入 `/etc/nginx/conf.d/shswiki.conf`；
- 执行 `nginx -t` 后重载 Nginx。

默认域名为 `shs.wiki www.shs.wiki`，可临时覆盖：

```bash
sudo SERVER_NAME="shs.wiki" bash scripts/deploy-nginx.sh
```

脚本不申请或配置证书；HTTPS 由现有反向代理或后续证书配置处理。

