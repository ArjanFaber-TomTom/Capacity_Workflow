# Parameters
$server = "Ams2wp-bwc20-3\DWH_PROD_TAB"
$database = "JiraApiCube"

# Connection string
$connString = "Provider=Provider=MSOLAP.7;Data Source=$server;Initial Catalog=$database;"

try {
    # Open connection
    $conn = New-Object -ComObject ADODB.Connection
    $conn.ConnectionString = $connString
    $conn.Open()
    Write-Host "Connected to cube."

    # DAX Query
$daxQuery = @"
EVALUATE
VAR FilteredIssues =
    FILTER (
        'Issue',
        SEARCH("BATTI", 'Issue'[PKEY], 1, 0) >= 1
            && 'Issue'[Date Created] > DATE(2024, 12, 31)
    )
RETURN
SELECTCOLUMNS (
    FilteredIssues,
    "PKEY", 'Issue'[PKEY],
    "Summary", 'Issue'[issue Summary],
    "Assignee Key", 'Issue'[Assignee Key],
    "Date Updated", 'Issue'[Date Updated],
    "Date Created", 'Issue'[Date Created],
    "Date Due", 'Issue'[Date Due],
    "Issue URL", 'Issue'[Issue URL],
    "Priority", 'Issue'[PRIORITY],
    "Reporter Key", 'Issue'[Reporter Key],
    "Issue Status", 'Issue'[ISSUESTATUS],
    "Type", 'Issue'[ISSUETYPE],
    "Resolution", 'Issue'[RESOLUTION],
    "First Response Time (Hours)", 'Issue'[First Response Time(in Hours)],
    "Component Key", 'Issue'[First Component Key],
    "Status Name", RELATED('Status'[Status Name])
)

"@

    # Prepare command
    $cmd = New-Object -ComObject ADODB.Command
    $cmd.ActiveConnection = $conn
    $cmd.CommandText = $daxQuery
    $cmd.CommandType = 1  # adCmdText
    $cmd.CommandTimeout = 120

    # Execute query
    $rs = $cmd.Execute()

    # Create an array to hold output objects
    $results = @()

    if ($rs -and -not $rs.EOF) {
        # Get column names
        $columns = @()
        for ($i = 0; $i -lt $rs.Fields.Count; $i++) {
            $columns += $rs.Fields.Item($i).Name
        }

        # Read rows into objects
        while (-not $rs.EOF) {
            $obj = @{}
            for ($i = 0; $i -lt $rs.Fields.Count; $i++) {
                $value = $rs.Fields.Item($i).Value
                if ($null -eq $value) {
                    $obj[$columns[$i]] = ""
                }
                else {
                    $obj[$columns[$i]] = $value
                }
            }
            $results += [PSCustomObject]$obj
            $rs.MoveNext()
        }

        # Convert to JSON and send to Python
        $json = $results | ConvertTo-Json -Depth 5
    $pythonExe = "python"  # or full path like "C:\Python39\python.exe"
    $scriptPath = "./capacity_metric.py"

# Call Python and pipe JSON
$json | & $pythonExe $scriptPath
    }
    else {
        Write-Host " Query returned no rows or recordset is closed."
    }

    # Clean up
    $rs.Close()
    $conn.Close()

} catch {
    Write-Host "Connection or query failed: $($_.Exception.Message)"
}











