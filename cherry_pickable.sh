#!/bin/bash

# Shell script to check which remote branches can be cherry-picked successfully with a given commit ID
# Usage: ./cherry-pick-checker. sh <commit-id>

# Check if commit ID is provided
if [ -z "$1" ]; then
    echo "Error: Commit ID is required"
    echo "Usage: $0 <commit-id>"
    exit 1
fi

COMMIT_ID="$1"
ORIGINAL_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Verify the commit exists
if ! git rev-parse --verify "$COMMIT_ID" > /dev/null 2>&1; then
    echo "Error:  Commit '$COMMIT_ID' does not exist"
    exit 1
fi

# Fetch all remote branches
git fetch --all --quiet --prune

REMOTE_BRANCHES=$(git branch -r | grep -v HEAD | awk '{print $1}' | sort)

echo "========================="
echo "cherry-pickable branches:"

while IFS= read -r BRANCH; do
    # Skip empty branch or original branch
    if [ -z "$BRANCH" ] || [ "$BRANCH" = "origin/$ORIGINAL_BRANCH" ]; then
        continue
    fi

    # Create a unique temporary branch for each iteration
    TEMP_BRANCH="temp_cherry_pick_test_$$_${RANDOM}"
    
    # Try to check out and test cherry-pick
    if git checkout -b "$TEMP_BRANCH" "$BRANCH"> /dev/null 2>&1; then
        if git cherry-pick "$COMMIT_ID"> /dev/null 2>&1; then
            echo "$BRANCH"
        else
            git cherry-pick --abort > /dev/null 2>&1 || true
        fi
    fi
    
    # Clean up:  return to original branch and delete temp branch
    git checkout "$ORIGINAL_BRANCH" > /dev/null 2>&1
    git branch -D "$TEMP_BRANCH" > /dev/null 2>&1
    
done <<< "$REMOTE_BRANCHES"
exit 0
