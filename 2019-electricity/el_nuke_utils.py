# -*- coding: utf-8 -*-
"""
Created on Mon Apr  1 09:47:36 2019

@author: Ethan
"""

import json
import numpy as np

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDir = 'e:/data/'

useEra = True
plotFigs = False

months = range(1,13)

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
                # restrict to summer months
                if not int(datapt[0][4:6]) in months or \
                    int(datapt[0][0:4]) > 2018:
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

def loadWxData(eba, useEra):
    # read tw time series
    fileName = 'nuke-tx-era.csv'
    if not useEra:
        fileName = 'nuke-tx-cpc.csv'
        
    tx = np.genfromtxt(fileName, delimiter=',')
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


def accumulateNukeWxData(eba, tx, ids):
    
    summerInds = np.where((eba[0]['month'] == 7) | (eba[0]['month'] == 8))[0]
    
    percCapacity = []
    totalOut = []
    totalCap = []
    for i in range(ids.shape[0]):
        out = np.array(eba[ids[i,0]]['data'])
        cap = np.array(eba[ids[i,1]]['data'])     
        
        if len(out) == 4383 and len(cap) == 4383:
            
            # calc the plant operating capacity (% of total normal capacity)
            percCapacity.append(100*(1-(out/cap)))
            if len(totalOut) == 0:
                totalOut = out
                totalCap = cap
            else:
                totalOut += out
                totalCap += cap
    
    percCapacity = np.array(percCapacity)  
    
    outageBool = []
    
    xtotal = []
    ytotal = []
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
            
            for k in range(len(y)):
                if y[k] < 100:
                    outageBool.append(1)
                else:
                    outageBool.append(0)
        else:
            print(i)
    
    xtotal = np.array(xtotal)
    ytotal = np.array(ytotal)
    
    d = {'txSummer': xtotal, 'capacitySummer':ytotal, 'percCapacity':percCapacity, \
         'summerInds':summerInds, 'outagesBool':outageBool}
    return d
