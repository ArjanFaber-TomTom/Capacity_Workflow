import pandas as pd 
import numpy as np
from datetime import datetime

df = pd.read_csv('output.csv')
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
print(capacity)
