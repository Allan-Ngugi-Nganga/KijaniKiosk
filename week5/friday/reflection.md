# Week 5 Reflection

## 1. Requirements in Tension
The most significant tension I encountered this week was between the strict requirement to use the pinned `node:18-alpine` Docker image and the requirement to tag the Nexus artifact with the Git SHA (`git rev-parse --short HEAD`). Alpine-based node images are exceptionally minimal and do not ship with the `git` binary installed. While my initial thought was to use `apk add git` inside the pipeline, this immediately conflicted with the security principle of running the Docker pipeline agent as a non-root user (`-u 1000:1000`), which prevents package installation. 

Faced with the choice of either bypassing the `alpine` image constraint, modifying the container to run in `--privileged` or `root` mode, or finding a workaround, I prioritized the environment constraints and security. I resolved the tension by relying natively on the Jenkins environment variables injected during the SCM checkout phase, using `echo $GIT_COMMIT | cut -c1-7` in Bash to securely evaluate the Git SHA without needing the `git` binary at all.

## 2. Audience Translation
**Board Document (for Nia):**
"If the code fails the initial proofreading stage, the system does not waste time or computing resources attempting to build or test it."

**Technical Equivalent (for Osei or Jenkinsfile):**
"The Jenkinsfile sequence places the `Lint` stage before `Build` to enforce the fail-fast principle, instantly terminating the job and skipping subsequent parallel verification and archiving stages if a syntax or code-style violation returns a non-zero exit code."

**Comparison:**
Both versions convey the identical outcome: the process stops early if an initial check fails. However, the board document uses metaphors ("proofreading stage", "waste time") and focuses entirely on the business value of resource conservation and immediate feedback. The technical equivalent is hyper-specific, explicitly naming the Jenkins configuration ("Jenkinsfile sequence"), the architectural principle ("fail-fast principle"), and the technical trigger ("non-zero exit code") required to achieve that outcome.

## 3. Scaling the Pipeline
Looking at the current pipeline design, if KijaniKiosk scales from four to forty developers, the **single part that would break first is the hardcoded Jenkins local executor capacity combined with the lack of `disableConcurrentBuilds()` logic or automated scaling.**

With forty developers pushing code simultaneously, the CI system will experience severe queueing. Currently, our Jenkins node spins up a new Docker container on the same host machine for every pipeline trigger. A sudden influx of concurrent commits would completely exhaust the host VM's CPU and memory resources, or queue indefinitely behind Jenkins' default executor limits. To resolve this, we would need to change the infrastructure from a standalone Jenkins server into a distributed architecture (e.g., Jenkins on Kubernetes) where dynamic build agents scale horizontally across multiple nodes based on webhook traffic volume, alongside implementing strict artifact collision handling for rapid-fire merges to the `master` branch.
