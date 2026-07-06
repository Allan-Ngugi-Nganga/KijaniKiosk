# Manual Provisioning Decisions - KijaniKiosk API Server

| Decision          | Value I chose | Reason |
|-------------------|---------------|--------|
| Cloud provider    | MUltipass              | free and easy to setup       |
| Region            | localhost              | not available       |
| Operating system  |  Ubuntu 22.04          | Requested in lab       |
| Instance type     | 1 CPU, 1G RAM          | Required for the lab constraints       | 
| VPC               |  Default               |        |
| Subnet            |  Default               |        |
| Security group    |  Default               |        |
| SSH key pair      |  MUltipass Default     |        |
| Root volume size  |  5G                    |        |
| Public IP?        |  No                    | Local network only       |
| Tags / labels     |  name: kijanikiosk-api | Identification       |