# Deployment Guide (OVH Ubuntu VPS)

This project includes automated deployment scripts specifically designed for an OVH Ubuntu 22.04/24.04 VPS.

## Prerequisites

- An Ubuntu VPS
- A domain name pointed to your VPS IP address (e.g., `chat.yourdomain.com`)
- SSH access to your VPS

## Step-by-Step Installation

1. **SSH into your VPS:**
   ```bash
   ssh ubuntu@YOUR_VPS_IP
   # Switch to root
   sudo su
   ```

2. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/livechat-saas.git /var/www/livechat
   cd /var/www/livechat
   ```
   *(If uploading files via FTP/SFTP, upload them to `/var/www/livechat`)*

3. **Configure Environment Variables:**
   ```bash
   cp .env.example .env
   nano .env
   # Set your domain, NEXTAUTH_SECRET, Pusher keys, and AI keys.
   ```

4. **Edit the Install Script:**
   ```bash
   nano install.sh
   # Change DOMAIN="yourdomain.com" and EMAIL="admin@yourdomain.com"
   ```

5. **Make Scripts Executable:**
   ```bash
   chmod +x install.sh update.sh backup.sh
   ```

6. **Run the Installer:**
   ```bash
   ./install.sh
   ```
   This script will:
   - Update Ubuntu
   - Install Node.js, MongoDB, Nginx, PM2, and Certbot
   - Build the Next.js app
   - Start it with PM2
   - Configure Nginx reverse proxy
   - Install Let's Encrypt SSL

7. **Create the Admin Account:**
   Once the installation is complete, run the seed script to create your super admin:
   ```bash
   cd /var/www/livechat
   npm run seed
   ```

## Post-Installation Details

- **Admin URL:** `https://yourdomain.com/admin`
- **Agent URL:** `https://yourdomain.com/agent`
- **Default Admin Login:** (See seed script output)

### Adding the Widget to a Website

In the admin panel, go to Widget Settings. You will get a script tag like this:
```html
<script src="https://yourdomain.com/widget.js" data-site-id="YOUR_SITE_ID"></script>
```
Paste this before the `</body>` tag of any website.

### Backups

A backup script (`backup.sh`) is included. You can add it to your crontab to run daily:
```bash
crontab -e
# Add this line to run backup every day at 2 AM
0 2 * * * /var/www/livechat/backup.sh >> /var/log/mongodb-backup.log 2>&1
```

### Updating the App

To update the app when you push new code to your repository:
```bash
cd /var/www/livechat
./update.sh
```
