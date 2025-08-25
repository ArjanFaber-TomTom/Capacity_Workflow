import json
import subprocess
from olap.xmla.xmla import XMLAProvider

# -----------------------------
# Parameters
# -----------------------------
server = "Ams2wp-bwc20-3"                # Host
catalog = "JiraApiCube"                  # Cube name
xmla_url = f"http://{server}/olap/msmdpump.dll"   # XMLA endpoint

# -----------------------------
# Function to test connection
# -----------------------------
def test_cube_connection(url, catalog):
    try:
        provider = XMLAProvider()
        conn = provider.connect(location=url, catalog=catalog)
        conn.Disconnect()
        print("✅ Connection test successful.")
        return True
    except Exception as e:
        print("❌ Connection test failed:", e)
        return False

# -----------------------------
# Test the connection first
# -----------------------------
if not test_cube_connection(xmla_url, catalog):
    print("Aborting script because connection could not be established.")
    exit(1)

# -----------------------------
# If connection works, proceed with query
# -----------------------------
try:
    provider = XMLAProvider()
    conn = provider.connect(location=xmla_url, catalog=catalog)
    print("✅ Connected to cube.")

    # DAX Query
    dax_query = """
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
    """

    # Execute query
    result = conn.Execute(dax_query)

    # -----------------------------
    # Convert result into rows
    # -----------------------------
    rows = []
    if "root" in result and "Axes" in result["root"]:
        # Depending on the XMLA response, you'd need to parse cells
        # Simplified example: show raw response
        print("⚠️ XMLA response returned. Needs parsing based on SSAS server.")
        print(result)
    else:
        # If result is already tabular
        rows = result.get("rows", [])
    
    # -----------------------------
    # Convert results to JSON
    # -----------------------------
    json_data = json.dumps(rows, indent=2, default=str)

    # -----------------------------
    # Call Python script with JSON
    # -----------------------------
    process = subprocess.Popen(
        ["python3", "./capacity_metric.py"],
        stdin=subprocess.PIPE,
        text=True
    )
    process.communicate(input=json_data)

    conn.Disconnect()

except Exception as e:
    print("❌ Connection or query failed:", e)
