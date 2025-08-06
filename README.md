# Capacity_Workflow
Implementing an automated workflow for storing capacity metric (BATTI projects)


# Scripts_Git — Jira Cube Extraction and Capacity Metric

This folder contains scripts to:
1. **Extract data** from a Microsoft Analysis Services (SSAS) cube using a **PowerShell script**
2. **Compute capacity metrics** using a **Python script**
3. **Store the output** into a local `.csv` and Excel file

---

## 🔧 Requirements

### On your self-hosted machine:

- PowerShell 7+ (`pwsh`)
- Python 3.9+
- Python packages:
  ```bash
  pip install pandas numpy openpyxl

## 📄 Files
1. script_powershell.ps1
- Connects to the JiraApiCube via MSOLAP and runs a DAX query to extract Jira issue data related to the string "BATTI".

- Connection details: Server: Ams2wp-bwc20-3\\DWH_PROD_TAB; Cube: JiraApiCube
- writes to : ./output.csv

2. capacity_metric.py
- Processes the output CSV to:
- Parse dates and detect overdue issues
- Compute: Overdue severity (ratio of overdue to total) and Proportion of "To Do" tickets. Overall capacity score using a 50/50 blend
- Stores results in:./store_capacity.xlsx

📈 Output Files
- output.csv: Raw data from the cube query
- store_capacity.xlsx: Capacity metric values appended per run
