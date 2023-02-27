#!/bin/bash
set -e

if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "Set the GITHUB_TOKEN env variable."
  exit 1
fi

if [[ -z "$ADD_LABEL" ]]; then
  echo "Set the ADD_LABEL env variable."
  exit 1
fi

if [[ -z "$SKIP_LABELS" ]]; then
  echo "Setting the default SKIP_LABELS variable value."
  SKIP_LABELS="work-in-progress,wip"
fi

if [[ -z "$REMOVE_LABEL" ]]; then
  echo "Set the REMOVE_LABEL env variable."
  exit 1
fi

if [[ -z "$AFTER_DAYS" ]]; then
  echo "Setting the default AFTER_DAYS variable value."
  AFTER_DAYS=3
fi

if [[ -z "$SKIP_DRAFTS" ]]; then
  echo "Setting the default SKIP_DRAFTS variable value."
  SKIP_DRAFTS=false
fi

URI="https://api.github.com"
API_HEADER="Accept: application/vnd.github.v3+json"
AUTH_HEADER="Authorization: token $GITHUB_TOKEN"

echo "Fetching, Open pull requests"
OPEN_PULL_REQUESTS=$(
  curl -XGET -fsSL \
    -H "$AUTH_HEADER" \
    -H "$API_HEADER" \
    "$URI/repos/$GITHUB_REPOSITORY/issues?state=open"
  )

PULL_REQUESTS=$(echo "$OPEN_PULL_REQUESTS" | jq --raw-output '.[] | {number: .number, created_at: .created_at, labels: .labels, draft: .draft} | @base64')

for PULL_REQUEST in $PULL_REQUESTS; do
  PULL_REQUEST_INFO="$(echo "$PULL_REQUEST" | base64 -d)"

  echo "Validating, Pull request INFO: $PULL_REQUEST_INFO"

  ADD_LABEL_NAME_EXIST=$(echo "$PULL_REQUEST_INFO" | jq --raw-output --arg ADD_LABEL "$ADD_LABEL" '.labels | .[] | select(.name==$ADD_LABEL)')

  if [[ -z "$ADD_LABEL_NAME_EXIST" ]]; then
    echo "Proceeding, This pull request doesn't have review attention LABEL: $ADD_LABEL"
  else
    echo "Ignoring, This pull request already have review attention LABEL: $ADD_LABEL"
    continue
  fi

  IS_SKIP_LABEL_NAME_EXIST=false

  for SKIP_LABEL in $(echo $SKIP_LABELS | sed "s/,/ /g"); do
    SKIP_LABEL_NAME_EXIST=$(echo "$PULL_REQUEST_INFO" | jq --raw-output --arg SKIP_LABEL "$SKIP_LABEL" '.labels | .[] | select(.name==$SKIP_LABEL)')

    if [[ -z "$SKIP_LABEL_NAME_EXIST" ]]; then
      echo "Proceeding, This pull request doesn't have an skip LABEL: $SKIP_LABEL"
    else
      echo "Ignoring, This pull request have an skip LABEL: $SKIP_LABEL"
      IS_SKIP_LABEL_NAME_EXIST=true
      break
    fi
  done

  if [[ "$IS_SKIP_LABEL_NAME_EXIST" == "true" ]]; then
    continue
  fi

  if [[ -n "$REMOVE_LABEL" ]]; then
    REMOVE_LABEL_NAME_EXIST=$(echo "$PULL_REQUEST_INFO" | jq --raw-output --arg REMOVE_LABEL "$REMOVE_LABEL" '.labels | .[] | select(.name==$REMOVE_LABEL)')

    if [[ -n "$REMOVE_LABEL_NAME_EXIST" ]]; then
      echo "Removing, Pull request label: $REMOVE_LABEL, Pull request NUMBER: $PULL_REQUEST_NUMBER"
      curl -sSL \
        -H "$AUTH_HEADER" \
        -H "$API_HEADER" \
        -X DELETE \
        "$URI/repos/$GITHUB_REPOSITORY/issues/$PULL_REQUEST_NUMBER/labels/$REMOVE_LABEL"
    else
      echo "Proceeding, This pull request doesn't have the label to remove: $REMOVE_LABEL"

  if [[ $SKIP_DRAFTS != "false" ]]; then
    IS_A_DRAFT=$(echo "$PULL_REQUEST_INFO" | jq --raw-output '.draft')
    if [[ $IS_A_DRAFT == "true" ]]; then
      echo "Ignoring, this pull request because it's a DRAFT"
      continue

    fi
  fi

  CREATED_AT=$(echo "$PULL_REQUEST_INFO" | jq --raw-output '.created_at')
  CREATED_AT_EPOCH=$(date -d $CREATED_AT +%s)
  CURRENT_EPOCH=$(date +%s)
  STALE_TIME_INTERVAL=$(($AFTER_DAYS * 24 * 60 * 60))

  if [[ $(($CURRENT_EPOCH - $CREATED_AT_EPOCH)) -ge $STALE_TIME_INTERVAL ]]; then
    echo "Proceeding, This pull request is CREATED_AT: $CREATED_AT, is greater than $AFTER_DAYS DAYS."
  else
    echo "Ignoring, This pull request is CREATED_AT: $CREATED_AT, is less than $AFTER_DAYS DAYS."
    continue
  fi

  PULL_REQUEST_NUMBER=$(echo "$PULL_REQUEST_INFO" | jq --raw-output '.number')
  echo "Adding, Pull request review attention LABEL: $ADD_LABEL, pull request NUMBER: $PULL_REQUEST_NUMBER"

  curl -sSL \
    -H "$AUTH_HEADER" \
    -H "$API_HEADER" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "{\"labels\":[\"$ADD_LABEL\"]}" \
    "$URI/repos/$GITHUB_REPOSITORY/issues/$PULL_REQUEST_NUMBER/labels"

