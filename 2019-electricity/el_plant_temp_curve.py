# -*- coding: utf-8 -*-
"""
Created on Sun Mar 31 16:58:58 2019

@author: Ethan
"""

# -*- coding: utf-8 -*-
"""
Created on Thu Mar 21 11:25:12 2019

@author: Ethan
"""


import json
import el_readUSCRN
import el_wet_bulb
import el_cooling_tower_model
from matplotlib import font_manager
import seaborn as sns
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

useEra = True
plotFigs = False


useEra = True
plotFigs = False

def normalize(v):
    nn = np.where(~np.isnan(v))[0]
    norm = np.linalg.norm(v[nn])
    newv = v.copy()
    if norm == 0: 
       return newv
   
    return newv / float(norm)
    

monthsList = ['January', 'February', 'March', 'April', 'May', 'June', \
              'July', 'August', 'September', 'October', 'November', 'December']

def getMonth(m):
    return monthsList.index(m)+1

def getEUCountryCode(s):
    euCodes = ['AL', 'AD', 'AM', 'AT', 'BY', 'BE', 'BA', 'BG', 'CH', 'CY', 'CZ', 'DE', \
               'DK', 'EE', 'ES', 'FO', 'FI', 'FR', 'GB', 'GE', 'GI', 'GR', 'HU', 'HR', \
               'IE', 'IS', 'IT', 'LT', 'LU', 'LV', 'MC', 'MK', 'MT', 'NO', 'NL', 'PO', \
               'PT', 'RO', 'SE', 'SI', 'SK', 'SM', 'VA']
    for c in euCodes:
        if c in s:
            return c

if not 'yearsEntsoe' in locals():
    yearsEntsoe = []
    monthsEntsoe = []
    daysEntsoe = []
    countriesEntsoe = []
    actualCapacityEntsoe = []
    normalCapacityEntsoe = []
    for year in range(2015, 2019):
        print('loading %d'%year)
        for month in range(1, 13):
            with open('%s/ecoffel/data/projects/electricity/entsoe/OutagesPU/%d_%d_OutagesPU.csv' % (dataDir, year, month), 'r', encoding='utf-16') as f:
                n = 0
                for line in f:
                    if n == 0:
                        n += 1
                        continue
                    
                    lineParts = line.split('\t')
                    
                    if len(lineParts) < 20:
                        continue
                    
                    if lineParts[8] != 'Forced':
                        continue
                    
                    if 'Hydro' in lineParts[15] or \
                        'hydro' in lineParts[15] or \
                        'Wind' in lineParts[15] or \
                        'wind' in lineParts[15]:
                        continue
                    
                    yearsEntsoe.append(int(lineParts[0]))
                    monthsEntsoe.append(int(lineParts[1]))
                    daysEntsoe.append(int(lineParts[2]))
                    countriesEntsoe.append(getEUCountryCode(lineParts[12]))
                    actualCapacityEntsoe.append(float(lineParts[19]))
                    normalCapacityEntsoe.append(float(lineParts[18]))
                    
    yearsEntsoe = np.array(yearsEntsoe)
    monthsEntsoe = np.array(monthsEntsoe)
    daysEntsoe = np.array(daysEntsoe)
    countriesEntsoe = np.array(countriesEntsoe)
    actualCapacityEntsoe = np.array(actualCapacityEntsoe)
    normalCapacityEntsoe = np.array(normalCapacityEntsoe)

fileName = 'country-tx-cpc-2015-2018.csv'
if useEra:
    fileName = 'country-tx-era-2015-2018.csv'

countryList = []
with open(fileName, 'r') as f:
    i = 0
    for line in f:
        if i > 3:
            parts = line.split(',')
            countryList.append(parts[0])
        i += 1
countryTxData = np.genfromtxt(fileName, delimiter=',', skip_header=1)
countryYearData = countryTxData[0,1:]
countryMonthData = countryTxData[1,1:]
countryDayData = countryTxData[2,1:]
countryTxData = countryTxData[3:,1:]

