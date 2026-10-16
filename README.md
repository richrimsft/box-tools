# box-tools
Helper scripts for the box.
- gh-backup.sh <repo> <folder> [msg] [desc]: create a PRIVATE repo on richrimsft (refuses public) and push a folder, skipping .git, .env*, *.pem, *.key, id_*. Needs GITHUB_TOKEN.
- git-askpass.sh: GIT_ASKPASS helper that reads GITHUB_TOKEN from the environment (never stores it).
