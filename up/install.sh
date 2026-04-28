#!/bin/bash

# Exit on any error
set -e

echo "===================================================="
echo " Starting Live Chat SaaS Production Deployment"
echo "===================================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo ./install.sh)"
  exit 1
fi

# Variables (change these as needed)
DOMAIN="textbii.com"
EMAIL="support@textbii.com"
APP_DIR="/var/www/livechat"
PORT=3000

echo "1. Updating Ubuntu..."
apt update && apt upgrade -y
apt install -y curl wget git build-essential unzip nginx certbot python3-certbot-nginx software-properties-common

echo "2. Installing Node.js LTS..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

echo "3. Installing MongoDB..."
# Assuming local MongoDB for free tier
curl -fsSL https://pgp.mongodb.com/server-7.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg \
   --dearmor
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
apt update
apt install -y mongodb-org
systemctl enable mongod
systemctl start mongod

echo "4. Installing PM2..."
npm install -g pm2

echo "5. Setting up Application Directory..."
mkdir -p $APP_DIR
# In a real scenario, you'd git clone here. Assuming files are copied to $APP_DIR
# git clone https://github.com/your-repo/livechat.git $APP_DIR

# Set permissions
chown -R $SUDO_USER:$SUDO_USER $APP_DIR

echo "6. Building Next.js App..."
cd $APP_DIR
# Run as normal user
su - $SUDO_USER -c "cd $APP_DIR && npm install"
su - $SUDO_USER -c "cd $APP_DIR && npm run build"

echo "7. Starting App with PM2..."
su - $SUDO_USER -c "cd $APP_DIR && pm2 start ecosystem.config.js --env production"
su - $SUDO_USER -c "pm2 save"
env PATH=$PATH:/usr/bin pm2 startup systemd -u $SUDO_USER --hp /home/$SUDO_USER

echo "8. Configuring Nginx Reverse Proxy..."
cp $APP_DIR/nginx.conf /etc/nginx/sites-available/livechat
sed -i "s/yourdomain.com/$DOMAIN/g" /etc/nginx/sites-available/livechat
ln -sf /etc/nginx/sites-available/livechat /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx

echo "9. Installing SSL with Certbot..."
certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos -m $EMAIL --redirect

echo "10. Setting up Auto-Renewal for SSL..."
systemctl enable certbot.timer
systemctl start certbot.timer

echo "===================================================="
echo " Deployment Complete!"
echo " App should be accessible at: https://$DOMAIN"
echo " Please check DEPLOYMENT.md for next steps (seed admin)."
echo "===================================================="
