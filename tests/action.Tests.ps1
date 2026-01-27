Describe "Add-TeamToRepo" {
    BeforeAll {
        $script:TeamSlug   = "test-team"
        $script:Role       = "admin"
        $script:Owner      = "test-owner"
        $script:RepoName   = "test-repo"
        $script:Token      = "fake-token"
        $script:MockApiUrl = "http://127.0.0.1:3000"
        . "$PSScriptRoot/../action.ps1"
    }
    BeforeEach {
        $env:GITHUB_OUTPUT = "$PSScriptRoot/github_output.temp"
        $env:GITHUB_ENV    = "$PSScriptRoot/github_env.temp"
        if (Test-Path $env:GITHUB_OUTPUT) { Remove-Item $env:GITHUB_OUTPUT }
        if (Test-Path $env:GITHUB_ENV) { Remove-Item $env:GITHUB_ENV }
        $env:MOCK_API = $script:MockApiUrl
    }
    AfterEach {
        if (Test-Path $env:GITHUB_OUTPUT) { Remove-Item $env:GITHUB_OUTPUT }
        if (Test-Path $env:GITHUB_ENV) { Remove-Item $env:GITHUB_ENV }
        Remove-Variable -Name MOCK_API -Scope Global -ErrorAction SilentlyContinue
    }

    It "succeeds with HTTP 204" {
        Mock Invoke-WebRequest {
            [PSCustomObject]@{ StatusCode = 204; Content = '{}' }
        }
        Add-TeamToRepo -TeamSlug $TeamSlug -Role $Role -Owner $Owner -RepoName $RepoName -Token $Token
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=success"
    }

    It "fails with HTTP 403" {
        Mock Invoke-WebRequest {
            [PSCustomObject]@{ StatusCode = 403; Content = '{"message": "Forbidden"}' }
        }
        Add-TeamToRepo -TeamSlug $TeamSlug -Role $Role -Owner $Owner -RepoName $RepoName -Token $Token
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Forbidden"
        $envWarn = Get-Content $env:GITHUB_ENV
        $envWarn | Should -Contain "Warning: Failed to assign admin role to team test-team: Forbidden"
    }

    It "fails with HTTP 404" {
        Mock Invoke-WebRequest {
            [PSCustomObject]@{ StatusCode = 404; Content = '{"message": "Not Found"}' }
        }
        Add-TeamToRepo -TeamSlug $TeamSlug -Role $Role -Owner $Owner -RepoName $RepoName -Token $Token
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Not Found"
        $envWarn = Get-Content $env:GITHUB_ENV
        $envWarn | Should -Contain "Warning: Failed to assign admin role to team test-team: Not Found"
    }

    It "fails with empty team_slug" {
        Add-TeamToRepo -TeamSlug "" -Role $Role -Owner $Owner -RepoName $RepoName -Token $Token
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Missing required parameters: team_slug, repo_name, role, owner, and token must be provided."
    }

    It "fails with empty role" {
        Add-TeamToRepo -TeamSlug $TeamSlug -Role "" -Owner $Owner -RepoName $RepoName -Token $Token
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Missing required parameters: team_slug, repo_name, role, owner, and token must be provided."
    }

    It "fails with empty owner" {
        Add-TeamToRepo -TeamSlug $TeamSlug -Role $Role -Owner "" -RepoName $RepoName -Token $Token
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Missing required parameters: team_slug, repo_name, role, owner, and token must be provided."
    }

    It "with empty repo_name" {
        Add-TeamToRepo -TeamSlug $TeamSlug -Role $Role -Owner $Owner -RepoName "" -Token $Token
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Missing required parameters: team_slug, repo_name, role, owner, and token must be provided."
    }

    It "fails with empty token" {
        Add-TeamToRepo -TeamSlug $TeamSlug -Role $Role -Owner $Owner -RepoName $RepoName -Token ""
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Missing required parameters: team_slug, repo_name, role, owner, and token must be provided."
    }
}