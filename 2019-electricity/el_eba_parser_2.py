# -*- coding: utf-8 -*-
"""
Created on Sat Mar 23 22:29:41 2019

@author: Ethan
"""


# -*- coding: utf-8 -*-
"""
Created on Wed Mar  6 15:09:30 2019

@author: Ethan
"""

import json
import matplotlib.pyplot as plt 
import numpy as np
import pandas as pd
import statsmodels.api as sm
import sys

from el_subgrids import subgrids

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDir = 'e:/data/'

def normalize(v):
    nn = np.where(~np.isnan(v))[0]
    norm = np.linalg.norm(v[nn])
    if norm == 0: 
       return v
   
    v[nn] = v[nn] / norm
    return v

months = range(1,13)

if not 'eba' in locals():
    print('loading eba...')
    eba = []
    for line in open('%s/ecoffel/data/projects/electricity/EBA.txt' % dataDir, 'r'):
        if (len(eba)+1) % 100 == 0:
            print('loading line ', (len(eba)+1))
            
        curLine = json.loads(line)
        
        
        #if 'Demand for' in curLine['name']: print(ln)
        
        if 'data' in curLine.keys():
            curLine['data'].reverse()
            curLineNew = curLine.copy()
            
            del curLineNew['data']
            curLineNew['year'] = []
            curLineNew['month'] = []
            curLineNew['day'] = []
            curLineNew['hour'] = []
            curLineNew['dataMax'] = []
            curLineNew['dataMin'] = []
            curLineNew['dataMean'] = []
            
            i = 0
            while i < len(curLine['data']):
                datapt = curLine['data'][i]
                curLineNew['year'].append(int(datapt[0][0:4]))
                curLineNew['month'].append(int(datapt[0][4:6]))
                curLineNew['day'].append(int(datapt[0][6:8]))
                
                hrlyData = []
                
                curDay = int(datapt[0][6:8])
                while i < len(curLine['data']) and int(curLine['data'][i][0][6:8]) == curDay:
                    if curLine['data'][i][1] != None:
                        hrlyData.append(float(curLine['data'][i][1]))
                    else:
                        hrlyData.append(np.nan)
                    i += 1
                
                if len(hrlyData) == 24 and len(np.where(~np.isnan(hrlyData))[0]) > 12:
                    
                    curLineNew['dataMax'].append(np.nanmax(hrlyData))
                    curLineNew['dataMin'].append(np.nanmin(hrlyData))
                    curLineNew['dataMean'].append(np.nanmean(hrlyData))
                else:
                    curLineNew['dataMax'].append(np.nan)
                    curLineNew['dataMin'].append(np.nan)
                    curLineNew['dataMean'].append(np.nan)
                
            curLineNew['year'] = np.array(curLineNew['year'])
            curLineNew['month'] = np.array(curLineNew['month'])
            curLineNew['day'] = np.array(curLineNew['day'])
            curLineNew['hour'] = np.array(curLineNew['hour'])
            curLineNew['dataMax'] = normalize(np.array(curLineNew['dataMax']))
            curLineNew['dataMin'] = normalize(np.array(curLineNew['dataMin']))
            curLineNew['dataMean'] = normalize(np.array(curLineNew['dataMean']))
#            curLineNew['dataMax'] = np.array(curLineNew['dataMax'])
#            curLineNew['dataMin'] = np.array(curLineNew['dataMin'])
#            curLineNew['dataMean'] = np.array(curLineNew['dataMean'])
            
            curLineNew['dataMaxSmooth'] = curLineNew['dataMax'].copy()
            curLineNew['dataMinSmooth'] = curLineNew['dataMin'].copy()
            curLineNew['dataMeanSmooth'] = curLineNew['dataMean'].copy()
            
            # remove 15 day mean (360 hr)
            tmpSmooth = pd.rolling_mean(curLineNew['dataMaxSmooth'], 15)
            indNn = np.where(~np.isnan(tmpSmooth))[0]
            indNan = np.where(np.isnan(tmpSmooth))[0]
            curLineNew['dataMaxSmooth'][indNn] = curLineNew['dataMaxSmooth'][indNn] - tmpSmooth[indNn]
            curLineNew['dataMaxSmooth'][indNan] = np.nan
            
            tmpSmooth = pd.rolling_mean(curLineNew['dataMinSmooth'], 15)
            indNn = np.where(~np.isnan(tmpSmooth))[0]
            indNan = np.where(np.isnan(tmpSmooth))[0]
            curLineNew['dataMinSmooth'][indNn] = curLineNew['dataMinSmooth'][indNn] - tmpSmooth[indNn]
            curLineNew['dataMinSmooth'][indNan] = np.nan
            
            tmpSmooth = pd.rolling_mean(curLineNew['dataMeanSmooth'], 15)
            indNn = np.where(~np.isnan(tmpSmooth))[0]
            indNan = np.where(np.isnan(tmpSmooth))[0]
            curLineNew['dataMeanSmooth'][indNn] = curLineNew['dataMeanSmooth'][indNn] - tmpSmooth[indNn]
            curLineNew['dataMeanSmooth'][indNan] = np.nan

            eba.append(curLineNew)

