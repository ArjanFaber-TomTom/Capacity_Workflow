# JIRA credentials from env variables (GitHub secrets)
$jiraEmail = "arjan.faber@tomtom.com"
$jiraToken = "ATATT3xFfGF0iwS-8N8B_PIwvvi7KMztGPmzlav8ECiL9NXCiYI7sULzfgTI1-yaI_Al95jrzEAqJs0tU59l2SMEU-z2Fo8dxMRYodkP7LoDMWWS-LplvdtgzzCsXtvj0-oK-J-bytrhzV3yWD8Qy3GKf3_uh4gOo9AGxe1MP62T6znTPkpiCoo=C6CB4564"
$jiraUrl   = "https://tomtom.atlassian.net"

# JQL equivalent of your DAX filter
$jql = 'project = BATTI AND created > "2024-12-31"'

# Fields to fetch
$fields = @(
    "summary",
    "assignee",
    "reporter",
    "priority",
    "status",
    "issuetype",
    "resolution",
    "duedate",
    "created",
    "updated",
    "components",
    "customfield_XXXXX" # First Response Time
) -join ","

# REST request
$searchUrl = "$jiraUrl/rest/api/3/search?jql=$([uri]::EscapeDataString($jql))&maxResults=5000&fields=$fields"

$bytes = [System.Text.Encoding]::ASCII.GetBytes("$jiraEmail:$jiraToken")
$encodedCreds = [Convert]::ToBase64String($bytes)
$headers = @{ Authorization = "Basic $encodedCreds" }

Write-Host "Calling Jira API..."

$response = Invoke-RestMethod -Uri $searchUrl -Headers $headers -Method Get

$results = @()

foreach ($issue in $response.issues) {
    $f = $issue.fields

    $obj = [PSCustomObject]@{
        "PKEY"                        = $issue.key
        "Summary"                    = $f.summary
        "Assignee Key"               = $f.assignee.accountId
        "Date Updated"               = $f.updated
        "Date Created"               = $f.created
        "Date Due"                   = $f.duedate
        "Issue URL"                  = "$jiraUrl/browse/$($issue.key)"
        "Priority"                   = $f.priority.name
        "Reporter Key"               = $f.reporter.accountId
        "Issue Status"               = $f.status.name
        "Type"                       = $f.issuetype.name
        "Resolution"                 = $f.resolution.name
        "First Response Time (Hours)"= $f.customfield_XXXXX
        "Component Key"              = $f.components[0].id
        "Status Name"                = $f.status.name
    }

    $results += $obj
}

# Convert to JSON
$json = $results | ConvertTo-Json -Depth 5

# Pipe JSON to Python 
$pythonExe = "python"
$scriptPath = "./capacity_metric.py"

Write-Host "Sending JSON to Python script..."
$json | & $pythonExe $scriptPath











