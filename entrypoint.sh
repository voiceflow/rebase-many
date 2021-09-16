#!/bin/bash

NEWLINE=$'\n'

# Configuration
: "${COMMENT_ON_FAILURE:=false}" # Whether to comment on the pull request that fails to rebase
: "${LOG_LINES:=1}" # Number of log lines to include in pull request comment

function rebase_failure {
  # Comment on PR with reason for failure
  "${COMMENT_ON_FAILURE}" && /ghcli/bin/gh pr comment $PR_NUMBER --body \
    "Failed to automatically rebase this pull request:$NEWLINE
    $2$NEWLINE
More details can be found in  workflow \"$GITHUB_WORKFLOW\" at https://github.com/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID"
}

for PR_NUMBER in $PR_NUMBERS
do
  if ! OUTPUT=$(PR_NUMBER=$PR_NUMBER /rebase/entrypoint.sh 2>&1)
  then
    REASON=$( echo "$OUTPUT" | tail -n "${LOG_LINES}" )
    rebase_failure "$PR_NUMBER" "$REASON"
  fi

  echo "$OUTPUT"
done
