# Deployment Recovery Runbook

This document outlines the standard operating procedure for recovering from a failed deployment to ensure maximum system reliability and minimum downtime.

## Emergency Recovery Steps

1. **Identify and Isolate the Failure**
   Check the real-time system metrics and alert dashboards to isolate whether the failure is affecting the entire system or a specific microservice.

2. **Trigger an Immediate Rollback**
   Revert the production environment to the last known stable build. Run the deployment script using the previous stable version tag to minimize user impact.

3. **Verify System Health Post-Rollback**
   Execute automated health check endpoints (`/healthz` or `/status`) and check application logs to confirm that traffic has normalized and errors have subsided.

4. **Notify Stakeholders and Team**
   Update the internal status page and alert the relevant engineering teams with a brief summary of the incident and current mitigation status.

5. **Preserve Logs and Initiate Blameless Post-Mortem**
   Export the error logs and crash dumps from the failed container/server before they are overwritten. Schedule a team review to analyze root causes without assigning blame.