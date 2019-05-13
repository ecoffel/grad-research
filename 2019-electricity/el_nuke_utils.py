# -*- coding: utf-8 -*-
"""
Created on Mon Apr  1 09:47:36 2019

@author: Ethan
"""

import json
import numpy as np

import sys

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDir = 'e:/data/'

useEra = True
plotFigs = False

def loadNukeData(dataDir):
    print('loading nuke eba...')
    eba = []
    for line in open('%s/ecoffel/data/projects/electricity/NUC_STATUS.txt' % dataDir, 'r'):
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
            curLineNew['data'] = []
            
            for datapt in curLine['data']:
                # restrict to before 2019
                if int(datapt[0][0:4]) > 2018:
                    continue
                
                curLineNew['year'].append(int(datapt[0][0:4]))
                curLineNew['month'].append(int(datapt[0][4:6]))
                curLineNew['day'].append(int(datapt[0][6:8]))
                if not datapt[1] == None:
                    curLineNew['data'].append(float(datapt[1]))
                else:
                    curLineNew['data'].append(np.nan)
                    
            curLineNew['year'] = np.array(curLineNew['year'])
            curLineNew['month'] = np.array(curLineNew['month'])
            curLineNew['day'] = np.array(curLineNew['day'])
            curLineNew['data'] = np.array(curLineNew['data'])
            
            eba.append(curLineNew)
    return eba

def loadWxData(eba, wxdata):
    # read tw time series
    fileName = ''
    
    if wxdata == 'cpc':
        fileName = 'nuke-tx-cpc.csv'
    elif wxdata == 'era':
        fileName = 'nuke-tx-era-075.csv'
    elif wxdata == 'ncep':
        fileName = 'nuke-tx-ncep.csv'
    elif wxdata == 'all':
        fileName = ['nuke-tx-cpc.csv', 'nuke-tx-era-075.csv', 'nuke-tx-ncep.csv']
        
        
    tx = []
    
    if wxdata == 'all':
        tx1 = np.genfromtxt(fileName[0], delimiter=',')    
        tx2 = np.genfromtxt(fileName[1], delimiter=',')    
        tx3 = np.genfromtxt(fileName[2], delimiter=',')    
        
        tx = tx1.copy()
        for i in range(0,tx1.shape[0]):
            for j in range(1,tx1.shape[1]):
                tx[i,j] = np.nanmean([tx1[i,j], tx2[i,j], tx3[i,j]])
        
    else:
        tx = np.genfromtxt(fileName, delimiter=',')
        
    # these ids store the line numbers for plant level outage and capacity data in the EBA file
    ids = []
    for i in range(tx.shape[0]):
        # current facility outage name
        outageId = int(tx[i,0])
        name = eba[outageId]['name']
        
        if 'for generator' in name: 
            continue
        
        nameParts = name.split(' at ')
        for n in range(len(eba)):
            if 'Nuclear generating capacity' in eba[n]['name'] and \
               not 'outage' in eba[n]['name'] and \
               not 'for generator' in eba[n]['name'] and \
               nameParts[1] in eba[n]['name']:
                   capacityId = n
                   ids.append([outageId, capacityId])
    return (np.array(tx), np.array(ids))





def accumulateNukeWxDataPlantLevel(eba, tx, ids):
    
    summerInds = np.where((eba[0]['month'] == 7) | (eba[0]['month'] == 8))[0]
    
    plantPercCapacity = []
    plantTx = []
    
    plantMonths = []
    plantDays = []
    
    for i in range(ids.shape[0]):
        out = np.array(eba[ids[i,0]]['data'])
        cap = np.array(eba[ids[i,1]]['data'])     
        
        if len(out) == 4383 and len(cap) == 4383:
            
            # calc the plant operating capacity (% of total normal capacity)
            plantPercCapacity.append(100*(1-(out/cap)))
            
            plantMonths.append(eba[ids[i,0]]['month'])
            plantDays.append(eba[ids[i,0]]['day'])
            
    
    plantPercCapacity = np.array(plantPercCapacity)  
    plantMonths = np.array(plantMonths)
    plantDays = np.array(plantDays)
    
    finalPlantPercCapacity = []
    
    for i in range(plantPercCapacity.shape[0]):
        
        y = plantPercCapacity[i]
        x = tx[i,1:]
        
        if len(y)==len(x):
            y = y[summerInds]
            x = x[summerInds]
            nn = np.where((~np.isnan(y)) & (~np.isnan(x)))[0]
            y = y[nn]
            x = x[nn]
            
            finalPlantPercCapacity.append(y)
            plantTx.append(x)
    
    plantTx = np.array(plantTx)
    finalPlantPercCapacity = np.array(finalPlantPercCapacity)
    
    d = {'txSummer': plantTx, 'capacitySummer':finalPlantPercCapacity, \
         'summerInds':summerInds, \
         'plantMonths':plantMonths, 'plantDays':plantDays}
    return d






def accumulateNukeWxData(eba, tx, ids):
    
    summerInds = np.where((eba[0]['month'] == 7) | (eba[0]['month'] == 8))[0]
    
    percCapacity = []
    totalOut = []
    totalCap = []
    
    # unique identifiers for plants
    plantIds = []
    plantMonths = []
    plantDays = []
    
    for i in range(ids.shape[0]):
        out = np.array(eba[ids[i,0]]['data'])
        cap = np.array(eba[ids[i,1]]['data'])     
        
        if len(out) == 4383 and len(cap) == 4383:
            
            # calc the plant operating capacity (% of total normal capacity)
            percCapacity.append(100*(1-(out/cap)))
            
            plantIds.append([i]*len(out))
            plantMonths.append(eba[ids[i,0]]['month'])
            plantDays.append(eba[ids[i,0]]['day'])
            
            if len(totalOut) == 0:
                totalOut = out
                totalCap = cap
            else:
                totalOut += out
                totalCap += cap
    
    percCapacity = np.array(percCapacity)  
    plantIds = np.array(plantIds)
    plantMonths = np.array(plantMonths)
    plantDays = np.array(plantDays)
    
    outageBool = []
    
    xtotal = []
    ytotal = []
    plantIdsAcc = []
    plantMeanTempsAcc = []
    monthsAcc = []
    daysAcc = []
    for i in range(percCapacity.shape[0]):
        
        y = percCapacity[i]
        x = tx[i,1:]
        
        if len(y)==len(x):
            y = y[summerInds]
            x = x[summerInds]
            nn = np.where((~np.isnan(y)) & (~np.isnan(x)))[0]
            y = y[nn]
            x = x[nn]
            ytotal.extend(y)
            xtotal.extend(x)
            plantIdsAcc.extend(plantIds[i,summerInds])
            plantMeanTempsAcc.extend([np.nanmean(x)]*len(x))
            monthsAcc.extend(plantMonths[i,summerInds])
            daysAcc.extend(plantDays[i,summerInds])            
            
            for k in range(len(y)):
                if y[k] < 100:
                    outageBool.append(1)
                else:
                    outageBool.append(0)
        else:
            print(i)
    
    xtotal = np.array(xtotal)
    ytotal = np.array(ytotal)
    plantIdsAcc = np.array(plantIdsAcc)
    monthsAcc = np.array(monthsAcc)
    daysAcc = np.array(daysAcc)
    
    d = {'txSummer': xtotal, 'capacitySummer':ytotal, 'percCapacity':percCapacity, \
         'summerInds':summerInds, 'outagesBoolSummer':outageBool, 'plantIds':plantIdsAcc, \
         'plantMeanTemps':plantMeanTempsAcc, 'plantMonths':monthsAcc, 'plantDays':daysAcc}
    return d
