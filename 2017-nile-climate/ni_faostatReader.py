# -*- coding: utf-8 -*-
"""
Spyder Editor

This is a temporary script file.
"""

import csv

with open('data/ethiopia-food-supply.csv', 'r') as f:
    reader = csv.reader(f)
    for row in reader:
        print(row)