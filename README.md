# GitHub action to rebase multiple PRs

A wrapper around [cirrus-actions/rebase](https://github.com/cirrus-actions/rebase) to allow rebasing multiple pull requests with a single action.

## Environment Variables

- `PR_NUMBERS`: A space-delimited list of pull request numbers to attemp to rebase
- `COMMENT_ON_FAILURE` (`true`/`false`): Whether to add a comment to PRs that fail to rebase. Set to `false` by default
- `LABEL_ON_FAILURE` (`true`/`false`): Whether to add a label to PRs that fail to rebase. When the label is present, additional comments will not be added. Set to `false` by default
- `LOG_LINES`: The number of log lines to include in the failure comment, starting from the last line. Set to `1` by default
