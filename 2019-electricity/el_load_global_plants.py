# -*- coding: utf-8 -*-
"""
Created on Wed May  1 17:41:46 2019

@author: Ethan
"""

import numpy as np
import csv

dataDir = 'e:/data'


def countryCheck(s):
    
    countries = ['USA', 'AUT', 'BEL', 'BGR', 'HRV', 'CYP', 'CZE', 'DNK', \
                 'EST', 'FIN', 'FRA', 'DEU', 'GRC', 'HUN', 'IRL', 'ITA', \
                 'LVA', 'LTU', 'LUX', 'MLT', 'NLD', 'POL', 'PRT', 'ROU', \
                 'SVK', 'SVN', 'ESP', 'SWE', 'GBR']
    
    if s.upper() in countries:
        return True
    else:
        return False

def fuelCheck(s):
    
    fuels = ['gas', 'coal', 'oil', 'nuclear']
    
    if s.lower() in fuels:
        return True
    else:
        return False

def capacityCheck(c):
    if c >= 400:
        return True
    else:
        return False

def loadGlobalPlants():
    globalPlants = {'countries':[], 'caps':[], 'lats':[], 'lons':[], 'fuels':[]}
        
    with open('%s/ecoffel/data/projects/electricity/global_power_plant_database.csv'%dataDir, 'r', encoding='latin-1') as f:
        i = 0
        for line in f:
            if i == 0:
                i += 1
                continue
            
            parts = line.split(',')
            
            country = parts[0].strip()
            fuel = parts[7].strip()
            cap = float(parts[4].strip())
            
            if countryCheck(country) and fuelCheck(fuel) and capacityCheck(cap):
                globalPlants['countries'].append(country)
                globalPlants['caps'].append(cap)
                globalPlants['lats'].append(float(parts[5].strip()))
                globalPlants['lons'].append(float(parts[6].strip()))
                globalPlants['fuels'].append(fuel)
    
    globalPlants['countries'] = np.array(globalPlants['countries'])
    globalPlants['caps'] = np.array(globalPlants['caps'])
    globalPlants['lats'] = np.array(globalPlants['lats'])
    globalPlants['lons'] = np.array(globalPlants['lons'])
    globalPlants['fuels'] = np.array(globalPlants['fuels'])

    return globalPlants


def exportGlobalPlants(globalPlants):
    i = 0
    with open('global-pp-lat-lon.csv', 'w') as f:
        csvWriter = csv.writer(f)    
        for i in range(len(globalPlants['lats'])):
            csvWriter.writerow([i, globalPlants['lats'][i], globalPlants['lons'][i]])


        