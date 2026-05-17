Describe "Add-TeamToRepo" {
    BeforeAll {
        $script:TeamName   = "test-team"
        $script:Role       = "admin"
        $script:Owner      = "test-owner"
        $script:RepoName   = "test-repo"
        $script:Token      = "fake-token"
        $script:MockApiUrl = "http://127.0.0.1:3000"
        . "$PSScriptRoot/../action.ps1"
    }
	
    BeforeEach {
        $env:GITHUB_OUTPUT = New-TemporaryFile
        $env:MOCK_API = $script:MockApiUrl
    }
	
    AfterEach {
        if (Test-Path $env:GITHUB_OUTPUT) { Remove-Item $env:GITHUB_OUTPUT }
        Remove-Item Env:MOCK_API -ErrorAction SilentlyContinue
    }

	Context "Success Cases" {
	    It "unit: Add-TeamToRepo succeeds with HTTP 204" {
	        Mock Invoke-WebRequest {
	            [PSCustomObject]@{ StatusCode = 204; Content = '{}' }
	        }
	        Add-TeamToRepo -TeamName $TeamName -Role $Role -Owner $Owner -RepoName $RepoName -Token $Token
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=success"
	    }
	}

	Context "HTTP Failure Cases" {
	    It "unit: Add-TeamToRepo fails with HTTP 404" {
	        Mock Invoke-WebRequest {
	            [PSCustomObject]@{ StatusCode = 404; Content = '{"message": "Not Found"}' }
	        }
	        Add-TeamToRepo -TeamName $TeamName -Role $Role -Owner $Owner -RepoName $RepoName -Token $Token
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=failure"
	        $output | Should -Contain "error-message=Error: Failed to assign $Role role to $TeamName team. HTTP Status: 404"
	    }		
	}

	Context "Parameter Validation Failure Cases" {
		It "unit: Add-TeamToRepo fails with empty TeamName" {
	        Add-TeamToRepo -TeamName "" -Role $Role -Owner $Owner -RepoName $RepoName -Token $Token
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=failure"
	        $output | Should -Contain "error-message=Missing required parameters: team_slug, repo_name, role, owner, and token must be provided."
	    }
	
	    It "unit: Add-TeamToRepo fails with empty Role" {
	        Add-TeamToRepo -TeamName $TeamName -Role "" -Owner $Owner -RepoName $RepoName -Token $Token
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=failure"
	        $output | Should -Contain "error-message=Missing required parameters: team_slug, repo_name, role, owner, and token must be provided."
	    }
	
	    It "unit: Add-TeamToRepo fails with empty Owner" {
	        Add-TeamToRepo -TeamName $TeamName -Role $Role -Owner "" -RepoName $RepoName -Token $Token
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=failure"
	        $output | Should -Contain "error-message=Missing required parameters: team_slug, repo_name, role, owner, and token must be provided."
	    }
	
	    It "unit: Add-TeamToRepo with empty RepoName" {
	        Add-TeamToRepo -TeamName $TeamName -Role $Role -Owner $Owner -RepoName "" -Token $Token
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=failure"
	        $output | Should -Contain "error-message=Missing required parameters: team_slug, repo_name, role, owner, and token must be provided."
	    }
	
	    It "unit: Add-TeamToRepo fails with empty Token" {
	        Add-TeamToRepo -TeamName $TeamName -Role $Role -Owner $Owner -RepoName $RepoName -Token ""
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=failure"
	        $output | Should -Contain "error-message=Missing required parameters: team_slug, repo_name, role, owner, and token must be provided."
	    }	
	}

	Context "Exception Failure Cases" {
		It "unit: Add-TeamToRepo fails with exception" {
			Mock Invoke-WebRequest { throw "API Error" }
	
			try {
				Add-TeamToRepo -TeamName $TeamName -Role $Role -Owner $Owner -RepoName $RepoName -Token $Token
			} catch {}
	
			$output = Get-Content $env:GITHUB_OUTPUT
			$output | Should -Contain "result=failure"
			$output | Where-Object { $_ -match "^error-message=Error: Failed to assign $Role role to $TeamName team\. Exception:" } |
				Should -Not -BeNullOrEmpty
		}
	}
}
