#!/bin/bash
# KijaniKiosk Production Provisioning Script (Friday Capstone)

set -euo pipefail

# === Logging Functions ===
log() { echo -e "[INFO] $(date +'%Y-%m-%dT%H:%M:%S%z') - $1"; }
success() { echo -e "[PASS] $1"; }
error() { echo -e "[FAIL] $1" >&2; exit 1; }

log "Starting KijaniKiosk Production Provisioning..."

# === Phase 1: Package Management ===
log "Phase 1: Checking and installing pinned packages..."
apt-get update -qq
if apt-mark showhold | grep -q "nginx"; then
    log "Packages already held. Skipping install."
else
    apt-get install -y -qq nginx nodejs
    apt-mark hold nginx nodejs >/dev/null
fi

# === Phase 2: Service Accounts ===
log "Phase 2: Provisioning service accounts..."
getent group kijanikiosk >/dev/null || groupadd kijanikiosk
for svc in kk-api kk-payments kk-logs; do
    if id -u "$svc" >/dev/null 2>&1; then log "Already exists: $svc"; else
        useradd -r -M -s /usr/sbin/nologin -g kijanikiosk "$svc"
    fi
done

# === Phase 3: Directory Structure & Access Model ===
log "Phase 3: Configuring directory structure..."
mkdir -p /opt/kijanikiosk/{api,payments,logs,config,scripts,shared/logs,health}
chown -R kk-api:kijanikiosk /opt/kijanikiosk/api
chown -R kk-payments:kijanikiosk /opt/kijanikiosk/payments
chown -R kk-logs:kijanikiosk /opt/kijanikiosk/logs
chmod 750 /opt/kijanikiosk/{api,payments,logs}
chown root:kijanikiosk /opt/kijanikiosk/config
chmod 750 /opt/kijanikiosk/config
touch /opt/kijanikiosk/config/api.env /opt/kijanikiosk/config/payments-api.env
chmod 640 /opt/kijanikiosk/config/*.env
chown kk-logs:kk-logs /opt/kijanikiosk/shared/logs
chmod 2770 /opt/kijanikiosk/shared/logs
chown root:kijanikiosk /opt/kijanikiosk/health
chmod 750 /opt/kijanikiosk/health

# Apply ACLs
setfacl -m u:kk-api:rwx /opt/kijanikiosk/shared/logs
setfacl -m u:kk-payments:r-x /opt/kijanikiosk/shared/logs
setfacl -d -m u:kk-api:rwx /opt/kijanikiosk/shared/logs
setfacl -d -m u:kk-payments:r-x /opt/kijanikiosk/shared/logs

# === Phase 4: Production Systemd Units ===
log "Phase 4: Writing hardened systemd units..."

# 1. API Service Unit (< 3.5)
cat << 'EOF' > /etc/systemd/system/kk-api.service
[Unit]
Description=KijaniKiosk API Service
After=network.target

[Service]
Type=simple
User=kk-api
Group=kk-api
WorkingDirectory=/opt/kijanikiosk/api
EnvironmentFile=/opt/kijanikiosk/config/api.env
ExecStart=/usr/bin/node server.js
Restart=on-failure

# Security Hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
PrivateDevices=true
ProtectKernelTunables=true
ProtectControlGroups=true
ProtectClock=true
ProtectKernelLogs=true
ProtectKernelModules=true
ProtectHostname=true
RestrictSUIDSGID=true
UMask=0027
RemoveIPC=true
CapabilityBoundingSet=
RestrictNamespaces=~user pid net mnt uts cgroup ipc
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
SystemCallFilter=@system-service @network-io

[Install]
WantedBy=multi-user.target
EOF

# 2. Payments Service Unit
cat << 'EOF' > /etc/systemd/system/kk-payments.service
[Unit]
Description=KijaniKiosk Payments Service
After=network.target kk-api.service
Wants=kk-api.service

[Service]
Type=simple
User=kk-payments
Group=kk-payments
WorkingDirectory=/opt/kijanikiosk/payments
EnvironmentFile=/opt/kijanikiosk/config/payments-api.env
ExecStart=/usr/bin/python3 processor.py
Restart=on-failure
# Final Security Hardening
CapabilityBoundingSet=
SystemCallFilter=@system-service @network-io

ReadOnlyPaths=/opt/kijanikiosk/config
ReadWritePaths=/opt/kijanikiosk/shared/logs

NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
PrivateDevices=true
ProtectKernelTunables=true
ProtectControlGroups=true
ProtectClock=true
ProtectKernelLogs=true
ProtectKernelModules=true
ProtectHostname=true
RestrictSUIDSGID=true
MemoryDenyWriteExecute=true
CapabilityBoundingSet=
RestrictNamespaces=~user pid mnt uts cgroup ipc
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
IPAddressDeny=any
IPAddressAllow=127.0.0.1 10.0.1.0/24
UMask=0027

[Install]
WantedBy=multi-user.target
EOF

# 3. Logs Service Unit (< 3.5)
cat << 'EOF' > /etc/systemd/system/kk-logs.service
[Unit]
Description=KijaniKiosk Logs Aggregator
After=network.target

[Service]
Type=simple
User=kk-logs
Group=kk-logs
WorkingDirectory=/opt/kijanikiosk/logs
ExecStart=/usr/bin/python3 log_aggregator.py
Restart=on-failure

# Security Hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
PrivateDevices=true
ProtectKernelTunables=true
ProtectControlGroups=true
ProtectClock=true
ProtectKernelLogs=true
ProtectKernelModules=true
ProtectHostname=true
RestrictSUIDSGID=true
UMask=0027
RemoveIPC=true
CapabilityBoundingSet=
RestrictNamespaces=~user pid net mnt uts cgroup ipc
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
SystemCallFilter=@system-service @network-io

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable kk-api.service kk-payments.service kk-logs.service >/dev/null 2>&1
systemctl restart kk-api.service kk-payments.service kk-logs.service >/dev/null 2>&1

# === Phase 5: Firewall Rules ===
log "Phase 5: Configuring UFW..."
ufw --force reset >/dev/null
ufw default deny incoming >/dev/null
ufw default allow outgoing >/dev/null
ufw allow 22/tcp comment 'SSH Access'
ufw allow 80/tcp comment 'HTTP Nginx'
ufw allow from 10.0.1.0/24 to any port 3001 proto tcp comment 'Monitoring Subnet Health Checks'
ufw allow in on lo to any port 3001 proto tcp comment 'Internal Loopback Proxy'
ufw deny 3001/tcp comment 'Explicit External Deny for Internal Payments Port'
ufw --force enable >/dev/null

# === Phase 7: Journal & Logrotate ===
log "Phase 7: Configuring Journal/Logrotate..."
mkdir -p /var/log/journal
sed -i 's/.*SystemMaxUse=.*/SystemMaxUse=500M/' /etc/systemd/journald.conf
systemctl restart systemd-journald

