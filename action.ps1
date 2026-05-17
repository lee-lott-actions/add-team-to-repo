function Add-TeamToRepo {
    param(
        [string]$TeamName,
        [string]$Role,
        [string]$Owner,
        [string]$RepoName,
        [string]$Token
    )

    # Validate required parameters
    if ([string]::IsNullOrEmpty($TeamName) -or
        [string]::IsNullOrEmpty($Role) -or
        [string]::IsNullOrEmpty($Owner) -or
        [string]::IsNullOrEmpty($RepoName) -or
        [string]::IsNullOrEmpty($Token)) {
        Write-Host "Error: Missing required parameters"
        Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=Missing required parameters: team_slug, repo_name, role, owner, and token must be provided."
        Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
        return
    }   

    # Use MOCK_API if set, otherwise default to GitHub API
    $apiBaseUrl = $env:MOCK_API
    if (-not $apiBaseUrl) { $apiBaseUrl = "https://api.github.com" }
    $uri = "$apiBaseUrl/orgs/$Owner/teams/$TeamName/repos/$Owner/$RepoName"

    $headers = @{
        Authorization = "Bearer $Token"
        Accept = "application/vnd.github.v3+json"
		"X-GitHub-Api-Version" = "2026-03-10"
        "Content-Type" = "application/json"
    }

    $body = @{
        permission = $Role
    } | ConvertTo-Json

    try {
		Write-Host "Assigning $Role role to team $TeamName for repo $Owner/$RepoName"
        $response = Invoke-WebRequest -Uri $uri -Headers $headers -Method Put -Body $body -SkipHttpErrorCheck

        if ($response.StatusCode -eq 204) {
            Write-Host "Successfully assigned $Role role to team $TeamName"
            Add-Content -Path $env:GITHUB_OUTPUT -Value "result=success"
        } else {
			$errorMsg = "Error: Failed to assign $Role role to $TeamName team. HTTP Status: $($response.StatusCode)" 
			Write-Host $errorMsg
            Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
			Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=$errorMsg"
        }
    } catch {		
		$errorMsg = "Error: Failed to assign $Role role to $TeamName team. Exception: $($_.Exception.Message)"
		Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
		Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=$errorMsg"
		Write-Host $errorMsg
    }
}
