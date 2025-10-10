#!/bin/bash

# =================================================================
# A robust script to add, commit, and push changes to Git.
# It checks for a commit message and for actual changes before
# proceeding.
# =================================================================

# Exit immediately if a command exits with a non-zero status.
set -e

# --- 1. Check for a commit message ---
if [ $# -eq 0 ]; then
  echo "Error: No commit message provided."
  echo "Usage: ./gcp.sh \"Your commit message\""
  exit 1
fi

# Combine all command-line arguments into a single string for the commit message.
COMMIT_MESSAGE="$@"

# --- 2. Check for changes ---
# `git status --porcelain` is empty if there are no changes.
if [ -z "$(git status --porcelain)" ]; then
  echo "No changes to commit. Working tree is clean."
  exit 0
fi

# --- 3. Execute Git Commands ---
echo "▶️ Staging all changes..."
git add .

echo "▶️ Committing with message: '$COMMIT_MESSAGE'..."
git commit -m "$COMMIT_MESSAGE"

echo "▶️ Pushing to origin main..."
git push origin main

echo "✅ All done! Changes have been pushed."
