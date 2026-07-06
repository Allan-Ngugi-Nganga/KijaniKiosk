# Project Reflection

## 1. Balancing Conflicting Requirements
The primary conflict encountered was between **maximum security hardening** and **application operational stability**. Specifically, implementing `ProtectSystem=strict` and `PrivateTmp=true` effectively "locked" the application inside a sandbox. 

Initially, this caused the service to fail because it attempted to perform standard operations (logging and temp file generation) that the hardened system policy interpreted as unauthorized attempts to modify the root filesystem. The resolution involved adjusting the application's working directory to a dedicated `/opt/kijanikiosk/` path and ensuring the service had explicit permissions to operate within that environment, effectively balancing the need for a "zero-trust" host environment with the functional requirements of the payment application.

## 2. Translation: Nia (Stakeholder) to Tendo (Tech Lead)
**Nia's Statement:** 
*"The application is now safe because we’ve made it impossible for it to see or touch anything else on the server, even though it's still doing its job."*

**Tendo's Technical Translation:**
*"We have successfully implemented PID and Mount namespace isolation via systemd unit directives (specifically `ProtectProc=invisible` and `ProcSubset=pid`). This limits the application's visibility to the process tree, mitigating risks of lateral movement. By combining this with `RestrictNamespaces=yes` and `ProtectSystem=strict`, we have enforced strict sandbox enforcement, ensuring the service operates with Least Privilege while maintaining its functional service-level objectives."*

## 3. The Most Fragile Pipeline Handoff
The most fragile point in the pipeline is the **handoff between the Terraform output and the Ansible inventory generation**. 

The current pipeline relies on a custom script to parse the `terraform output` (JSON) and inject it into the Ansible inventory. This coupling is brittle because it assumes a static output structure. If a future change modifies the Terraform output keys (e.g., changing the server naming convention) or if the JSON parsing logic fails to handle an empty state, the Ansible phase will either fail to execute or, worse, attempt to configure the wrong host. To harden this, we should transition to a dynamic inventory plugin that queries the AWS API directly, removing the need for intermediary file parsing.