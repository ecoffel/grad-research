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

def loadGlobalWx(wxdata):
    if wxdata == 'all':
        import pickle, os
        
        if os.path.isfile('globalWx.dat'):
            with open('globalWx.dat', 'rb') as f:
                globalWx = pickle.load(f)
                return globalWx
        else:
            fileNameEra = 'global-pp-tx-era.csv'
            fileNameCpc = 'global-pp-tx-cpc.csv'
            fileNameNcep = 'global-pp-tx-ncep.csv'
    
            plantList = []
            with open(fileNameEra, 'r') as f:
                i = 0
                for line in f:
                    if i >= 3:
                        parts = line.split(',')
                        plantList.append(parts[0])
                    i += 1
            plantTxData = np.genfromtxt(fileNameEra, delimiter=',', skip_header=0)
            plantYearData = plantTxData[0,1:].copy()
            plantMonthData = plantTxData[1,1:].copy()
            plantDayData = plantTxData[2,1:].copy()
            plantTxDataEra = plantTxData[3:,1:].copy()
            
            plantTxDataCpc = np.genfromtxt(fileNameCpc, delimiter=',', skip_header=0)
            plantTxDataCpc = plantTxDataCpc[3:,1:].copy()
            
            plantTxDataNcep = np.genfromtxt(fileNameNcep, delimiter=',', skip_header=0)
            plantTxDataNcep = plantTxDataNcep[3:,1:].copy()
            
            plantTxData = np.zeros([plantTxDataEra.shape[0], plantTxDataEra.shape[1], 3])
            plantTxData[:,:,0] = plantTxDataEra
            plantTxData[:,:,1] = plantTxDataCpc
            plantTxData[:,:,2] = plantTxDataNcep
            
            plantTxData = np.nanmean(plantTxData, axis=2)
    
            globalWx = {'plantYearData':plantYearData, 'plantMonthData':plantMonthData, \
                        'plantDayData':plantDayData, 'plantTxData':plantTxData, \
                        'plantList':plantList}
            
            with open('globalWx.dat', 'wb') as f:
                pickle.dump(globalWx, f)
            
            return globalWx


def exportGlobalPlants(globalPlants):
    i = 0
    with open('global-pp-lat-lon.csv', 'w') as f:
        csvWriter = csv.writer(f)    
        for i in range(len(globalPlants['lats'])):
            csvWriter.writerow([i, globalPlants['lats'][i], globalPlants['lons'][i]])


        