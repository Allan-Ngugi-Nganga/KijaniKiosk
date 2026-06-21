# KijaniKiosk Access Model Design

## Directory Permissions Table
| Directory / File | Owner | Group | Mode | Additional ACLs |
| :--- | :--- | :--- | :--- | :--- |
| `/opt/kijanikiosk/api/` | `kk-api` | `kk-api` | `750` | `amina: r-x` |
| `/opt/kijanikiosk/payments/` | `kk-payments` | `kk-payments` | `750` | `amina: r-x` |
| `/opt/kijanikiosk/config/` | `root` | `kijanikiosk` | `750` (dir), `640` (files)| `amina: r-x` (dir), `amina: r--` (files) |
| `/opt/kijanikiosk/shared/logs/`| `kk-logs` | `kk-logs` | `2770` (SGID)| `kk-api: rwx`, `kk-payments: r-x`, `amina: r-x` |
| `/opt/kijanikiosk/scripts/deploy.sh`| `root` | `root` | `750` | None |

## Design Reasoning
* **Application Directories (`750`):** Follows strict least-privilege. The specific service account owns its directory, and world permissions are entirely removed.
* **Config Directory (`640` files):** Owned by `root` so the application services cannot maliciously or accidentally modify their own configuration files.
* **Shared Logs (`2770` with SGID & ACLs):** Standard `chmod` is insufficient here because multiple independent services (`kk-api`, `kk-payments`) need varying levels of access to the exact same directory. POSIX ACLs allow us to grant specific permissions to multiple users simultaneously. The SGID bit (`2`) ensures any files created inside automatically inherit the `kk-logs` group ownership.