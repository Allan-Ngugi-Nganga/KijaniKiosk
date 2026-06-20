## Working Directory vs Staging vs History
The working directory is where files are edited. The staging area holds prepared modifications before a snapshot is taken. The history contains all permanently saved commits.

## Branching Rules
Always create a short-lived feature branch off of the main branch. Never commit directly to master.
Note: The git commit -am shortcut only works on tracked files and will completely ignore brand-new files.

## Pull Request Expectations
Every pull request must contain concise commit messages, undergo peer review, and pass automated CI checks before being merged.

