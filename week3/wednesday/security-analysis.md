# Systemd Security Hardening Analysis

Initial Baseline Score: ~3.8
Final Score Achieved: < 3.0

### Additional Hardening Directives Applied:

1. `SystemCallFilter=@system-service`
   - **What it does:** Uses a predefined systemd group to block the service from executing dangerous kernel system calls.
   - **Why I chose it:** Node.js APIs only need standard networking and file I/O. Restricting the syscall surface area limits what an attacker can do if they achieve Remote Code Execution (RCE).

2. `RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX`
   - **What it does:** Restricts the types of network sockets the service can open.
   - **Why I chose it:** An API server only needs IPv4 (`AF_INET`), IPv6 (`AF_INET6`), and local Unix sockets (`AF_UNIX`). Denying exotic socket types prevents an attacker from pivoting or sniffing network traffic.