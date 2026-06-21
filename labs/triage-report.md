# KijaniKiosk API Server - Triage Report

**Date:** June 21, 2026
**Investigated by:** Allan Ng'ang'a
**Server:** localhost
**Incident start (approximate):** 04:07 (Based on first hard log errors)

## Summary
The system experienced a cascading failure initiated by database connection pool exhaustion, followed rapidly by a rogue process consuming massive system memory. Currently, the API is entirely offline (returning 404s), and the Node.js application cannot connect to the database. Additionally, a log rotation failure has left a large orphaned file on disk.

## Process and Resource State
* **High Memory Consumption:** A background `python3` process (PID: [Insert PID from Area 1]) was discovered consuming ~3.3% of system memory (approx. 511 MB). 
* This correlates precisely with the `WARN Memory usage at 87%` alert found in the application logs.
* System memory is otherwise stable (`[Insert total available memory from Area 1]` available).

## Filesystem and Disk
* The primary partition is healthy at 70% capacity.
* **Log Rotation Failure:** An orphaned log file, `/var/log/kijanikiosk/access.log.1`, has ballooned to 271M, making it the largest file in the directory. This indicates a failure in `logrotate`, posing a future risk of disk exhaustion.

## Log Analysis
A review of `/var/log/kijanikiosk/app.log` reveals the failure timeline:
* **04:07:55:** Connection pool exhausted, forcing request queuing.
* **04:08:01:** Queries to `orders` and `products` timed out (30,000ms).
* **04:09:12:** Memory usage warnings triggered (correlating to the rogue Python process).
* **06:22:18 - 06:22:28:** Complete database failure (`ECONNREFUSED database:5432`), followed by retry limits being reached.

## Network and Service State
* **Web Server:** NGINX is alive on port 80 and returning `HTTP 200` in ~1ms.
* **API/Database:** The `/api/health` endpoint is returning `HTTP 404`, indicating the Node app is not routing traffic. While port 5432 is in a `LISTEN` state, the application logs confirm it is actively refusing connections from the app.
* TCP connections are low (`5 established`), confirming no active traffic pile-ups.

## Assessment
The P95 latency spike reported by Osei was the first symptom of a connection pool exhaustion event at 04:07. This was rapidly compounded by a rogue Python process consuming memory, starving the system. Ultimately, the database persistence layer failed entirely by 06:22. The API is now completely down.

## Recommended Next Steps
1.  **Kill Rogue Process:** Run `kill -9 [Insert Python PID]` to terminate the memory-consuming Python script immediately.
2.  **Database Triage:** Investigate the PostgreSQL service on port 5432 to determine why it is refusing connections to the Node app, and restart the Node application.
3.  **Clean Disk:** Delete `/var/log/kijanikiosk/access.log.1` and fix the `logrotate` configuration for the KijaniKiosk app.