# -*- coding: utf-8 -*-
"""
Created on Wed May  1 17:41:46 2019

@author: Ethan
"""

import numpy as np
import csv

#dataDir = 'e:/data'
dataDirDiscovery = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/projects/electricity'


def countryCheck(s):
    
    countries = ['USA', 'AUT', 'BEL', 'BGR', 'HRV', 'CYP', 'CZE', 'DNK', \
                 'EST', 'FIN', 'FRA', 'DEU', 'GRC', 'HUN', 'IRL', 'ITA', \
                 'LVA', 'LTU', 'LUX', 'MLT', 'NLD', 'POL', 'PRT', 'ROU', \
                 'SVK', 'SVN', 'ESP', 'SWE', 'GBR']
    
    if s.upper() in countries:
        return True
    else:
        return False

def countryCheckNoUS(s):
    
    countries = ['AUT', 'BEL', 'BGR', 'HRV', 'CYP', 'CZE', 'DNK', \
                 'EST', 'FIN', 'FRA', 'DEU', 'GRC', 'HUN', 'IRL', 'ITA', \
                 'LVA', 'LTU', 'LUX', 'MLT', 'NLD', 'POL', 'PRT', 'ROU', \
                 'SVK', 'SVN', 'ESP', 'SWE', 'GBR']
    
    if s.upper() in countries:
        return True
    else:
        return False
    

def fuelCheck(s):
    
    fuels = ['coal', 'gas', 'oil', 'nuclear', 'biomass']
    
    if s.lower() in fuels:
        return True
    else:
        return False

def capacityCheck(c):
    if c >= 0:
        return True
    else:
        return False

def loadGlobalPlants(world = True, us = True):
    globalPlants = {'countries':[], 'caps':[], 'lats':[], 'lons':[], 'fuels':[], 'yearCom':[]}
    
    with open('%s/global_power_plant_database.csv'%dataDirDiscovery, 'r', encoding='latin-1') as f:
        i = 0
        for line in f:
            if i == 0:
                i += 1
                continue
            
            parts = line.split(',')
            
            country = parts[0].strip()
            fuel = parts[7].strip()
            cap = float(parts[4].strip())
            
            year = parts[11].strip()
            if len(year) > 0:
                year = float(year)
            else:
                year = np.nan
            
            if not world:
                # if us-eu
                
                # if using US, check against US + EU
                if us:
                    if countryCheck(country) and fuelCheck(fuel) and capacityCheck(cap):
                        globalPlants['countries'].append(country)
                        globalPlants['caps'].append(cap)
                        globalPlants['lats'].append(float(parts[5].strip()))
                        globalPlants['lons'].append(float(parts[6].strip()))
                        globalPlants['fuels'].append(fuel)
                        globalPlants['yearCom'].append(year)
                # if no US, check against only EU
                else:
                    if countryCheckNoUS(country) and fuelCheck(fuel) and capacityCheck(cap):
                        globalPlants['countries'].append(country)
                        globalPlants['caps'].append(cap)
                        globalPlants['lats'].append(float(parts[5].strip()))
                        globalPlants['lons'].append(float(parts[6].strip()))
                        globalPlants['fuels'].append(fuel)
                        globalPlants['yearCom'].append(year)
                    
            else:
                # world, so no country check
                if fuelCheck(fuel) and capacityCheck(cap):
                    globalPlants['countries'].append(country)
                    globalPlants['caps'].append(cap)
                    globalPlants['lats'].append(float(parts[5].strip()))
                    globalPlants['lons'].append(float(parts[6].strip()))
                    globalPlants['fuels'].append(fuel)
                    globalPlants['yearCom'].append(year)
    
    globalPlants['countries'] = np.array(globalPlants['countries'])
    globalPlants['caps'] = np.array(globalPlants['caps'])
    globalPlants['lats'] = np.array(globalPlants['lats'])
    globalPlants['lons'] = np.array(globalPlants['lons'])
    globalPlants['fuels'] = np.array(globalPlants['fuels'])
    globalPlants['yearCom'] = np.array(globalPlants['yearCom'])

    return globalPlants

def loadGlobalWx(wxdata):
    if wxdata == 'all':
        import pickle, os, gzip
        
        if os.path.isfile('globalWx.dat'):
            with gzip.open('globalWx.dat', 'rb') as f:
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
            plantYearData = plantTxData[0,:].copy()
            plantMonthData = plantTxData[1,:].copy()
            plantDayData = plantTxData[2,:].copy()
            plantTxDataEra = plantTxData[3:,:].copy()
            
            plantTxDataCpc = np.genfromtxt(fileNameCpc, delimiter=',', skip_header=0)
            plantTxDataCpc = plantTxDataCpc[3:,:].copy()
            
            plantTxDataNcep = np.genfromtxt(fileNameNcep, delimiter=',', skip_header=0)
            plantTxDataNcep = plantTxDataNcep[3:,:].copy()
            
            plantTxData = np.zeros([plantTxDataEra.shape[0], plantTxDataEra.shape[1], 3])
            plantTxData[:,:,0] = plantTxDataEra
            plantTxData[:,:,1] = plantTxDataCpc
            plantTxData[:,:,2] = plantTxDataNcep
            
            plantTxData = np.nanmean(plantTxData, axis=2)
    
            globalWx = {'plantYearData':plantYearData, 'plantMonthData':plantMonthData, \
                        'plantDayData':plantDayData, 'plantTxData':plantTxData, \
                        'plantList':plantList}
            
            with gzip.open('globalWx.dat', 'wb') as f:
                pickle.dump(globalWx, f)
            
            return globalWx


def exportGlobalPlants(globalPlants):
    i = 0
    with open('useu-pp-lat-lon.csv', 'w') as f:
        csvWriter = csv.writer(f)    
        for i in range(len(globalPlants['lats'])):
            csvWriter.writerow([i, globalPlants['lats'][i], globalPlants['lons'][i]])


        