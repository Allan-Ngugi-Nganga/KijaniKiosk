The First Way: Flow


Figure 1: Flow — Courtesy of alpacked.io

The first principle focuses on flow. Flow refers to how smoothly work moves from the moment an idea is created until it is running in production.

In many organizations, work moves slowly because it is blocked between stages of the delivery process. Code may wait for testing environments, approval from another team, or manual deployment procedures.

When work accumulates in this way, releases become large and risky. Debugging problems becomes difficult because many changes are deployed simultaneously.

High-performing DevOps teams focus on creating continuous flow by:

Breaking work into smaller changes
Reducing manual handoffs between teams
Automating repetitive steps such as builds and deployments
Delivering software frequently rather than in large batches
The goal of improving flow is not simply speed. The goal is to reduce complexity and risk by making each change small and manageable.


The Second Way: Feedback


Figure 2: Feedback — Courtesy of alpacked.io

The second principle focuses on feedback loops. Feedback ensures that the delivery system quickly detects when something goes wrong.

Without feedback, teams may continue developing software for weeks before discovering that an error was introduced earlier in the process.

Effective DevOps systems introduce feedback at multiple points in the pipeline. Examples include:

Automated tests that run when code is committed
Code reviews that catch design issues early
Continuous Integration pipelines that detect integration problems
Monitoring systems that detect production failures
The earlier a problem is detected, the cheaper and easier it is to fix. Detecting a bug during development may take minutes to fix, while discovering the same bug in production could require hours of investigation and potentially disrupt customers.

Feedback loops also improve communication across teams. Instead of waiting for incidents to occur, engineers receive immediate signals about whether their changes work correctly.


The Third Way: Continuous Learning


Figure 3: Learning — Courtesy of alpacked.io

The third principle focuses on learning. Every incident, failure, or mistake should lead to an improvement in the system.

Traditional organizations sometimes treat incidents as individual mistakes. DevOps instead treats incidents as signals that the system needs improvement.

For example, if a deployment fails because a required configuration file is missing, the solution should not only be to fix the file. The team should also introduce a guardrail that prevents the same mistake from occurring again.

Examples of learning mechanisms include:

Post-incident reviews that focus on system improvements rather than blame
Automation that prevents repeated human errors
Runbooks that guide engineers during operational incidents
Documentation that captures lessons learned
Organizations that practice continuous learning become more resilient over time because their systems gradually improve after each incident.


The Three Ways in the KijaniKiosk Platform
Scenario
The KijaniKiosk engineering team currently releases software once every month.

Large numbers of changes accumulate between releases.
Deployments require a weekend war-room.
Incidents frequently occur immediately after releases.
Applying the Three Ways could transform the delivery system:

Flow: Smaller changes merged frequently instead of large monthly releases
Feedback: Automated CI pipelines detect errors immediately after code is committed
Learning: Incidents produce guardrails such as automated checks and runbooks
Over time these improvements allow the team to deploy software safely during normal working hours rather than relying on high-risk release events.