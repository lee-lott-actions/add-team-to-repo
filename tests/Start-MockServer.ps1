param(
    [int]$Port = 3000
)

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:$Port/")
$listener.Start()

Write-Host "Mock server listening on http://127.0.0.1:$Port..." -ForegroundColor Green

function GetJsonBody($request) {
    $reader = New-Object System.IO.StreamReader($request.InputStream)
    $body = $reader.ReadToEnd()
    $reader.Close()
    if ($body) {
        try { return $body | ConvertFrom-Json } catch { return $null }
    } else {
        return $null
    }
}

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $path = $request.Url.LocalPath
        $method = $request.HttpMethod

        Write-Host "Mock intercepted: $method $path" -ForegroundColor Cyan

        $responseJson = $null
        $statusCode = 200

        # HealthCheck endpoint: GET /HealthCheck
        if ($method -eq "GET" -and $path -eq "/HealthCheck") {
            $statusCode = 200
            $responseJson = @{ status = "ok" } | ConvertTo-Json
        }
        # PUT /orgs/:owner/teams/:team_slug/repos/:owner/:repo_name
        elseif ($method -eq "PUT" -and $path -match '^/orgs/([^/]+)/teams/([^/]+)/repos/([^/]+)/([^/]+)$') {
            $ownerPath      = $Matches[1]
            $teamSlug       = $Matches[2]
            $ownerRepo      = $Matches[3]
            $repoName       = $Matches[4]
            $bodyObj = GetJsonBody $request

            Write-Host "Request body: $(if ($bodyObj) { $bodyObj | ConvertTo-Json -Compress } else { '[null]' })"
            Write-Host "Request headers: $($request.Headers | Out-String)"

            # Validate 'permission' field
            if (-not $bodyObj.permission -or ($bodyObj.permission -isnot [string]) -or [string]::IsNullOrEmpty($bodyObj.permission)) {
                $statusCode = 400
                $responseJson = @{ message = "Invalid request: permission must be a non-empty string" } | ConvertTo-Json
            }
            elseif ($ownerPath -eq "test-owner" -and $teamSlug -eq "test-team" -and $repoName -eq "test-repo") {
                # Simulate successful response (HTTP 204 No Content)
                $statusCode = 204
                $responseJson = $null
            }
            else {
                $statusCode = 404
                $responseJson = @{ message = "Not Found" } | ConvertTo-Json
            }
        }
        else {
            $statusCode = 404
            $responseJson = @{ message = "Not Found" } | ConvertTo-Json
        }

        # Send response
        $response.StatusCode = $statusCode
        if ($statusCode -eq 204) {
            $response.ContentLength64 = 0
        } else {
            $response.ContentType = "application/json"
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseJson)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        $response.Close()
    }
}
finally {
    $listener.Stop()
    $listener.Close()
    Write-Host "Mock server stopped." -ForegroundColor Yellow
}