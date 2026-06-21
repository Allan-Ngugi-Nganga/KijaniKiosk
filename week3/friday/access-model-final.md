# KijaniKiosk Final Access Model Design

## Directory Permissions Table
| Directory / File | Owner | Group | Mode | Additional ACLs |
| :--- | :--- | :--- | :--- | :--- |
| `/opt/kijanikiosk/api/` | `kk-api` | `kijanikiosk` | `750` | `amina: r-x` |
| `/opt/kijanikiosk/payments/` | `kk-payments` | `kijanikiosk` | `750` | `amina: r-x` |
| `/opt/kijanikiosk/config/` | `root` | `kijanikiosk` | `750` (dir), `640` (files)| `amina: r-x` (dir), `amina: r--` (files) |
| `/opt/kijanikiosk/shared/logs/`| `kk-logs` | `kk-logs` | `2770` (SGID)| `kk-api: rwx`, `kk-payments: r-x`, `amina: r-x` |
| `/opt/kijanikiosk/health/` | `root` | `kijanikiosk` | `750` | None |
| `last-provision.json` | `root` | `kijanikiosk` | `640` | None |

## Logrotate Interaction Notes
When `logrotate` rotates log files within the shared directory, its `create 640 kk-logs kk-logs` directive defines basic POSIX modes for the newly spawned files. Uninterrupted read/write access for the API and payments services is preserved via **Default ACLs** (`setfacl -d`) applied to the parent directory. Inherited default ACL rules natively propagate to newly created files, ensuring the access model survives automated rotations.