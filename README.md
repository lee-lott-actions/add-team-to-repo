# Grant Team Access GitHub Action

This GitHub Action grants a specified team access to a repository with a given role (e.g., pull, push, admin, maintain, triage) using the GitHub API.

## Features
- Assigns a team to a repository with a specified permission role.
- Provides outputs for success/failure status and error messages.
- Uses `jq` for parsing API responses.
- Handles errors gracefully with detailed logging.

## Inputs
| Name | Description | Required |
|------|-------------|----------|
| `team-name` | The slug of the team to grant access | Yes |
| `role` | The role to assign (e.g., pull, push, admin, maintain, triage) | Yes |
| `owner` | The organization or user that owns the repository | Yes |
| `repo-name` | The name of the repository | Yes |
| `token` | GitHub token with permissions to manage team access | Yes |

## Outputs
| Name | Description |
|------|-------------|
| `result` | Result of the team access operation ("success" or "failure") |
| `error-message` | Error message if the team access operation fails |

## Usage
To use this action, create a workflow file in your repository (e.g., `.github/workflows/grant-access.yml`) and reference the action. Ensure the `github-token` has the necessary permissions (typically `repo` and `admin:org` scopes).

### Example Workflow
```yaml
name: Grant Team Access
on:
  workflow_dispatch:
    inputs:
      team-name:
        description: 'Team slug to grant access'
        required: true
      role:
        description: 'Role to assign (e.g., admin, maintain)'
        required: true
      repo-name:
        description: 'Repository name'
        required: true

jobs:
  grant-access:
    runs-on: ubuntu-latest
    steps:
      - name: Grant Team Access
        uses: lee-lott/add-team-to-repo@v1.0.0
        with:
          team-name: ${{ github.event.inputs.team-name }}
          role: ${{ github.event.inputs.role }}
          owner: ${{ github.repository_owner }}
          repo-name: ${{ github.event.inputs.repo-name }}
          token: ${{ secrets.GITHUB_TOKEN }}
      - name: Check Result
        run: |
          echo "Result: ${{ steps.grant-access.outputs.result }}"
          if [ "${{ steps.grant-access.outputs.result }}" == "failure" ]; then
            echo "Error: ${{ steps.grant-access.outputs.error-message }}"
            exit 1
          fi
