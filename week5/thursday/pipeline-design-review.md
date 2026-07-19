# Pipeline Design Review

## 1. Docker Socket Mounting vs. Docker-in-Docker (DinD)
**Why is it safer to mount `/var/run/docker.sock` instead of running a full Docker daemon inside the Jenkins container?**
Mounting the host's Docker socket (often called Docker-out-of-Docker or DooD) allows the Jenkins container to use the host's existing Docker daemon to spin up sibling containers. This is significantly safer and less complex than running a full nested Docker daemon (Docker-in-Docker or DinD). DinD requires the Jenkins container to run in `--privileged` mode, which poses a massive security risk by granting the container near-root access to the host system. DooD avoids the `--privileged` requirement while providing the necessary containerization capabilities, at the slight trade-off that Jenkins containers are technically peers rather than children, meaning path mounts must align with the host's filesystem.

## 2. Ephemeral Credential Cleanup
**What is the advantage of using a trap command to clean up `.npmrc` compared to putting the `rm` command at the end of the script?**
Using a `trap "rm -f .npmrc" EXIT` command guarantees that the cleanup logic will execute regardless of how the shell script terminates. If the `npm publish` command fails midway (e.g., due to a network error, 401 Unauthorized, or a syntax issue), the script will exit immediately due to `set -e`. If the `rm` command were placed sequentially at the end of the script, it would be skipped entirely upon failure, leaving the plaintext `.npmrc` file (with credentials) lingering in the workspace. The `trap` acts as a finally-block, ensuring credential hygiene even during chaotic failure modes.

## 3. Branch-Specific Execution
**If we wanted to deploy to staging after publishing, what Jenkinsfile feature would ensure the deployment only runs if the `master` branch triggered the pipeline?**
In a Declarative Pipeline, we can use the `when` directive combined with the `branch` condition to restrict execution of a specific stage. For example:
```groovy
stage('Deploy to Staging') {
    when {
        branch 'master'
    }
    steps {
        // Deployment logic here
    }
}
```
This ensures that the deployment stage is completely bypassed for feature branches or pull requests, maintaining a safe and isolated continuous delivery strategy.

## Implementation Details & Limitations
During the pipeline construction, it was noted that the official `node:18-alpine` Docker image does not come with `git` pre-installed, and executing `apk add` inside the pipeline container fails because the Docker Pipeline plugin correctly runs the container as a non-root user (`-u 1000:1000`). To circumvent this while adhering to the Alpine image restriction, the pipeline utilizes the Jenkins-injected `$GIT_COMMIT` environment variable directly in Bash (`echo $GIT_COMMIT | cut -c1-7`) to evaluate the short SHA, completely bypassing the need for a `git` binary while achieving the exact same result.