if not 'dailySeries' in locals():
    dailySeries = {'year':[], 'month':[], 'day':[], 'tempData':[], 'rhData':[], 'wbData':[], \
                       'genData':[], 'intData':[], 'demData':[], 'demFctData':[]}
    
    stateList = []
    with open('subgrid-tx-era.csv', 'r') as f:
        i = 0
        for line in f:
            if i > 2:
                parts = line.split(',')
                stateList.append(parts[0])
            i += 1
    tx = np.genfromtxt('subgrid-tx-era.csv', delimiter=',', skip_header=1)
    year = tx[0,1:]
    month = tx[1,1:]
    day = tx[2,1:]
    tx = tx[3:,1:]
        
    for subgrid in subgrids.keys():

        print('building daily electricity data for %s...' % subgrid)

        dailySeries['genData'].append([])
        dailySeries['demData'].append([])
        dailySeries['intData'].append([])
        dailySeries['demFctData'].append([])
        dailySeries['tempData'].append([])

        genId = subgrids[subgrid]['genId']
        demId = subgrids[subgrid]['demId']
        demFctId = subgrids[subgrid]['demFctId']
        intId = subgrids[subgrid]['intId']
        
        # loop through all obs from the uscrn data
        for i in range(tx.shape[1]):
            
            # find matching TX generation data
            indGen = np.where((eba[genId]['year'] == year[i]) & \
                           (eba[genId]['month'] == month[i]) & \
                           (eba[genId]['day'] == day[i]))[0]
            
            # and find TX interchange data
            indInt = np.where((eba[intId]['year'] == year[i]) & \
                           (eba[intId]['month'] == month[i]) & \
                           (eba[intId]['day'] == day[i]))[0]
            
            # and find TX demand data
            indDem = np.where((eba[demId]['year'] == year[i]) & \
                           (eba[demId]['month'] == month[i]) & \
                           (eba[demId]['day'] == day[i]))[0]
            
            # and find TX demand forecast data
            indDemFct = np.where((eba[demFctId]['year'] == year[i]) & \
                           (eba[demFctId]['month'] == month[i]) & \
                           (eba[demFctId]['day'] == day[i]))[0]
                        
            if len(indGen) == 1 and len(indInt) == 1 and len(indDem) == 1 and len(indDemFct) == 1:
                dailySeries['genData'][-1].extend(eba[genId]['dataMaxSmooth'][indGen])
                dailySeries['intData'][-1].extend(eba[intId]['dataMinSmooth'][indInt])
                dailySeries['demData'][-1].extend(eba[demId]['dataMaxSmooth'][indDem])
                dailySeries['demFctData'][-1].extend(eba[demFctId]['dataMaxSmooth'][indDemFct])
                
                # add list for current day
                meanTx = 0
                for state in subgrids[subgrid]['states']:
                    meanTx += tx[stateList.index(state)-1, i]
                                                
                dailySeries['tempData'][-1].append(meanTx / len(subgrids[subgrid]['states']))
    
            else:
                dailySeries['genData'][-1].append(np.nan)
                dailySeries['intData'][-1].append(np.nan)
                dailySeries['demData'][-1].append(np.nan)
                dailySeries['demFctData'][-1].append(np.nan)
                dailySeries['tempData'][-1].append(np.nan)
        
    dailySeries['genData'] = np.array(dailySeries['genData'])
    dailySeries['intData'] = np.array(dailySeries['intData'])
    dailySeries['demData'] = np.array(dailySeries['demData'])
    dailySeries['demFctData'] = np.array(dailySeries['demFctData'])
    dailySeries['tempData'] = np.array(dailySeries['tempData'])

intTx = []
genTx = []
demTx = []
demFctTx = []
for s in range(len(subgrids)):
    dailyTx = dailySeries['tempData'][s]
    
    intTx.append([])
    genTx.append([])
    demTx.append([])
    demFctTx.append([])
    
    range1 = -20
    range2 = 40
    step = 2
    for t in range(range1, range2, step):
        indTx = np.where((dailyTx >= t) & (dailyTx < t+step))[0]
        if len(indTx) < 10:
            intTx[s].append(np.nan)
            genTx[s].append(np.nan)
            demTx[s].append(np.nan)
            demFctTx[s].append(np.nan)
            continue
        intTx[s].append(np.nanmean(dailySeries['intData'][s][indTx], axis = 0))
        genTx[s].append(np.nanmean(dailySeries['genData'][s][indTx], axis = 0))
        demTx[s].append(np.nanmean(dailySeries['demData'][s][indTx], axis = 0))
        demFctTx[s].append(np.nanmean(dailySeries['demFctData'][s][indTx], axis = 0))
    
demTx = np.transpose(np.array(demTx))
genTx = np.transpose(np.array(genTx))
intTx = np.transpose(np.array(intTx))

plt.figure()
for s in range(len(subgrids)):
#    plt.plot(range(range1, range2, step), demTx[:,s]-genTx[:,s], label='Demand - Generation for %s'%list(subgrids.keys())[s])
    plt.plot(range(range1, range2, step), intTx[:,s], label='Interchange for %s'%list(subgrids.keys())[s])
plt.plot([-100, 100], [0, 0], '--k')
plt.xticks(range(-20, 40, 5))
plt.xlim([-20, 41])
plt.xlabel('Summer daily max Tx')
plt.ylabel('Electricity anomaly (MWh)')

plt.figure()
for s in range(len(subgrids)):
    plt.plot(range(range1, range2, step), demTx[:,s], label='Demand for %s'%list(subgrids.keys())[s])
    plt.plot(range(range1, range2, step), genTx[:,s], label='Generation for %s'%list(subgrids.keys())[s])
plt.plot([-100, 100], [0, 0], '--k')
plt.xticks(range(-20, 40, 5))
plt.xlim([-20, 41])
plt.xlabel('Summer daily max Tx')
plt.ylabel('Electricity anomaly (MWh)')


sys.exit()











