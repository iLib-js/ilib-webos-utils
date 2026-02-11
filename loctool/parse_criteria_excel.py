#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
parse_criteria_excel.py

Reads an Excel file and converts each row to a loctool criteria string.
The first row is column names, subsequent rows are criteria.
Example: eng,key_others,module_info,datatype -> source,key,project,datatype
Each row is output as 'source=^...$,key=^...$,project=^...$,datatype=^...$'
"""

import sys
import pandas as pd
import re

if len(sys.argv) < 2:
    print("[parse_criteria] Usage: parse_criteria_excel.py <excel-file>", file=sys.stderr)
    sys.exit(1)

excel_file = sys.argv[1]
try:
    df = pd.read_excel(excel_file)
except Exception as e:
    print(f"[parse_criteria] [ERROR] Failed to read Excel file: {e}", file=sys.stderr)
    sys.exit(2)

col_map = {
    'key_others': 'key',
    'eng': 'source',
    'module_info': 'project',
    'datatype': 'datatype',
}

criteria_list = []
criteria_map = {}

def print_log(message):
    print(f"[parse_criteria] {message}", file=sys.stderr)

# for Bash output
def print_data(message):
    print(message)

def regex_escape(val):
    # Escape regex special characters
    return re.sub(r'([.\\+*?\[^\]$(){}=!<>|:\-])', r'\\\1', val)

for _, row in df.iterrows():
    parts = []
    log_values = []
    values = {col: str(row[col]).strip() if col in row and pd.notnull(row[col]) else '' for col in col_map}
    # If key_others is empty, use eng (source) as key
    if not values['key_others']:
        values['key_others'] = values.get('eng', '')
    for col in col_map:
        mapped = col_map[col]
        val_str = values[col]
        log_values.append(f"{mapped}: {val_str}")
        if val_str:
            esc_val = regex_escape(val_str)
            parts.append(f"{mapped}=^{esc_val}$")
    if log_values:
        print_log(f"[parse_criteria] values: " + ", ".join(log_values))

    if parts:
        criteria = ','.join(parts)
        # Find the column name mapped to 'project' in col_map
        project_col = [k for k, v in col_map.items() if v == 'project']
        project = values.get(project_col[0], '') if project_col else ''
        if project:
            if project not in criteria_map:
                criteria_map[project] = []
            criteria_map[project].append(criteria)

# Output data for Bash
# WARNING: If the print message format changes, the Bash script may not work correctly.
for project, criteria_list in criteria_map.items():
    print_data(f"[PROJECT: {project}]")
    for crit in criteria_list:
        print_data(crit)

