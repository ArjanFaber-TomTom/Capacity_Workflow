# Capacity_Workflow
Implementing an automated workflow for storing capacity metric (BATTI projects)

# Requirements
Install Microsoft OLE DB Driver for SQL Server on your local machine (Windows): https://learn.microsoft.com/en-us/sql/connect/oledb/release-notes-for-oledb-driver-for-sql-server?view=sql-server-ver17

# Setup
A. Configure a self-hosted runner on a local Windows machine e.g. "C:\Users\fabera\Self-Hosted_Runner" . Make sure to not create a directory for the self-hosted runner on a OneDrive folder since that will create errors. 

B. Configure the Windows scheduler (.bat file) by adjusting the path to the Github self-hosted runner (in default case it is "C:\Users\fabera\Self-Hosted_Runner\run.cmd" ) . 

How to schedule it with Windows Task Scheduler? 
1. Press Win + R, type shell:startup, and hit Enter.

2. add scheduler.bat file here


