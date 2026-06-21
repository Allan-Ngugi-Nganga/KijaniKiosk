#!/bin/bash
# KijaniKiosk Baseline Provisioning Script (Wednesday Lab)

# Fail fast on errors, undefined variables, and pipeline failures
set -euo pipefail

# Structured Logging
log() { echo -e "[INFO] $(date +'%Y-%m-%dT%H:%M:%S%z') - $1"; }
success() { echo -e "[PASS] $1"; }
error() { echo -e "[FAIL] $1" >&2; exit 1; }

log "Starting KijaniKiosk Staging Provisioning..."

# === Pre-flight Checks ===
[[ $EUID -eq 0 ]] || error "This script must be run as root."
source /etc/os-release
[[ "$ID" == "ubuntu" ]] || error "This script requires Ubuntu."

# === Phase 1: Package Management ===
log "Phase 1: Installing pinned packages..."
apt-get update -qq
# Idempotent install: will only install if missing or different
apt-get install -y -qq nginx nodejs
# Hold packages against drift
apt-mark hold nginx nodejs >/dev/null

# === Phase 2: Service Accounts ===
log "Phase 2: Creating service accounts idempotently..."
getent group kijanikiosk >/dev/null || groupadd kijanikiosk

for svc in kk-api kk-payments kk-logs; do
    if id -u "$svc" >/dev/null 2>&1; then
        log "Already exists: $svc"
    else
        useradd -r -M -s /usr/sbin/nologin -c "KijaniKiosk $svc Service" "$svc"
        usermod -aG kijanikiosk "$svc"
        log "Created user: $svc"
    fi
done

# === Phase 3: Directory Structure & ACLs ===
log "Phase 3: Configuring directory structure and access model..."
mkdir -p /opt/kijanikiosk/{api,payments,logs,config,scripts,shared/logs}

# Ownership & Base Permissions
chown -R kk-api:kk-api /opt/kijanikiosk/api
chown -R kk-payments:kk-payments /opt/kijanikiosk/payments
chown -R kk-logs:kk-logs /opt/kijanikiosk/logs
chmod 750 /opt/kijanikiosk/{api,payments,logs}

chown root:kijanikiosk /opt/kijanikiosk/config
chmod 750 /opt/kijanikiosk/config

chown kk-logs:kk-logs /opt/kijanikiosk/shared/logs
chmod 2770 /opt/kijanikiosk/shared/logs

# Apply ACLs idempotently
setfacl -m u:kk-api:rwx /opt/kijanikiosk/shared/logs
setfacl -m u:kk-payments:r-x /opt/kijanikiosk/shared/logs
setfacl -d -m u:kk-api:rwx /opt/kijanikiosk/shared/logs
setfacl -d -m u:kk-payments:r-x /opt/kijanikiosk/shared/logs

# === Phase 4: Systemd Unit Deployment ===
log "Phase 4: Writing and enabling systemd units..."
cat << 'EOF' > /etc/systemd/system/kk-api.service
[Unit]
Description=KijaniKiosk API Service
After=network.target

[Service]
Type=simple
User=kk-api
Group=kk-api
WorkingDirectory=/opt/kijanikiosk/api
ExecStart=/usr/bin/node server.js
Restart=on-failure
RestartSec=5s
StartLimitBurst=3
StartLimitIntervalSec=60s

# Security Hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
# Extra Hardening for < 3.0 score
SystemCallFilter=@system-service
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable kk-api.service >/dev/null 2>&1

# === Phase 5: Firewall Configuration ===
log "Phase 5: Configuring UFW Firewall..."
# Reset idempotently
ufw --force reset >/dev/null
ufw default deny incoming >/dev/null
ufw default allow outgoing >/dev/null
# ALLOW 22 FIRST TO PREVENT LOCKOUT
ufw allow 22/tcp comment 'SSH Access' >/dev/null
ufw allow 80/tcp comment 'HTTP Nginx' >/dev/null
ufw --force enable >/dev/null

# === Phase 6: Verification ===
log "Phase 6: Verifying final state..."
failed=0

# Verify User
id kk-api >/dev/null || { error "Missing kk-api user"; ((failed++)); }
# Verify Packages
apt-mark showhold | grep -q nginx || { error "Nginx not held"; ((failed++)); }
# Verify Service
systemctl is-enabled kk-api.service >/dev/null || { error "Service not enabled"; ((failed++)); }
# Verify Firewall
ufw status | grep -q "22/tcp.*ALLOW" || { error "SSH not allowed"; ((failed++)); }

if [[ $failed -eq 0 ]]; then
    success "Provisioning complete. All checks passed."
else
    error "$failed checks failed."
fi
