# Parameters
$server = "Ams2wp-bwc20-3\DWH_PROD_TAB"
$database = "JiraApiCube"
$outputCsvPath = "output.csv"
"

# Connection string
$connString = 'Provider=MSOLAP;Data Source=Ams2wp-bwc20-3\DWH_PROD_TAB;Initial Catalog=JiraApiCube'

try {
    # Open connection
    $conn = New-Object -ComObject ADODB.Connection
    $conn.Open($connString)

    # DAX Query
$daxQuery = @"
EVALUATE
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

        # Export results to CSV (with UTF8 BOM for Excel compatibility)
       $results | Export-Csv -Path $outputCsvPath -NoTypeInformation -Encoding UTF8
        Write-Host "Exported results to CSV: $outputCsvPath"
        Write-Host " Total rows exported: $($results.Count)"
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





