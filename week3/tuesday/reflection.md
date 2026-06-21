# Engineering Reflection: Linux Permissions

## Question 1: The SUID Paradox
**Response to Colleague:**
You are correct that the kernel ignores the SUID bit on interpreted scripts to prevent Time-of-Check to Time-of-Use (TOCTOU) race conditions—a vulnerability where an attacker manipulates the script or environment between the time the interpreter starts with elevated privileges and when the script actually runs. 

However, the SUID bit itself is a red herring here. The true vulnerability is the combination of the script being **world-writable** (`-xw-`) and its **operational context**. The incident report specifically stated that this `deploy.sh` script is executed automatically by a **root-owned cron job**. Because the file is world-writable, any low-privileged user (e.g., a compromised application service account) can append a malicious command to the script (e.g., `echo "cat /etc/shadow > /tmp/out" >> deploy.sh`). The moment the root cron job blindly executes the modified script, the attacker's payload runs with full root privileges. We aren't fixing a broken SUID implementation; we are closing a direct, world-writable backdoor into a root automation process.

## Question 2: Sudoers Policy Completeness
While `amina ALL=(root) NOPASSWD: /bin/systemctl restart *` looks cleaner, it is a massive security risk because wildcards in sudoers policies are notoriously difficult to bound safely. This policy grants Amina the ability to restart **any** service on the system, not just KijaniKiosk services.

Two concrete abuse scenarios this enables:
1. **Denial of Service (DoS):** An operator (or compromised account) could intentionally or accidentally run `sudo systemctl restart networkd` or `sudo systemctl restart sshd`, instantly severing connectivity to the server and causing a hard outage.
2. **Privilege Escalation via Malicious Service:** An attacker could write a custom `.service` file in a user-writable directory (like `/tmp/payload.service`) that executes a reverse shell or changes the root password. Because the wildcard allows interaction with *any* service name, the attacker can simply run `sudo systemctl start /tmp/payload.service` (or restart), forcing systemd to execute their arbitrary payload as root. 

## Question 3: nologin vs Locked Account
**Part A: Operational Difference**
Setting the shell to `/usr/sbin/nologin` prevents interactive terminal access but leaves the account active for system processes. Locking an account (`passwd -l`) disables password-based authentication entirely by placing a `!` in the shadow file. A locked account with a `nologin` shell cannot be logged into interactively AND cannot authenticate via PAM (Pluggable Authentication Modules). 

In production, you use `/usr/sbin/nologin` for service accounts (like `kk-api`) because they need to be active to own processes or be switched to by other automation (like `sudo -u kk-api`). You use `passwd -l` (account locking) for offboarding employees or temporarily suspending an account where you want to completely sever their ability to authenticate without deleting their home directory or files.

**Part B: Operational Scenario Failure**
If `kk-api` is locked (`passwd -l`), the deployment pipeline running `sudo -u kk-api /startup.sh` will likely fail if the system's PAM configuration requires an unlocked account for `su` or `sudo` transitions (which is common in hardened environments). 
* **The Failure at Runtime:** The CI/CD pipeline would crash, outputting a generic authentication or permissions error. The application would fail to start.
* **The Error in Logs:** The `/var/log/auth.log` would show an authentication failure or PAM rejection indicating the account is locked or expired.
* **Junior Engineer Misdiagnosis:** A junior engineer would likely see the pipeline failure and assume it is a standard Linux file permission issue on `startup.sh`, wasting time running `chmod` or checking SSH keys, failing to realize the account itself has been cryptographically disabled from executing processes.

## Question 4: ACLs vs Group Redesign
Replacing the ACLs with a single `kk-shared-logs` group containing `kk-api`, `kk-payments`, and `amina`, and making the directory group-writable (`770`), is a blunt instrument. 

* **Security Isolation:** The group redesign fails the principle of least privilege. It forces us to give `kk-payments` and `amina` **write** access to the logs, even though they only need **read** access. ACLs allow us to surgically apply read-only access to specific entities while maintaining write access for the API.
* **Auditability:** ACLs explicitly state the intent on the directory itself (e.g., `user:amina:r-x`). With a shared group, an auditor looking at the directory only sees `drwxrwx--- kk-logs kk-shared-logs`. To understand who actually has access, they have to cross-reference `/etc/group`, making audits more complex and opaque.
* **Operational Complexity:** The group approach is simpler to implement initially (no `setfacl` required). However, as the system scales (e.g., adding a billing service that needs read access, or a backup agent), managing a sprawling, over-privileged shared group becomes an operational nightmare compared to simply attaching a read-only ACL for the new service.