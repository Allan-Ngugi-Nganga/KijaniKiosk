# KijaniKiosk Pipeline Fault Injection Log

## 1. Lint Stage Failure
- **What Broke**: Introduced a syntax error (`const a =`) at the end of `index.js`.
- **Why**: Simulates a developer committing malformed JavaScript code.
- **Pipeline Behavior**: The pipeline failed immediately at the `Lint` stage because `node -c index.js test.js` detected the syntax error and returned a non-zero exit code.
- **Fail Fast**: Yes, the pipeline failed fast. Stages subsequent to `Lint` (such as `Build`, `Verify`, `Archive`, and `Publish`) were skipped entirely, conserving CI/CD resources. The `always` post condition ran and cleaned up the workspace.

## 2. Build Stage Failure
- **What Broke**: Modified the `Jenkinsfile` to misspell the `npm ci` command as `npm cci` in the Build stage.
- **Why**: Simulates an incorrect build script, a missing dependency issue, or an infrastructure failure during compilation.
- **Pipeline Behavior**: The pipeline passed the `Lint` stage but failed at the `Build` stage. The `sh` step returned exit code 1 because `npm cci` is an invalid command.
- **Fail Fast**: Yes, the pipeline failed fast at the `Build` stage. The parallel `Verify` stages (`Test` and `Security Audit`), along with `Archive` and `Publish`, were not executed.

## 3. Test Stage Failure
- **What Broke**: Modified `test.js` to forcefully exit with code `1` (`process.exit(1)`).
- **Why**: Simulates unit test failures or a broken test suite.
- **Pipeline Behavior**: The pipeline passed `Lint` and `Build`, then entered the parallel `Verify` stage. The `Test` branch failed (`exit code 1`). The `Archive` and `Publish` stages were subsequently skipped.
- **Parallel Stage Behavior (Security Audit)**: The `Security Audit` stage ran alongside the `Test` stage and completed successfully (`found 0 vulnerabilities`). By default, Jenkins parallel branches execute independently unless `failFast true` is configured. Therefore, the failure in the `Test` branch did not instantly kill the running `Security Audit` branch.

## 4. Publish Stage Failure
- **What Broke**: Modified the `NEXUS_URL` and registry in `.npmrc` to an incorrect repository (`npm-wrong-repo`).
- **Why**: Simulates an incorrect Nexus URL, invalid credentials, or network misconfiguration during artifact publishing.
- **Pipeline Behavior**: The pipeline successfully passed all prior stages (`Lint`, `Build`, `Verify`, `Archive`). The `Publish` stage failed when `npm publish` returned a 404/401 error because the repository does not exist or authorization failed.
- **Credential Security**: Despite the failure, the credentials were not leaked. The `.npmrc` file was safely removed by the `trap "rm -f .npmrc" EXIT` command, ensuring that ephemeral credentials do not persist in the workspace even upon failure. The Jenkins log masked the credentials natively via the `withCredentials` block.

