#!/bin/bash

# Function to grant a team access to a repository with a specified role
grant_team_access_to_repo() {
  local team_slug=$1
  local role=$2
  local owner=$3
  local repo_name=$4
  local token=$5

  # Validate required inputs
  if [ -z "$team_slug" ] || [ -z "$repo_name" ] || [ -z "$owner" ] || [ -z "$token" ] || [ -z "$role" ]; then
    echo "Error: Missing required parameters"
    echo "error-message=Missing required parameters: team_slug, repo_name, role, owner, and token must be provided." >> "$GITHUB_OUTPUT"
    echo "result=failure" >> "$GITHUB_OUTPUT"
    return
  fi

  echo "Assigning $role role to team $team_slug for repo $owner/$repo_name"

  # Use MOCK_API if set, otherwise default to GitHub API
  local api_base_url="${MOCK_API:-https://api.github.com}"
  
  RESPONSE=$(curl -s -o team_response.json -w "%{http_code}" \
    -X PUT \
    -H "Authorization: Bearer $token" \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Content-Type: application/json" \
    "$api_base_url/orgs/$owner/teams/$team_slug/repos/$owner/$repo_name" \
    -d "{\"permission\": \"$role\"}")
    
  echo "Grant Team Access API Response Code for $team_slug: $RESPONSE"
  cat team_response.json
  
  if [ "$RESPONSE" -ne 204 ]; then
    ERROR_MESSAGE=$(jq -r .message team_response.json)
    echo "Warning: Failed to assign $role role to team $team_slug: $ERROR_MESSAGE" >> $GITHUB_ENV
    echo "error-message=$ERROR_MESSAGE" >> $GITHUB_OUTPUT
    echo "result=failure" >> $GITHUB_OUTPUT
  else
    echo "Successfully assigned $role role to team $team_slug"
    echo "result=success" >> $GITHUB_OUTPUT
  fi
}