cat << 'EOF' > /etc/logrotate.d/kijanikiosk
/opt/kijanikiosk/shared/logs/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 640 kk-logs kk-logs
    sharedscripts
    su kk-logs kk-logs
    postrotate
        systemctl restart kk-logs.service > /dev/null 2>&1 || true
    endscript
}
EOF

# === Phase 8: Monitoring Health Checks ===
log "Phase 8: Executing Health Checks..."
api_status=$(timeout 2 bash -c "echo >/dev/tcp/localhost/3000" 2>/dev/null && echo '"ok"' || echo '"down"')
payments_status=$(timeout 2 bash -c "echo >/dev/tcp/localhost/3001" 2>/dev/null && echo '"ok"' || echo '"down"')

printf '{"timestamp":"%s","kk-api":%s,"kk-payments":%s}\n' "$(date -Is)" "$api_status" "$payments_status" > /opt/kijanikiosk/health/last-provision.json
chown root:kijanikiosk /opt/kijanikiosk/health/last-provision.json
chmod 640 /opt/kijanikiosk/health/last-provision.json

# === Phase 6: Final Verification ===
log "Phase 6: Verifying Provisioning State..."
failed=0
ufw_status=$(ufw status)
echo "$ufw_status" | grep -q "22/tcp.*ALLOW" || { echo "FAIL: SSH missing"; ((failed++)); }
echo "$ufw_status" | grep -q "3001.*DENY" || { echo "FAIL: 3001 deny missing"; ((failed++)); }
[ -f /etc/logrotate.d/kijanikiosk ] || { echo "FAIL: Logrotate missing"; ((failed++)); }
[ -f /opt/kijanikiosk/health/last-provision.json ] || { echo "FAIL: Health check missing"; ((failed++)); }

if [[ $failed -eq 0 ]]; then success "PROVISIONING COMPLETE."; exit 0; else error "FAILED with $failed errors."; fi