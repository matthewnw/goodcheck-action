#!/bin/bash
set -e

count=0
existingComments=$(gh api repos/$GITHUB_REPOSITORY/pulls/${{ github.event.pull_request.number }}/comments)

while IFS= read -r obj; do
  ruleID="$(jq -r '.rule_id' <<< "$obj")"
  message="$(jq -r '.message' <<< "$obj")"
  filePath="$(jq -r '.path' <<< $obj)"
  startLine="$(jq -r '.location.start_line // empty' <<< "$obj")"
  endLine="$(jq -r '.location.end_line // empty' <<< "$obj")"
  severity="$(jq -r '.severity' <<< "$obj")"

  alert=""
  if [ "$severity" = "blocking" ]; then
    alert="
<sub>:no_entry:_This is blocking and should be fixed before continuing._:no_entry:</sub>"
  fi

  if [ -z "$startLine" ] && [ -z "$endLine" ]; then
    wasModified=true
  else
    wasModified="$(jq -r \
      --arg FILE "$filePath" \
      --argjson STARTLINE "$startLine" \
      '.[$FILE]|any(. == $STARTLINE)' <<< "$CHANGED")"
  fi

  echo "."
  echo "."
  if [ "$wasModified" = true ]; then
    echo -e "\033[31;1;4m|------------------------------------------ NEW ISSUE ------------------------------------------\033[0m"
  fi
  echo "|-----------------------------------------------------------------------------------------------"
  echo "|---- $filePath:$startLine"
  echo "|-----------------------------------------------------------------------------------------------"
  echo -e "Rule: \033[0;36m$ruleID\033[0m"
  if [ "$wasModified" = true ]; then
    echo "Line was modified in this PR: Yes"
  else
    echo "Line was modified in this PR: No"
  fi
  echo "$message"
  echo -e "\n"

  found=$(jq \
      --arg FILE "$filePath" \
      --arg RULEMATCH "<sub>rule:${ruleID}</sub>" \
      '.[] | select(.path==$FILE and .user.login=="github-actions[bot]") and select(.body | endswith($RULEMATCH))' <<< $existingComments)

  if [ "$wasModified" = true ]; then
    count=$((count+1)) # only count errors for modified lines

    if [ -z "$found" ]; then
        echo -e "\033[0;35mNo existing comment found, adding to PR...\033[0m"
        comment="$message $alert
  <sub>rule:${ruleID}</sub>"

        if [ -z "$startLine" ] && [ -z "$endLine" ]; then
          gh api \
            --method POST \
            -H "Accept: application/vnd.github+json" \
            repos/$GITHUB_REPOSITORY/pulls/${{ github.event.pull_request.number }}/comments \
            -f commit_id="${{ github.event.pull_request.head.sha }}" \
            -f body="$comment" \
            -f path="$filePath" \
            -f subject_type="file" \
          1> /dev/null || true
        else
          gh api \
            --method POST \
              -H "Accept: application/vnd.github+json" \
              repos/$GITHUB_REPOSITORY/pulls/${{ github.event.pull_request.number }}/comments \
              -f commit_id="${{ github.event.pull_request.head.sha }}" \
              -f body="$comment" \
              -f path="$filePath" \
              -f start_side='RIGHT' \
              -F line="$endLine" \
              -f side="RIGHT" \
          1> /dev/null || true
        fi
    else
        echo -e "\033[0;35mComment already added, skipping...\033[0m"
    fi
  else
    echo -e "\033[0;33mLine was not modified in this PR, skipping comment...\033[0m"
  fi
done < <(jq -c '.[]' <<< ${{ steps.goodcheck-analysis.outputs.errors }})

if [[ "$count" -gt 0 ]]; then
  echo "----"
  echo "Applying Auto Review label to PR..."
  gh api \
      --method POST \
      -H "Accept: application/vnd.github+json" \
      repos/$GITHUB_REPOSITORY/issues/${{ github.event.pull_request.number }}/labels \
      -f "labels[]=Auto Reviewed" \
  1> /dev/null || true

  exit 1
fi