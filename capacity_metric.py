import sys
import json
import pandas as pd
import numpy as np
from datetime import datetime

# Read JSON from stdin
raw_input = sys.stdin.read()
if not raw_input:
    print("No input received.")
    sys.exit(1)

data = json.loads(raw_input)

df.columns

# Convert the date columns (note the brackets)
df['[Date Due]'] = pd.to_datetime(df['[Date Due]'], errors='coerce')

today = datetime.today()


# Get first day of current month
start_of_year = datetime(2025, 1, 1)

df = df.sort_values('[Date Created]')

# Cumulative overdue count
df['Is Overdue'] = (df['[Date Due]'] < today)
df = df.sort_values('[Date Created]')
df['Cumulative Overdue'] = df['Is Overdue'].cumsum()

# 2. Filter only overdue rows (Is Overdue == True)
df_overdue = df[df['Is Overdue']]

overdue_severity = int(np.array(df['Cumulative Overdue'])[-1])/int(len(df))
todo_tickets = df[
    (df['[Status Name]'] == 'To Do')  
    ]
inprogress_tickets = df[
     (df['[Status Name]'] == 'In Progress')  ]
    

if (len(inprogress_tickets) + len(todo_tickets)) != 0:
    proportion_todo = len(todo_tickets) / (len(inprogress_tickets) + len(todo_tickets))
else:
    proportion_todo = 0
capacity = 0.5*proportion_todo + 0.5* overdue_severity

df = pd.DataFrame({'date': [today], 'value': [capacity]})
file_path = "C:/Users/fabera/OneDrive - TomTom/Desktop/Scripts_Git/store_capacity.xlsx"
if os.path.exists(file_path) and os.path.getsize(file_path) > 0:
    with pd.ExcelWriter(file_path, engine='openpyxl', mode='a', if_sheet_exists='overlay') as writer:
    # Append below existing data, so find max_row
        startrow = writer.sheets[writer.book.active.title].max_row
        df.to_excel(writer, index=False, header=False, startrow=startrow)
else:
    df.to_excel(file_path, index=False)