if not 'finalTx' in locals():
    finalTx = []
    finalOutages = []
    finalOutagesBool = []
    finalOutagesCount = []
    finalOutageInds = []
    
    for c in range(len(countryList)):
        get_inds = lambda x, xs: [i for (y, i) in zip(xs, range(len(xs))) if x == y]
        indCountryEntsoe = get_inds(countryList[c], countriesEntsoe)
    
        finalTx.append([])
        finalOutages.append([])
        finalOutageInds.append([])
        finalOutagesBool.append([])
        finalOutagesCount.append([])
        for i in range(len(countryTxData[c])):
            curYear = countryYearData[i]
            curMonth = countryMonthData[i]
            curDay = countryDayData[i]
            
            curDayIndEntsoe = np.where((yearsEntsoe == curYear) & (monthsEntsoe == curMonth) & \
                                 (daysEntsoe == curDay))[0]
            
            curDayIndEntsoe = np.intersect1d(curDayIndEntsoe, indCountryEntsoe)
            
            if len(curDayIndEntsoe) > 0:
                perc = []
                for p in curDayIndEntsoe:    
                    perc.append(actualCapacityEntsoe[p] / normalCapacityEntsoe[p])
                
                finalOutages[c].append(np.nanmean(perc))
                finalOutagesBool[c].append(1)
            else:
                finalOutages[c].append(0)
                finalOutagesBool[c].append(0)
            
            finalOutagesCount[c].append(len(curDayIndEntsoe))
            finalTx[c].append(countryTxData[c,i])

        
        outageInd = np.where(np.array(finalOutages[c]) > 0)[0]
        finalOutageInds[c].extend(outageInd)
    
    finalTx = np.array(finalTx)
    finalOutages = np.array(finalOutages)
    finalOutagesBool = np.array(finalOutagesBool)
    finalOutagesCount = np.array(finalOutagesCount)
    finalOutageInds = np.array(finalOutageInds)
                
#    for c in range(finalOutages.shape[0]):
#        finalOutages[c,:] = finalOutages[c,:]-pd.rolling_mean(finalOutages[c,:], 15)
##        normalize(finalOutages[c,:])


txAll = []
outageAll = []
outageBoolAll = []
outageCountAll = []

for c in range(finalOutages.shape[0]):
    summerInds = np.where((countryMonthData > 6) & (countryMonthData < 9))[0]
#    inds = np.intersect1d(summerInds, finalOutageInds[c])
    
    inds = summerInds
    curTx = finalTx[c,inds]
    curOutage = finalOutages[c,inds]
    curOutageBool = finalOutagesBool[c,inds]
    curOutageCount = finalOutagesCount[c,inds]

    X = sm.add_constant(curTx)
    model = sm.OLS(normalize(curOutage), X).fit() 
    
    # outages reported for this country
    if np.nansum(curOutageCount) > 0:
        txAll.extend(curTx)
        outageAll.extend(curOutage)
        outageBoolAll.extend(curOutageBool)
        outageCountAll.extend(normalize(np.array(curOutageCount)))
        if len(np.where(curOutage>0)[0]) > 20:
            print('c = %d, country = %s, slope = %0.2f, p = %.02f' % (c, countryList[c], model.params[1]*1000, model.pvalues[1]))
    #            plt.figure()
    #            plt.scatter(curTx,normalize(curOutage))
    #            plt.title('c = %s'%countryList[c])
    #            plt.draw()
            

xtotalEu = np.array(txAll)
ytotalEu = 100 - (100*np.array(outageAll))





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
        percOutage.append(100*(1-out/cap))
        if len(totalOut) == 0:
            totalOut = out
            totalCap = cap
        else:
            totalOut += out
            totalCap += cap

percOutage = np.array(percOutage)
percOutageMean = np.nanmean(percOutage, axis=0)

summerInds = np.where((eba[0]['month'] == 7) | (eba[0]['month'] == 8))[0]

xtotalNuke = []
ytotalNuke = []
for i in range(percOutage.shape[0]):
    
    y = percOutage[i]
    x = tw[i,1:]
    
    if len(y)==len(x):
        y = y[summerInds]
        x = x[summerInds]
        nn = np.where((~np.isnan(y)) & (~np.isnan(x)) & (y < 100))[0]
        y = y[nn]
        x = x[nn]
        ytotalNuke.extend(y)
        xtotalNuke.extend(x)
    else:
        print(i)


xtotalNuke = np.array(xtotalNuke)
ytotalNuke = np.array(ytotalNuke)



xtotal = []
xtotal.extend(xtotalNuke)
xtotal.extend(xtotalEu)
xtotal = np.array(xtotal)

ytotal = []
ytotal.extend(ytotalNuke)
ytotal.extend(ytotalEu)
ytotal = np.array(ytotal)

df = pd.DataFrame({'x':xtotal, 'y':ytotal})


plt.figure()
plt.xlim([15,42])
plt.ylim([-5,105])
sns.regplot(x='x', y='y', data=df, order=3, \
            scatter_kws={"color": [.5, .5, .5], "facecolor":[.75, .75, .75], "s":30}, \
            line_kws={"color": [234/255., 49/255., 49/255.]})
plt.xlim([15,44])



