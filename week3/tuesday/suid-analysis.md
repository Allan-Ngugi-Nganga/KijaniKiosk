# SUID Vulnerability Analysis

**1. Why does the kernel ignore SUID on interpreted scripts?**
Modern Linux kernels ignore the SUID bit on scripts (files starting with a `#!` shebang) because they are highly susceptible to Time-of-Check to Time-of-Use (TOCTOU) race conditions. When an SUID script runs, the kernel actually executes the interpreter (e.g., `/bin/bash`), not the script itself. Passing elevated privileges to an interpreter while reading a script from user space allows attackers to manipulate environment variables (like `PATH` or `IFS`) or swap the script via symlinks just before execution, easily hijacking the root context.

**2. If the SUID bit has no effect, why is SUID + world-write still a critical finding?**
The SUID bit here is a red herring; the real critical vulnerability is the world-writable (`-xw-`) permission combined with the context of how the script is used. The scenario notes that this script is executed by a root-owned cron job. Because it is world-writable, any unprivileged user on the system can alter the script's contents.

**3. What would make this scenario exploitable in practice?**
An attacker who gains access to a low-privileged account (like `www-data` or `kk-api`) simply needs to append a malicious command to `deploy.sh`. For example, they could run:
`echo "cat /etc/shadow > /tmp/shadow.txt && chmod 777 /tmp/shadow.txt" >> /opt/kijanikiosk/scripts/deploy.sh`
The moment the root-owned cron job executes the deployment script, the attacker's payload runs with full root privileges, resulting in a complete system compromise.