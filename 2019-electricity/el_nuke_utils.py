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
    fileNameCDD = ''
    
    if wxdata == 'cpc':
        fileName = 'nuke-tx-cpc.csv'
        fileNameCDD = 'nuke-cdd-cpc.csv'
    elif wxdata == 'era':
        fileName = 'nuke-tx-era.csv'
        fileNameCDD = 'nuke-cdd-era.csv'
    elif wxdata == 'ncep':
        fileName = 'nuke-tx-ncep.csv'
        fileNameCDD = 'nuke-cdd-ncep.csv'
    elif wxdata == 'all':
        fileName = ['nuke-tx-cpc.csv', 'nuke-tx-era.csv', 'nuke-tx-ncep.csv']
        fileNameCDD = ['nuke-cdd-cpc.csv', 'nuke-cdd-era.csv', 'nuke-cdd-ncep.csv']
        
        
    tx = []
    cdd = []
    
    if wxdata == 'all':
        tx1 = np.genfromtxt(fileName[0], delimiter=',')    
        tx2 = np.genfromtxt(fileName[1], delimiter=',')    
        tx3 = np.genfromtxt(fileName[2], delimiter=',')    
        
        tx = tx1.copy()
        for i in range(0,tx1.shape[0]):
            for j in range(1,tx1.shape[1]):
                tx[i,j] = np.nanmean([tx1[i,j], tx2[i,j], tx3[i,j]])
        
        
        cdd1 = np.genfromtxt(fileNameCDD[0], delimiter=',')    
        cdd2 = np.genfromtxt(fileNameCDD[1], delimiter=',')    
        cdd3 = np.genfromtxt(fileNameCDD[2], delimiter=',')    
        
        cdd = cdd1.copy()
        for i in range(0,cdd1.shape[0]):
            for j in range(1,cdd1.shape[1]):
                cdd[i,j] = np.nanmean([cdd1[i,j], cdd2[i,j], cdd3[i,j]])
        
    else:
        tx = np.genfromtxt(fileName, delimiter=',')
        cdd = np.genfromtxt(fileNameCDD, delimiter=',')
        
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
    return {'tx':np.array(tx), 'cdd':np.array(cdd), 'ids':np.array(ids)}





def accumulateNukeWxDataPlantLevel(eba, nukeMatchData):
    
    summerInds = np.where((eba[0]['month'] == 7) | (eba[0]['month'] == 8))[0]
    
    tx = nukeMatchData['tx']
    cdd = nukeMatchData['cdd']
    ids = nukeMatchData['ids']
    
    plantPercCapacity = []
    plantTx = []
    plantCDD = []
    
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
        
        curPC = plantPercCapacity[i]
        curTx = tx[i,1:]
        curCDD = cdd[i,1:]
        
        if len(curPC)==len(curTx):
            curPC = curPC[summerInds]
            curTx = curTx[summerInds]
            curCDD = curCDD[summerInds]
            nn = np.where((~np.isnan(curPC)) & (~np.isnan(curTx)) & (~np.isnan(curCDD)))[0]
            curPC = curPC[nn]
            curTx = curTx[nn]
            curCDD = curCDD[nn]
            
            finalPlantPercCapacity.append(curPC)
            plantTx.append(curTx)
            plantCDD.append(curCDD)
    
    plantTx = np.array(plantTx)
    plantCDD = np.array(plantCDD)
    finalPlantPercCapacity = np.array(finalPlantPercCapacity)
    
    d = {'txSummer': plantTx, 'cddSummer':plantCDD, \
         'capacitySummer':finalPlantPercCapacity, \
         'summerInds':summerInds, \
         'plantMonths':plantMonths, 'plantDays':plantDays}
    return d






def accumulateNukeWxData(eba, nukeMatchData):
    
    tx = nukeMatchData['tx']
    cdd = nukeMatchData['cdd']
    ids = nukeMatchData['ids']
    
    # for averaging cdd and tx
    smoothingLen = 4
    
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
    
    plantTxTotal = []
    plantTxAvgTotal = []
    plantCDDAccTotal = []
    plantCapTotal = []
    plantIdsAcc = []
    plantMeanTempsAcc = []
    monthsAcc = []
    daysAcc = []
    
    # loop over all plants
    for i in range(percCapacity.shape[0]):
        
        plantCap = percCapacity[i]
        plantTx = tx[i,1:]
        plantCDD = cdd[i,1:]
        
        # accumulate weekly cdd
        
        plantCDDSmooth = []
        for d in range(len(plantCDD)):
            if d < (smoothingLen-1):
                plantCDDSmooth.append(np.nan)
            else:
                plantCDDSmooth.append(np.nansum(plantCDD[d-(smoothingLen-1):d+1]))
            
        plantCDDSmooth = np.array(plantCDDSmooth)
        
        
        plantTxAvg = []
        for d in range(tx.shape[1]):
            if d > smoothingLen-1:
                plantTxAvg.append(np.nanmean(tx[i,d-(smoothingLen-1):d+1]))
            else:
                plantTxAvg.append(np.nan)
        
        plantTxAvg = np.array(plantTxAvg)
        
        if len(plantTx)==len(plantCap):
            plantCap = plantCap[summerInds]
            plantTx = plantTx[summerInds]
            plantTxAvg = plantTxAvg[summerInds]
            plantCDD = plantCDD[summerInds]
            plantCDDSmooth = plantCDDSmooth[summerInds]
            
            nn = np.where((~np.isnan(plantCap)) & (~np.isnan(plantTx)) & (~np.isnan(plantTxAvg)) \
                          & (~np.isnan(plantCDD)) & (~np.isnan(plantCDDSmooth)))[0]
            
            plantCap = plantCap[nn]
            plantTx = plantTx[nn]
            plantTxAvg = plantTxAvg[nn]
            plantCDD = plantCDD[nn]
            plantCDDSmooth = plantCDDSmooth[nn]
            
            plantCapTotal.extend(plantCap)
            plantTxTotal.extend(plantTx)
            plantTxAvgTotal.extend(plantTxAvg)
            plantCDDAccTotal.extend(plantCDDSmooth)
            
            plantIdsAcc.extend(plantIds[i,summerInds])
            plantMeanTempsAcc.extend([np.nanmean(plantTx)]*len(plantTx))
            monthsAcc.extend(plantMonths[i,summerInds])
            daysAcc.extend(plantDays[i,summerInds])            
            
            for k in range(len(plantCap)):
                if plantCap[k] < 100:
                    outageBool.append(1)
                else:
                    outageBool.append(0)
    
    plantTxTotal = np.array(plantTxTotal)
    plantTxAvgTotal = np.array(plantTxAvgTotal)
    plantCDDAccTotal = np.array(plantCDDAccTotal)
    plantCapTotal = np.array(plantCapTotal)
    plantIdsAcc = np.array(plantIdsAcc)
    monthsAcc = np.array(monthsAcc)
    daysAcc = np.array(daysAcc)
    
    d = {'txSummer': plantTxTotal, 'txAvgSummer': plantTxAvgTotal, 'cddSummer': plantCDDAccTotal, \
         'capacitySummer':plantCapTotal, 'percCapacity':percCapacity, \
         'summerInds':summerInds, 'outagesBoolSummer':outageBool, 'plantIds':plantIdsAcc, \
         'plantMeanTemps':plantMeanTempsAcc, 'plantMonths':monthsAcc, 'plantDays':daysAcc}
    return d
