#!/usr/bin/env bash
# Usage: gh-backup.sh <repo-name> <folder> ["commit message"] ["description"]
# Creates PRIVATE repo richrimsft/<repo-name> if missing, then commits & pushes <folder>.
# Needs GITHUB_TOKEN in env. Token is never printed or written to .git/config.
set -euo pipefail
OWNER=richrimsft
NAME=${1:?repo name}; SRC=${2:?folder}; MSG=${3:-"Backup $(date '+%F %T %Z')"}; DESC=${4:-""}
[ -n "${GITHUB_TOKEN:-}" ] || { echo "GITHUB_TOKEN not set" >&2; exit 1; }
[ -d "$SRC" ] || { echo "No such folder: $SRC" >&2; exit 1; }
API=https://api.github.com; AUTH=(-H "Authorization: Bearer $GITHUB_TOKEN" -H "Accept: application/vnd.github+json")
code=$(curl -s -o /tmp/ghb.$$ -w '%{http_code}' "${AUTH[@]}" "$API/repos/$OWNER/$NAME")
if [ "$code" = 404 ]; then
  body=$(python3 -c 'import json,sys;print(json.dumps({"name":sys.argv[1],"description":sys.argv[2],"private":True}))' "$NAME" "$DESC")
  curl -sf "${AUTH[@]}" -X POST "$API/user/repos" -d "$body" >/dev/null && echo "Created private repo $OWNER/$NAME"
elif [ "$code" = 200 ]; then
  python3 -c 'import json;d=json.load(open("/tmp/ghb.'$$'"));exit(0 if d["private"] else 1)' || { echo "Refusing: $OWNER/$NAME is PUBLIC" >&2; rm -f /tmp/ghb.$$; exit 1; }
else echo "API error $code" >&2; rm -f /tmp/ghb.$$; exit 1; fi
rm -f /tmp/ghb.$$
ASK=$(mktemp); trap 'rm -f "$ASK"; rm -rf "${WORK:-}"' EXIT
printf '#!/bin/sh\ncase "$1" in Username*) echo x-access-token;; *) echo "$GITHUB_TOKEN";; esac\n' > "$ASK"; chmod 700 "$ASK"
export GIT_ASKPASS="$ASK" GIT_TERMINAL_PROMPT=0
URL="https://github.com/$OWNER/$NAME.git"; WORK=$(mktemp -d)
git clone -q "$URL" "$WORK/r" 2>/dev/null || { git init -q -b main "$WORK/r"; git -C "$WORK/r" remote add origin "$URL"; }
tar -C "$SRC" --exclude=.git --exclude='.env*' --exclude='*.pem' --exclude='*.key' --exclude='id_*' -cf - . | tar -C "$WORK/r" -xf -
cd "$WORK/r"; git add -A
if git diff --cached --quiet; then echo "No changes"; exit 0; fi
git -c user.name=$OWNER -c user.email=$OWNER@users.noreply.github.com commit -qm "$MSG"
git push -q origin HEAD:main
echo "Pushed to https://github.com/$OWNER/$NAME (private)"
