# Reflection: Infrastructure as Code & Hardening

### 1. Conflict Discovery: Hardening vs. Runtime Stability
The conflict between security requirements and operational stability became apparent during the final phase of hardening the `kk-api.service`. I attempted to apply strict syscall filtering (`SystemCallFilter=@system-service`) and memory protection (`MemoryDenyWriteExecute=true`), which resulted in a `Fatal javascript OOM` and `signal 5/TRAP` errors. 

The JIT (Just-In-Time) compiler in the Node.js runtime requires memory pages to be simultaneously writable and executable to compile JavaScript into machine code. By hardening the service to prevent this, I effectively broke the application. I learned that security is not an absolute state but a series of calculated trade-offs; a perfectly secure, hardened service that is perpetually crashing is effectively an outage. I resolved this by relaxing the specific memory-protection directives for the API service while maintaining namespace isolation and filesystem protection to ensure the service remained functional.

### 2. Translating for Nia vs. Tendo
**Original sentence (for Nia):** "We locked down the system permissions so that unauthorized users cannot change the code or execute malicious scripts."

**Technical translation (for Tendo):** "I implemented `ProtectSystem=strict` and `RestrictSUIDSGID=true` to mitigate privilege escalation vectors and prevent unauthorized modification of the application binary or runtime environment."

**What is lost:** The high-level intent, which explains *why* the business cares about the change, is lost. Nia needs to know that the kiosk is "safe."
**What is gained:** Technical precision and auditability are gained. Tendo needs to know *specifically* which kernel controls were invoked to satisfy the security posture.

### 3. Most Fragile Component: Package & State Management
The most fragile part of my provisioning script is **Phase 1 (Package Management)** and **Phase 4 (Systemd Unit deployment)**. 

The script currently assumes a specific base state of the host (e.g., Ubuntu) and relies on `apt-mark hold` to manage state. In a real production environment, this is fragile because it doesn't account for:
- Existing package repositories or custom version pinning that might conflict with the `nodejs` installation.
- Pre-existing files in `/etc/systemd/system/` that may have been created by another configuration management tool (e.g., Puppet or Chef), leading to unexpected overrides or service collisions.

**What I would need to know to make it robust:**
To move this from a "test VM" script to "production grade," I would need to perform an environment discovery phase (or "fact-gathering") before execution. I would need to know:
- The exact OS distribution and version (beyond just "Ubuntu").
- The state of configuration management agents (is there a lockfile preventing changes?).
- The current version of dependencies currently running in the environment to ensure a non-destructive upgrade path.