#!/bin/bash
set -e

# Configuration
DOMAIN="textbii.com"
MAIL_DOMAIN="mail.$DOMAIN"

echo "=================================================="
echo " Setting up Mail Server for $DOMAIN"
echo "=================================================="

# Check root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo ./mail-setup.sh)"
  exit 1
fi

echo "1. Installing Postfix and Dovecot..."
# Unattended install for postfix
echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections
echo "postfix postfix/mailname string $DOMAIN" | debconf-set-selections
apt update
apt install -y postfix dovecot-imapd dovecot-pop3d certbot

echo "2. Setting up SSL for $MAIL_DOMAIN..."
certbot certonly --standalone -d $MAIL_DOMAIN --non-interactive --agree-tos -m admin@$DOMAIN || echo "Warning: Certbot failed, make sure port 80 is free and DNS is pointed."

echo "3. Configuring Postfix..."
cat <<EOF > /etc/postfix/main.cf
smtpd_banner = \$myhostname ESMTP \$mail_name (Ubuntu)
biff = no
append_dot_mydomain = no
readme_directory = no
compatibility_level = 3
smtpd_tls_cert_file=/etc/letsencrypt/live/$MAIL_DOMAIN/fullchain.pem
smtpd_tls_key_file=/etc/letsencrypt/live/$MAIL_DOMAIN/privkey.pem
smtpd_tls_security_level=may
smtp_tls_security_level=may
smtpd_relay_restrictions = permit_mynetworks permit_sasl_authenticated defer_unauth_destination
myhostname = $MAIL_DOMAIN
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
myorigin = /etc/mailname
mydestination = \$myhostname, $DOMAIN, localhost.localdomain, localhost
relayhost = 
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
mailbox_size_limit = 0
recipient_delimiter = +
inet_interfaces = all
inet_protocols = all
home_mailbox = Maildir/
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_auth_enable = yes
EOF

echo "4. Configuring Dovecot..."
sed -i 's/#disable_plaintext_auth = yes/disable_plaintext_auth = no/g' /etc/dovecot/conf.d/10-auth.conf
sed -i 's/auth_mechanisms = plain/auth_mechanisms = plain login/g' /etc/dovecot/conf.d/10-auth.conf
sed -i 's|mail_location = mbox:~/mail:INBOX=/var/mail/%u|mail_location = maildir:~/Maildir|g' /etc/dovecot/conf.d/10-mail.conf

cat <<EOF > /etc/dovecot/conf.d/10-master.conf
service auth {
  unix_listener /var/spool/postfix/private/auth {
    mode = 0666
    user = postfix
    group = postfix
  }
}
EOF

# Setup SSL in Dovecot
sed -i "s|ssl_cert = </etc/dovecot/dovecot.pem|ssl_cert = </etc/letsencrypt/live/$MAIL_DOMAIN/fullchain.pem|g" /etc/dovecot/conf.d/10-ssl.conf
sed -i "s|ssl_key = </etc/dovecot/private/dovecot.pem|ssl_key = </etc/letsencrypt/live/$MAIL_DOMAIN/privkey.pem|g" /etc/dovecot/conf.d/10-ssl.conf

echo "5. Restarting Services..."
systemctl restart postfix
systemctl restart dovecot

echo "6. Creating email users..."
SUPPORT_PASS="Ra@38251176"
ADMIN_PASS="Ra@38251176"

# Add users
useradd -m support -s /usr/sbin/nologin || echo "User support already exists"
echo "support:$SUPPORT_PASS" | chpasswd
useradd -m admin -s /usr/sbin/nologin || echo "User admin already exists"
echo "admin:$ADMIN_PASS" | chpasswd

echo "=================================================="
echo " Mail server setup complete!"
echo ""
echo " You can now connect these emails to your personal Gmail:"
echo " 1. Go to Gmail -> Settings -> Accounts and Import"
echo " 2. Add a mail account you own (Check mail from other accounts)"
echo " 3. Email: support@$DOMAIN"
echo " 4. POP Server: $MAIL_DOMAIN (Port 995, Requires SSL)"
echo " 5. Username: support"
echo " 6. Password: <the password you just set>"
echo ""
echo " To send email as support@$DOMAIN from Gmail:"
echo " 1. Add another email address you own"
echo " 2. SMTP Server: $MAIL_DOMAIN (Port 465, SSL)"
echo " 3. Username: support"
echo " 4. Password: <the password you just set>"
echo "=================================================="
