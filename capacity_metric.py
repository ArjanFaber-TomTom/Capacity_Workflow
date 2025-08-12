import sys
import os
import json
import pandas as pd
import numpy as np
import psycopg2
from datetime import datetime

# Read JSON from stdin
raw_input = sys.stdin.read()
if not raw_input:
    print("No input received.")
    sys.exit(1)

data = json.loads(raw_input)
df = pd.DataFrame(data)
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

pw = "'9GV~NGU3uUZL8v"

try:
    conn = psycopg2.connect(
        dbname="tti_database",
        user="YE2137_user_tti_quality",
        password=pw, 
        host="tti-biba-db.postgres.database.azure.com",
        port=5432,
        sslmode="require"
    )
    print("Connection successful!")

    cur = conn.cursor()

    # Prepare data to insert
    current_date = today 
    value =  capacity

    # SQL insert statement
    insert_query = """
        INSERT INTO ba.capacity_metric (date, capacity)
        VALUES (%s, %s)
    """

    # Row data to insert
    row_to_insert = (current_date, value)

    try:
        cur.execute(insert_query, row_to_insert)
        conn.commit()
        print("Row inserted successfully!")
    except Exception as e:
        print("Error inserting row:", e)
        conn.rollback()

    cur.close()
    conn.close()

except Exception as e:
    print("Connection failed:", e)











