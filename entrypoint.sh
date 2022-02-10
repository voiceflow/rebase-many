#!/bin/bash

NEWLINE=$'\n'

FAILED_LABEL="unable-auto-rebase"
FAILED_LABEL_COLOR="1D76DB"
FAILED_LABEL_DESCRIPTION="Pull requests that require manual action to rebase"

# Configuration
: "${COMMENT_ON_FAILURE:=false}" # Whether to comment on the pull request that fails to rebase
: "${LABEL_ON_FAILURE:=false}" # Whether to label the pull request that fails to rebase
: "${LOG_LINES:=1}" # Number of log lines to include in pull request comment
: "${CHECK_DRAFT:=true}" # Check if a PR is a draft or not
: "${CHECK_BORS:=true}" # Check if Bors is running


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
  echo "Checking PR $PR_NUMBER"

  REBASE=true
  if [[ $CHECK_DRAFT || $CHECK_BORS ]]; then

    /ghcli/bin/gh pr view $PR_NUMBER --json comments,state,isDraft > pr_info.json
    if [[ $CHECK_DRAFT == true ]]; then
      DRAFT=$(cat pr_info.json | jq .isDraft)
      echo "Checking if the PR is a draft: $DRAFT"
      if [[ $DRAFT == true ]]; then
        REBASE=false
      fi
    fi
    if [[ $CHECK_BORS == true ]]; then
      # If bors is executing and the PR is not merged yet and number of bors+ !+ rojected by bors comments
      BORS_EXECUTING=$(cat pr_info.json | jq -c '[.comments[] | select(.body | contains ( "bors r+" ) )] | length' )
      BORS_REJECTED=$(cat pr_info.json | jq -c '[.comments[] | select(.body | contains ( ":-1: Rejected by" ) )] | length' )
      BORS_CANCELED=$(cat pr_info.json | jq -c '[.comments[] | select(.body | contains ( "Canceled." ) )] | length' )
      PR_MERGED_BY_BORS=$(cat pr_info.json | jq -c '[.comments[] | select(.body | contains ( "merged into master" ) )] | length')

      echo "Bors r+ messages found: $BORS_EXECUTING"
      echo "Bors canceled messages found: $BORS_CANCELED"
      echo "Bors rejected messages found: $BORS_REJECTED"
      echo "Bors merge messages found: $PR_MERGED_BY_BORS"
      if [[ $BORS_EXECUTING -gt 0 && $BORS_EXECUTING -ne $BORS_REJECTED && $BORS_EXECUTING -ne $BORS_CANCELED && $PR_MERGED_BY_BORS -eq 0 ]]; then
        REBASE=false
        echo "Bors is executing"
      else 
        echo "Bors is not executing"
      fi
    fi
  fi

  if [[ $REBASE == true ]]; then
    echo "Running rebase script for PR $PR_NUMBER"
    if ! OUTPUT=$(PR_NUMBER=$PR_NUMBER /rebase/entrypoint.sh 2>&1)
    then
      echo "Failed to rebase PR $PR_NUMBER"
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
  else
    echo "Avoiding rebase"
  fi
done
