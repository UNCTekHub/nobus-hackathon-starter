#!/usr/bin/env bash
# Nobus Cloud hackathon starter: one command from a fresh Ubuntu 22.04 server to a live URL.
#
# Usage (on your Nobus server, logged in as ubuntu, from the kit folder):
#   ./deploy.sh sample|<your-repo-url> [app-port] [your-domain] [your-email]
#
# Examples:
#   ./deploy.sh sample                                   # the kit's sample app
#   ./deploy.sh sample 3000 team07.com.ng you@example.com  # sample app with HTTPS
#   ./deploy.sh https://github.com/team07/app.git        # your own code
#   ./deploy.sh https://github.com/team07/app.git 3000 team07.com.ng you@example.com
#
# Run it again after every git push to redeploy.

set -euo pipefail

REPO="${1:-sample}"
PORT="${2:-3000}"
DOMAIN="${3:-}"
EMAIL="${4:-}"
KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$KIT_DIR/sample-app"

if [ "$REPO" = "sample" ]; then
  APP_DIR="$SAMPLE_DIR"
else
  APP_DIR="$HOME/app"
fi

step() { printf '\n==> %s\n' "$1"; }

step "1/5 Installing Git, Nginx and Docker (first run only)"
sudo apt-get update -y
sudo apt-get install -y git nginx curl
if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sudo sh
fi

step "2/5 Getting your code"
if [ "$REPO" = "sample" ]; then
  echo "Using the starter kit's sample app in $SAMPLE_DIR"
else
  # Moving from the sample app to your own code: stop the sample so port $PORT is free.
  if command -v docker >/dev/null 2>&1 && [ -f "$SAMPLE_DIR/docker-compose.yml" ]; then
    sudo docker compose -f "$SAMPLE_DIR/docker-compose.yml" down >/dev/null 2>&1 || true
  fi
  if [ -d "$APP_DIR/.git" ]; then
    git -C "$APP_DIR" pull --ff-only
  else
    git clone "$REPO" "$APP_DIR"
  fi
fi
cd "$APP_DIR"
if [ ! -f .env ] && [ -f .env.example ]; then
  cp .env.example .env
  echo "Created .env from .env.example. Edit it with: nano $APP_DIR/.env"
fi
touch .env

step "3/5 Building and starting your app"
if [ -f docker-compose.yml ] || [ -f docker-compose.yaml ] || [ -f compose.yml ] || [ -f compose.yaml ]; then
  sudo docker compose up -d --build
elif [ -f Dockerfile ]; then
  sudo docker build -t hackathon-app .
  sudo docker rm -f hackathon-app >/dev/null 2>&1 || true
  sudo docker run -d --name hackathon-app --restart always \
    --env-file .env -e PORT="$PORT" -p "127.0.0.1:$PORT:$PORT" hackathon-app
else
  echo "No Dockerfile or docker-compose.yml found in your repo."
  echo "Copy one from the starter kit's sample-app folder, push it, then run this again."
  exit 1
fi

step "4/5 Pointing Nginx at your app on port $PORT"
SERVER_NAME="${DOMAIN:-_}"
sudo tee /etc/nginx/sites-available/hackathon-app >/dev/null <<EOF
server {
  listen 80 default_server;
  server_name $SERVER_NAME;
  client_max_body_size 20m;
  location / {
    proxy_pass http://127.0.0.1:$PORT;
    proxy_http_version 1.1;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
  }
}
EOF
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/hackathon-app /etc/nginx/sites-enabled/hackathon-app
sudo nginx -t
sudo systemctl reload nginx

step "5/5 HTTPS"
if [ -n "$DOMAIN" ]; then
  sudo apt-get install -y certbot python3-certbot-nginx
  if [ -n "$EMAIL" ]; then
    MAIL_ARGS=(-m "$EMAIL")
  else
    MAIL_ARGS=(--register-unsafely-without-email)
  fi
  if ! sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --redirect "${MAIL_ARGS[@]}"; then
    echo "HTTPS isn't set up yet. Check that $DOMAIN has an A record pointing at this server,"
    echo "wait a few minutes, then run this script again. Your app is still live on the IP."
  fi
else
  echo "No domain given, so skipping HTTPS. Add your domain later and run this again."
fi

IP="$(curl -fsS --max-time 5 https://ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')"
printf '\nLive at: http://%s\n' "$IP"
if [ -n "$DOMAIN" ]; then
  printf 'And at:  https://%s (once DNS has updated)\n' "$DOMAIN"
fi
printf 'Open it on your phone, on mobile data, to check.\n'
