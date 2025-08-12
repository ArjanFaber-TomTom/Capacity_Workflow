# Capacity_Workflow
Implementing an automated workflow for storing capacity metric (BATTI projects)

# Requirements
Install Microsoft OLE DB Driver for SQL Server on your local machine (Windows): https://learn.microsoft.com/en-us/sql/connect/oledb/release-notes-for-oledb-driver-for-sql-server?view=sql-server-ver17

# Setup
Configure the Windows scheduler (.bat file) by adjusting the path to the Github self-hosted runner (in default case it is "C:\Users\fabera\Self-Hosted_Runner\run.cmd" ) . 

How to schedule it with Windows Task Scheduler? 
1. Press Win + R, type taskschd.msc, and hit Enter.

2. Click Create Basic Task or Create Task.

3. Give it a name like “Start GitHub Runner”.

4. Choose a trigger (e.g., at system startup, daily at 8 AM, etc.).

5. For the action, select Start a program.

6. Browse to the .bat file or type its full path, e.g.

"C:\path\to\scheduler.bat"

