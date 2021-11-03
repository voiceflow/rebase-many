#!/bin/bash

NEWLINE=$'\n'

FAILED_LABEL="unable-auto-rebase"
FAILED_LABEL_COLOR="1D76DB"
FAILED_LABEL_DESCRIPTION="Pull requests that require manual action to rebase"

# Configuration
: "${COMMENT_ON_FAILURE:=false}" # Whether to comment on the pull request that fails to rebase
: "${LABEL_ON_FAILURE:=false}" # Whether to label the pull request that fails to rebase
: "${LOG_LINES:=1}" # Number of log lines to include in pull request comment

function rebase_failure {
  /ghcli/bin/gh pr view $1 --json labels --jq '.labels[].name' | grep "$FAILED_LABEL" >/dev/null
  NO_LABEL=$?

  # Comment on PR with reason for failure
  if "${COMMENT_ON_FAILURE}" && (( $NO_LABEL )); then
    echo "Posting comment on PR $1"
    /ghcli/bin/gh pr comment $1 --body \
    "Failed to automatically rebase this pull request:$NEWLINE
    $2$NEWLINE
More details can be found in  workflow \"$GITHUB_WORKFLOW\" at https://github.com/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID"
  fi

  if "${LABEL_ON_FAILURE}"; then
    # Ensure label exists before adding it
    $(/ghcli/bin/gh api /repos/{owner}/{repo}/labels --field name="$FAILED_LABEL" --field color="$FAILED_LABEL_COLOR" --field description="$FAILED_LABEL_DESCRIPTION") || echo "Label $FAILED_LABEL already exists in repo"

    # Add label denoting inability to automatically rebase
    echo "Adding label $FAILED_LABEL to PR $1"
    /ghcli/bin/gh pr edit $1 --add-label "$FAILED_LABEL"
  fi
}

for PR_NUMBER in $PR_NUMBERS
do
  if ! OUTPUT=$(PR_NUMBER=$PR_NUMBER /rebase/entrypoint.sh 2>&1)
  then
    REASON=$( echo "$OUTPUT" | tail -n "${LOG_LINES}" )
    rebase_failure "$PR_NUMBER" "$REASON"
  else
    # On success, remove label that indicates past failure
    echo "Removing label $FAILED_LABEL from PR $1 due to successful rebase"
    /ghcli/bin/gh pr edit $PR_NUMBER --remove-label "$FAILED_LABEL"
  fi

  # Remove fork remote for subsequent rebases
  if [[ "$(git remote)" == *fork* ]]; then
    git remote remove fork
  fi

  echo "$OUTPUT"
done
