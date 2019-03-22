# -*- coding: utf-8 -*-
"""
Created on Thu Mar 21 11:25:12 2019

@author: Ethan
"""


import json
import el_readUSCRN
import el_wet_bulb
import el_cooling_tower_model
import matplotlib.pyplot as plt 
import numpy as np
import pandas as pd
import glob
import statsmodels.api as sm
import math
import sys
import csv

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDir = 'e:/data/'

months = range(1,13)

if not 'eba' in locals():
    print('loading eba...')
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


# read tw time series
tw = np.genfromtxt('nuke-tx-era.csv', delimiter=',')
ids = []
for i in range(tw.shape[0]):
    # current facility outage name
    outageId = int(tw[i,0])
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

ids = np.array(ids)
percOutage = []
totalOut = []
totalCap = []
for i in range(ids.shape[0]):
    out = np.array(eba[ids[i,0]]['data'])
    cap = np.array(eba[ids[i,1]]['data'])
    
    
    if len(out) == 4383 and len(cap) == 4383:
        percOutage.append(out/cap)    
        if len(totalOut) == 0:
            totalOut = out
            totalCap = cap
        else:
            totalOut += out
            totalCap += cap

summerInds = np.where((eba[0]['month'] >= 6) & (eba[0]['month'] <= 9))[0]

percOutage = np.array(percOutage)
xtotal = []
ytotal = []
for i in range(percOutage.shape[0]):
    
    y = percOutage[i]
    x = tw[i,1:]
    
    if len(y)==len(x):
        y = y[summerInds]
        x = x[summerInds]
        nn = np.where((~np.isnan(y)) & (~np.isnan(x)) & (y > 0) & (x > 305))[0]
        y = y[nn]
        x = x[nn]
        ytotal.extend(y)
        xtotal.extend(x)
#        if len(y) > 1000:
#            model = sm.OLS(y, x).fit()
#            print(model.params[0],model.pvalues[0])

plt.figure()
plt.scatter(xtotal,ytotal)
X = sm.add_constant(xtotal)
model = sm.OLS(ytotal, X).fit()
z = [model.params[1], model.params[0]]
p = np.poly1d(z)
plt.plot(range(int(np.nanmin(xtotal)),int(np.nanmax(xtotal))), p(range(int(np.nanmin(xtotal)),int(np.nanmax(xtotal)))), "r--")



#i = 0
#with open('nuke-lat-lon.csv', 'w') as f:
#    csvWriter = csv.writer(f)    
#    for pp in eba:
#        if 'lat' in pp.keys() and 'Nuclear generating capacity outage' in pp['name'] and not 'for generator' in pp['name']:
#            print(pp['name'])
#            csvWriter.writerow([i, float(pp['lat']), float(pp['lon'])])
#        i += 1

