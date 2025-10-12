#!/bin/bash
# medaly.dridi 
# Define your variables

REPO_PATH= "/path/to/your/project"
COMMIT_MESSAGE= "Automated commit on $(date + '%Y-%m-%d at %H:%M:%S')"
BRANCH_NAME="main"


if [ -z "$(git status --procelain)"]; then
	echo "No changes to commit."
	exit 0
fi

git pull origin "$BRANCH_NAME"
git add .
git commit -m "$COMMIT_MESSAGE"

git push origin "$BRANCH_NAME"

echo "Auto-push from Mini Arch complete at $(date +'%Y-%m-%d at %H:%M:%S')"

