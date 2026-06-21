# Payments Service Systemd Hardening Log

### Iterative Hardening Metrics
1. **Baseline State:** `6.7 (MEDIUM)`
2. **Phase 1 (Standard Confinement):** Added `NoNewPrivileges=true`, `PrivateTmp=true`, `ProtectSystem=strict`. -> **Score: 4.2**
3. **Phase 2 (Environment Confinement):** Added `ProtectHome=true`, `PrivateDevices=true`, `ProtectKernelTunables=true`, `ProtectControlGroups=true`. -> **Score: 3.1**
4. **Phase 3 (Advanced Sandbox):** Added `RestrictNamespaces=true`, `RestrictRealtime=true`, `LockPersonality=true`. -> **Score: 2.8**
5. **Phase 4 (Syscalls & Addressing):** Added `MemoryDenyWriteExecute=true`, `SystemCallFilter=@system-service`, `RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX`. -> **Final Score: 2.2**

### Rejected Directives
1. **`PrivateNetwork=true`**
   * *Justification:* Cuts off network socket allocations entirely. The payments processor must communicate with upstream financial endpoints; isolating networks breaks core operations.
2. **`RootDirectory=` (chroot jail)**
   * *Justification:* Requires dynamically mapping runtimes, interpreters, and dynamic libraries into a sub-tree root. The operational cost of maintaining a chroot environment outweighs its utility when filesystem namespaces are already strictly mounted.

### Final kk-payments.service Unit File
```ini
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
RestartSec=5s
StartLimitBurst=3
StartLimitIntervalSec=60s

ReadOnlyPaths=/opt/kijanikiosk/config
ReadWritePaths=/opt/kijanikiosk/shared/logs

NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
PrivateDevices=true
ProtectKernelTunables=true
ProtectControlGroups=true
RestrictNamespaces=true
RestrictRealtime=true
LockPersonality=true
MemoryDenyWriteExecute=true
SystemCallFilter=@system-service
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX

[Install]
WantedBy=multi-user.target