# Parameters
$server = "Ams2wp-bwc20-3\DWH_PROD_TAB"
$database = "JiraApiCube"

# Connection string
$connString = "Provider=MSOLAP;Data Source=$server;Initial Catalog=$database;"

# Function to test connection
function Test-CubeConnection {
    param($connString)

    try {
        $testConn = New-Object -ComObject ADODB.Connection
        $testConn.ConnectionString = $connString
        $testConn.Open()
        Write-Host " Connection test successful."
        $testConn.Close()
        return $true
    } catch {
        Write-Host "Connection test failed: $($_.Exception.Message)"
        return $false
    }
}

# Test the connection first
if (-not (Test-CubeConnection -connString $connString)) {
    Write-Host "Aborting script because connection could not be established."
    exit 1
}

# If connection works, proceed with query
try {
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

    $results = @()
    if ($rs -and -not $rs.EOF) {
        $columns = @()
        for ($i = 0; $i -lt $rs.Fields.Count; $i++) {
            $columns += $rs.Fields.Item($i).Name
        }

        while (-not $rs.EOF) {
            $obj = @{}
            for ($i = 0; $i -lt $rs.Fields.Count; $i++) {
                $value = $rs.Fields.Item($i).Value
                $obj[$columns[$i]] = if ($null -eq $value) { "" } else { $value }
            }
            $results += [PSCustomObject]$obj
            $rs.MoveNext()
        }

        $json = $results | ConvertTo-Json -Depth 5
        $pythonExe = "python"
        $scriptPath = "./capacity_metric.py"
        $json | & $pythonExe $scriptPath
    } else {
        Write-Host "Query returned no rows or recordset is closed."
    }

    $rs.Close()
    $conn.Close()

} catch {
    Write-Host "Connection or query failed: $($_.Exception.Message)"
}










