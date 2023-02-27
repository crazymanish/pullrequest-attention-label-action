## Add an attention label to an open pull-request
A GitHub action to add an attention label on an open pull-request after certain days.

## Usage
This Action uses the [Pull request api](https://developer.github.com/v3/issues/#list-issues-for-a-repository) which will fire on the [scheduled_event](https://help.github.com/en/actions/reference/events-that-trigger-workflows#scheduled-events-schedule) .

### Input
The action requires three environment variables
- `ADD_LABEL`: The label name to add. **Mandatory** variable.
- `AFTER_DAYS`: The number of days from pull request creation date. **Optional** variable, default value is `3 days`.
- `SKIP_LABELS`: The **comma separated** labels string. If an open pull-request have one of those label then this action will skip adding the attention label. **Optional** variable, default value is `work-in-progress,wip`.

### Example Use-case
- `Problem`: Let's say, we need to add an reviewer attention label `need-review` for code-review of an open pull-request, when it is 4 days old. We need to skip the open pull request, if already have approved/wip label. Also lets add reviewer attention label only in working days Monday-Friday(5days).
- `Solution`: Schedule a GitHub action to add `need-review` label for those 4 days old open pull-requests.

#### GitHub action workflow file
```workflow
name: Add an attention label to an open pull request for review after 4 days.
on:
  schedule:
  - cron:  '0 0 * * 1-5'
jobs:
  pullrequestAttentionLabel:
    runs-on: ubuntu-latest
    steps:
    - name: Add an attention label to an open pull request
      uses: crazymanish/pullrequest-attention-label-action@master
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        ADD_LABEL: "need-review"
        AFTER_DAYS: 4
        SKIP_LABELS: "approved,wip"
        REMOVE_LABELS: "helpwanted,untriaged"
```

#### GitHub action workflow execution
<img src="https://user-images.githubusercontent.com/5364500/75099737-5fa83980-55c5-11ea-8b9d-3e4c8f0be0b9.jpg" width="540">


### License
The Dockerfile and associated scripts and documentation in this project are released under the [MIT License](LICENSE).
