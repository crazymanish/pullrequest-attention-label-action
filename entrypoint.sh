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

if [[ -z "$AFTER_DAYS" ]]; then
  echo "Setting the default AFTER_DAYS variable value."
  AFTER_DAYS=3
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

PULL_REQUESTS=$(echo "$OPEN_PULL_REQUESTS" | jq --raw-output '.[] | {number: .number, created_at: .created_at, labels: .labels} | @base64')

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

done
