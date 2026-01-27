function Add-TeamToRepo {
    param(
        [string]$TeamSlug,
        [string]$Role,
        [string]$Owner,
        [string]$RepoName,
        [string]$Token
    )

    # Validate required parameters
    if ([string]::IsNullOrEmpty($TeamSlug) -or
        [string]::IsNullOrEmpty($Role) -or
        [string]::IsNullOrEmpty($Owner) -or
        [string]::IsNullOrEmpty($RepoName) -or
        [string]::IsNullOrEmpty($Token)) {
        Write-Host "Error: Missing required parameters"
        Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=Missing required parameters: team_slug, repo_name, role, owner, and token must be provided."
        Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
        return
    }

    Write-Host "Assigning $Role role to team $TeamSlug for repo $Owner/$RepoName"

    # Use MOCK_API if set, otherwise default to GitHub API
    $apiBaseUrl = $env:MOCK_API
    if (-not $apiBaseUrl) { $apiBaseUrl = "https://api.github.com" }
    $uri = "$apiBaseUrl/orgs/$Owner/teams/$TeamSlug/repos/$Owner/$RepoName"

    $headers = @{
        Authorization  = "Bearer $Token"
        Accept         = "application/vnd.github.v3+json"
        "Content-Type" = "application/json"
        "User-Agent"   = "pwsh-action"
    }

    $jsonBody = @{
        permission = $Role
    } | ConvertTo-Json

    try {
        $response = Invoke-WebRequest -Uri $uri -Headers $headers -Method Put -Body $jsonBody

        Write-Host "Grant Team Access API Response Code for $TeamSlug team: $($response.StatusCode)"
        Write-Host $response.Content

        if ($response.StatusCode -eq 204) {
            Write-Host "Successfully assigned $Role role to team $TeamSlug"
            Add-Content -Path $env:GITHUB_OUTPUT -Value "result=success"
        } else {
            $errorMessage = ""
            try {
                $errorJson = $response.Content | ConvertFrom-Json
                $errorMessage = $errorJson.message
            } catch { $errorMessage = $response.Content }
            Write-Host "Warning: Failed to assign $Role role to $TeamSlug team: $errorMessage"
            Add-Content -Path $env:GITHUB_ENV -Value "Warning: Failed to assign $Role role to $TeamSlug team: $errorMessage"
            Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=$errorMessage"
            Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
        }
    } catch {
        $errorMessage = ""
        if ($_.Exception.Response -and $_.Exception.Response.GetResponseStream()) {
            $reader = New-Object System.IO.StreamReader $_.Exception.Response.GetResponseStream()
            $content = $reader.ReadToEnd()
            $reader.Close()
            try {
                $errorJson = $content | ConvertFrom-Json
                $errorMessage = $errorJson.message
            } catch { $errorMessage = $content }
        }
        Write-Host "Warning: Failed to assign $Role role to $TeamSlug team: $errorMessage"
        Add-Content -Path $env:GITHUB_ENV -Value "Warning: Failed to assign $Role role to $TeamSlug team: $errorMessage"
        Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=$errorMessage"
        Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
    }
}