echo "Fetching, Open issues"
OPEN_ISSUES=$(
  curl -XGET -fsSL \
    -H "$AUTH_HEADER" \
    -H "$API_HEADER" \
    "$URI/repos/$GITHUB_REPOSITORY/issues?state=open"
  )

ISSUES=$(echo "$OPEN_ISSUES" | jq --raw-output '.[] | {number: .number, created_at: .created_at, labels: .labels} | @base64')

for ISSUE in $ISSUES; do
  ISSUE_INFO="$(echo "$ISSUE" | base64 -d)"

  echo "Validating issue INFO: $ISSUE_INFO"

  ADD_LABEL_NAME_EXIST=$(echo "$ISSUE_INFO" | jq --raw-output --arg ADD_LABEL "$ADD_LABEL" '.labels | .[] | select(.name==$ADD_LABEL)')

  if [[ -z "$ADD_LABEL_NAME_EXIST" ]]; then
    echo "Proceeding, This issue doesn't have review attention LABEL: $ADD_LABEL"
  else
    echo "Ignoring, This issue already have review attention LABEL: $ADD_LABEL"
    continue
  fi

  IS_SKIP_LABEL_NAME_EXIST=false

  for SKIP_LABEL in $(echo $SKIP_LABELS | sed "s/,/ /g"); do
    SKIP_LABEL_NAME_EXIST=$(echo "$ISSUE_INFO" | jq --raw-output --arg SKIP_LABEL "$SKIP_LABEL" '.labels | .[] | select(.name==$SKIP_LABEL)')

    if [[ -z "$SKIP_LABEL_NAME_EXIST" ]]; then
      echo "Proceeding, This issue doesn't have an skip LABEL: $SKIP_LABEL"
    else
      echo "Ignoring, This issue have an skip LABEL: $SKIP_LABEL"
      IS_SKIP_LABEL_NAME_EXIST=true
      break
    fi
  done

  if [[ "$IS_SKIP_LABEL_NAME_EXIST" == "true" ]]; then
    continue
  fi

  if [[ -n "$REMOVE_LABEL" ]]; then
    REMOVE_LABEL_NAME_EXIST=$(echo "$ISSUE_INFO" | jq --raw-output --arg REMOVE_LABEL "$REMOVE_LABEL" '.labels | .[] | select(.name==$REMOVE_LABEL)')

    if [[ -n "$REMOVE_LABEL_NAME_EXIST" ]]; then
      echo "Removing, Issue label: $REMOVE_LABEL, Issue NUMBER: "
      curl -sSL \
        -H "$AUTH_HEADER" \
        -H "$API_HEADER" \
        -X DELETE \
        "$URI/repos/$GITHUB_REPOSITORY/issues/$ISSUE_NUMBER/labels/$REMOVE_LABEL"
    else
      echo "Proceeding, This Issue  doesn't have the label to remove: $REMOVE_LABEL"
    fi
  fi

  CREATED_AT=$(echo "$ISSUE_INFO" | jq --raw-output '.created_at')
  CREATED_AT_EPOCH=$(date -d $CREATED_AT +%s)
  CURRENT_EPOCH=$(date +%s)
  STALE_TIME_INTERVAL=$(($AFTER_DAYS * 24 * 60 * 60))

  if [[ $(($CURRENT_EPOCH - $CREATED_AT_EPOCH)) -ge $STALE_TIME_INTERVAL ]]; then
    echo "Proceeding, This issue is CREATED_AT: $CREATED_AT, is greater than $AFTER_DAYS DAYS."
  else
    echo "Ignoring, This issue is CREATED_AT: $CREATED_AT, is less than $

  ISSUE_NUMBER=$(echo "$ISSUE_INFO" | jq --raw-output '.number')
  echo "Adding, Issue review attention LABEL: $ADD_LABEL, issue NUMBER: $ISSUE_NUMBER"

  curl -sSL \
    -H "$AUTH_HEADER" \
    -H "$API_HEADER" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "{\"labels\":[\"$ADD_LABEL\"]}" \
    "$URI/repos/$GITHUB_REPOSITORY/issues/$ISSUE_NUMBER/labels"

done
