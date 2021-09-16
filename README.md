# GitHub action to rebase multiple PRs

## Environment Variables

- `PR_NUMBERS`: A space-delimited list of pull request numbers to attemp to rebase
- `COMMENT_ON_FAILURE` (`true`/`false`): Whether to add a comment to PRs that fail to rebase. Set to `false` by default
- `LOG_LINES`: The number of log lines to include in the failure comment, starting from the last line. Set to `1` by default
