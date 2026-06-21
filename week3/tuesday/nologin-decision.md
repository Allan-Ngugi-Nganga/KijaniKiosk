# Service Account Shell Decision

For the KijaniKiosk service accounts (`kk-api`, `kk-payments`, `kk-logs`), the shell `/usr/sbin/nologin` was selected over `/bin/false`. 

**Reasoning:**
While both configurations prevent interactive terminal access, they handle the rejection differently. 
* `/bin/false` does exactly one thing: it immediately exits with a non-zero status code. It provides no output to the user and logs nothing.
* `/usr/sbin/nologin` actively and politely rejects the login, displaying a message (e.g., "This account is currently not available") and, crucially, logs the failed login attempt to the system auth logs. 

In a production environment, operational visibility is critical. If a threat actor attempts to brute-force or interactively log into a background service account, `/usr/sbin/nologin` ensures that the security team has an auditable log trace of the attempt, whereas `/bin/false` would fail silently.