#!/usr/bin/env bats

# Load the Bash script containing the grant_team_access_to_repo function
load ../action.sh

# Mock the curl command to simulate API responses
mock_curl() {
  local http_code=$1
  local response_file=$2
  local output_file="team_response.json"

  # Copy the mock response to the specified output file to mimic curl -o team_response.json
  cp "$response_file" "$output_file"
  # Output only the HTTP status code to mimic curl -w "%{http_code}"
  echo "$http_code"
}

# Mock jq command to extract values from JSON
mock_jq() {
  local key=$1
  local file=$2
  if [ "$key" = ".message" ]; then
    # Extract the value of the "message" field, handling whitespace and newlines
    local value=$(cat "$file" | tr -d '\n' | sed -E 's/.*"message"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/')
    if [ -n "$value" ]; then
      echo "$value"
    else
      echo "null"
    fi
  else
    echo ""
  fi
}

# Setup function to run before each test
setup() {
  export GITHUB_OUTPUT=$(mktemp)
  export GITHUB_ENV=$(mktemp)
}

# Teardown function to clean up after each test
teardown() {
  rm -f team_response.json "$GITHUB_OUTPUT" "$GITHUB_ENV" mock_response.json
}

@test "unit: grant_team_access_to_repo succeeds with HTTP 204" {
  echo '{}' > mock_response.json
  curl() { mock_curl "204" mock_response.json; }
  export -f curl

  run grant_team_access_to_repo "test-team" "admin" "test-owner" "test-repo" "fake-token"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=success" ]
}

@test "unit: grant_team_access_to_repo fails with HTTP 403" {
  echo '{"message": "Forbidden"}' > mock_response.json
  curl() { mock_curl "403" mock_response.json; }
  jq() { mock_jq ".message" mock_response.json; }
  export -f curl
  export -f jq

  run grant_team_access_to_repo "test-team" "admin" "test-owner" "test-repo" "fake-token"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" == "error-message=Forbidden" ]
  [ "$(grep 'Warning: Failed to assign admin role to team test-team: Forbidden' "$GITHUB_ENV")" ]
}

@test "unit: grant_team_access_to_repo fails with HTTP 404" {
  echo '{"message": "Not Found"}' > mock_response.json
  curl() { mock_curl "404" mock_response.json; }
  jq() { mock_jq ".message" mock_response.json; }
  export -f curl
  export -f jq

  run grant_team_access_to_repo "test-team" "admin" "test-owner" "test-repo" "fake-token"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" == "error-message=Not Found" ]
  [ "$(grep 'Warning: Failed to assign admin role to team test-team: Not Found' "$GITHUB_ENV")" ]
}

@test "unit: grant_team_access_to_repo fails with empty team_slug" {
  run grant_team_access_to_repo "" "admin" "test-owner" "test-repo" "fake-token"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" == "error-message=Missing required parameters: team_slug, repo_name, role, owner, and token must be provided." ]
}

@test "unit: grant_team_access_to_repo fails with empty role" {
  run grant_team_access_to_repo "test-team" "" "test-owner" "test-repo" "fake-token"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" == "error-message=Missing required parameters: team_slug, repo_name, role, owner, and token must be provided." ]
}

@test "unit: grant_team_access_to_repo fails with empty owner" {
  run grant_team_access_to_repo "test-team" "admin" "" "test-repo" "fake-token"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" == "error-message=Missing required parameters: team_slug, repo_name, role, owner, and token must be provided." ]
}

@test "unit: grant_team_access_to_repo fails with empty repo_name" {
  run grant_team_access_to_repo "test-team" "admin" "test-owner" "" "fake-token"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" == "error-message=Missing required parameters: team_slug, repo_name, role, owner, and token must be provided." ]
}

@test "unit: grant_team_access_to_repo fails with empty token" {
  run grant_team_access_to_repo "test-team" "admin" "test-owner" "test-repo" ""

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" == "error-message=Missing required parameters: team_slug, repo_name, role, owner, and token must be provided." ]
}
