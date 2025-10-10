#!/bin/bash

# ==========================================================================
#	@socials:medaly.dridi
# =========================================================================
# Configuration variables (EDIT THESE)
# ==============================================================================
GMAIL_USER="your_email@gmail.com"
GMAIL_APP_PASSWORD="your_app_password"
RECIPIENT_EMAIL="your_email@example.com"
MAIL_HOSTNAME="your_server_hostname"

# Log file for script output
LOG_FILE="/var/log/smtp_setup_$(date +%Y%m%d).log"

# Redirect all output to the log file
exec &> "$LOG_FILE"

echo "▶️ Starting universal Postfix setup for Gmail SMTP relay..."
echo "--------------------------------------------------"

# Detect the package manager
# ==============================================================================
if command -v apt >/dev/null; then
    PKG_MANAGER="apt"
    echo "ℹ️ Detected Debian/Ubuntu based system. Using apt."
elif command -v dnf >/dev/null; then
    PKG_MANAGER="dnf"
    echo "ℹ️ Detected Fedora/RHEL based system. Using dnf."
elif command -v pacman >/dev/null; then
    PKG_MANAGER="pacman"
    echo "ℹ️ Detected Arch Linux based system. Using pacman."
else
    echo "❌ Error: Could not detect a supported package manager (apt, dnf, or pacman)."
    exit 1
fi

# Install required packages
# ==============================================================================
case "$PKG_MANAGER" in
    apt)
        sudo apt update
        sudo apt install -y postfix mailutils libsasl2-2 ca-certificates libsasl2-modules
        ;;
    dnf)
        sudo dnf check-update
        sudo dnf install -y postfix mailx cyrus-sasl-plain
        ;;
    pacman)
        sudo pacman -Sy --noconfirm postfix mailutils
        ;;
esac

# Configure Postfix
# ==============================================================================
echo "▶️ Configuring Postfix..."

# Backup existing main.cf
sudo cp /etc/postfix/main.cf /etc/postfix/main.cf.bak

# Common Postfix settings
cat <<EOF | sudo tee /etc/postfix/main.cf > /dev/null
relayhost = [smtp.gmail.com]:587
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_use_tls = yes
myhostname = $MAIL_HOSTNAME
EOF

# Distribution-specific settings (CA certificates)
case "$PKG_MANAGER" in
    apt)
        echo "smtp_tls_CAfile = /etc/postfix/cacert.pem" | sudo tee -a /etc/postfix/main.cf > /dev/null
        # Certs are automatically handled by apt's ca-certificates
        ;;
    dnf)
        echo "smtp_tls_CAfile = /etc/ssl/certs/ca-bundle.crt" | sudo tee -a /etc/postfix/main.cf > /dev/null
        ;;
    pacman)
        echo "smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt" | sudo tee -a /etc/postfix/main.cf > /dev/null
        ;;
esac

# Configure authentication
# ==============================================================================
echo "▶️ Creating SASL password file..."
echo "[smtp.gmail.com]:587 $GMAIL_USER:$GMAIL_APP_PASSWORD" | sudo tee /etc/postfix/sasl_passwd > /dev/null
sudo chmod 600 /etc/postfix/sasl_passwd
sudo postmap /etc/postfix/sasl_passwd

# Reload Postfix
# ==============================================================================
echo "▶️ Reloading Postfix service..."
sudo systemctl restart postfix

# Send test email
# ==============================================================================
echo "▶️ Sending test email to $RECIPIENT_EMAIL..."
echo "This is a test email from your server via Gmail SMTP relay." | mail -s "Postfix Setup Test" "$RECIPIENT_EMAIL"

echo "✅ Script finished successfully. Check your email for the test message."
echo "--------------------------------------------------"
echo "Log file: $LOG_FILE"
echo "Mail logs can be found in /var/log/mail.log or similar."
