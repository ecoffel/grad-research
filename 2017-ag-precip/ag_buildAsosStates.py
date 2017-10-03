# -*- coding: utf-8 -*-
"""
Created on Fri Sep 29 17:02:43 2017

@author: Ethan

Merges each station
"""

import os
import pickle
import gzip

baseDir = 'e:/data/projects/ag/wx-data/'

states = ['al', 'az', 'ar', 'ca', 'co', 'ct', 'de', 'fl', 'ga', \
          'id', 'il', 'in', 'ia', 'ks', 'ky', 'la', 'me', 'md', \
          'ma', 'mi', 'mn', 'ms', 'mo', 'mt', 'ne', 'nv', 'nh', 'nj', \
          'nm', 'ny', 'nc', 'nd', 'oh', 'ok', 'or', 'pa', 'ri', 'sc', \
          'sd', 'tn', 'tx', 'ut', 'vt', 'va', 'wa', 'wv', 'wi', 'wy']
states = ['mi']
for state in states:
    stateDir = baseDir + state + '/'
    
    print('processing ' + state + '...')
    
    # weather db: (key = station id, value = dictionary(key = column, val = value at time))
    stateDb = {}
    
    # find all files in this directory
    files = os.listdir(stateDir)
    
    # columns:
    # 0 - year
    # 1 - month
    # 2 - day
    # 3 - hour
    # 4 - lon
    # 5 - lat
    # 6 - temp (C, -999 = missing value)
    # 7 - rel humidity (%, -999 = missing value)
    # 8 - precip (hourly, mm, -999 = missing value)
    
    # loop over all stations
    for file in files:
        f = open(stateDir + file, 'r')
        
        stationID = file.strip('.txt')
        
        # loop over each line in current station file
        for line in f:
            parts = line.split(',')
            
            lon = float(parts[4].strip())
            lat = float(parts[5].strip())

            stateDb[stationID] = (lat, lon)
            break        
            
        f.close()
    
    fileName = baseDir + 'asos-station-locations-' + state
    with open(fileName + '.dat', 'wb') as f:
        pickle.dump(stateDb, f)
    