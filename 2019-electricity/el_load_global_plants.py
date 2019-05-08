# -*- coding: utf-8 -*-
"""
Created on Wed May  1 17:41:46 2019

@author: Ethan
"""

import numpy as np
import csv

dataDir = 'e:/data'

def loadGlobalPlants():
    globalPlants = {'countries':[], 'caps':[], 'lats':[], 'lons':[], 'fuels':[]}
        
    with open('%s/ecoffel/data/projects/electricity/global_power_plant_database.csv'%dataDir, 'r', encoding='latin-1') as f:
        i = 0
        for line in f:
            if i == 0:
                i += 1
                continue
            
            parts = line.split(',')
            globalPlants['countries'].append(parts[0].strip())
            globalPlants['caps'].append(float(parts[4].strip()))
            globalPlants['lats'].append(float(parts[5].strip()))
            globalPlants['lons'].append(float(parts[6].strip()))
            globalPlants['fuels'].append(parts[7].strip())
    
    globalPlants['countries'] = np.array(globalPlants['countries'])
    globalPlants['caps'] = np.array(globalPlants['caps'])
    globalPlants['lats'] = np.array(globalPlants['lats'])
    globalPlants['lons'] = np.array(globalPlants['lons'])
    globalPlants['fuels'] = np.array(globalPlants['fuels'])

    return globalPlants


def exportGlobalPlants(globalPlants):
    # only export 100MW or greater plants
    capThresh = 1000
    
    i = 0
    with open('global-pp-lat-lon.csv', 'w') as f:
        csvWriter = csv.writer(f)    
        for i in range(len(globalPlants['lats'])):
            if globalPlants['caps'][i] > capThresh:
                csvWriter.writerow([i, globalPlants['lats'][i], globalPlants['lons'][i]])


        