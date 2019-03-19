
# -*- coding: utf-8 -*-
"""
Created on Wed Mar  6 15:09:30 2019

@author: Ethan
"""

import json
import el_readUSCRN
import el_cooling_tower_model
import matplotlib.pyplot as plt 
import numpy as np
import pandas as pd
import statsmodels.api as sm
import math
import sys

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDir = 'e:/data/'

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
            curLineNew['data'] = []
            
            for datapt in curLine['data']:
                curLineNew['year'].append(int(datapt[0][0:4]))
                curLineNew['month'].append(int(datapt[0][4:6]))
                curLineNew['day'].append(int(datapt[0][6:8]))
                curLineNew['hour'].append(int(datapt[0][9:11]))
                if not datapt[1] == None:
                    curLineNew['data'].append(float(datapt[1]))
                else:
                    curLineNew['data'].append(np.nan)
                    
            curLineNew['year'] = np.array(curLineNew['year'])
            curLineNew['month'] = np.array(curLineNew['month'])
            curLineNew['day'] = np.array(curLineNew['day'])
            curLineNew['hour'] = np.array(curLineNew['hour'])
            curLineNew['data'] = np.array(curLineNew['data'])
            curLineNew['dataSmooth'] = curLineNew['data'].copy()
            
            # remove monthly mean (720 hr)
            tmpSmooth = pd.rolling_mean(curLineNew['dataSmooth'], 720)
            indNn = np.where(~np.isnan(tmpSmooth))[0]
            indNan = np.where(np.isnan(tmpSmooth))[0]
            curLineNew['dataSmooth'][indNn] = curLineNew['dataSmooth'][indNn] - tmpSmooth[indNn]
            curLineNew['dataSmooth'][indNan] = np.nan
                                        
            for h in range(0, 24):
                indH = np.where((curLineNew['hour'] == h) & (~np.isnan(curLineNew['dataSmooth'])))[0]
                curLineNew['dataSmooth'][indH] = curLineNew['dataSmooth'][indH] - np.nanmean(curLineNew['dataSmooth'][indH])
                
            
            eba.append(curLineNew)

# TX
genId = 547
intId = 548
demId = 69 
demFctId = 546


# ISNE
#genId = 474
#intId = 432
#demId = 73
#demFctId = 473 

# CISO
#genId = 508
#intId = 509
#demId = 65
#demFctId = 507

if not 'uscrn' in locals():
    uscrnList = ['CRNH0203-%d-TX_Austin_33_NW', 'CRNH0203-%d-TX_Bronte_11_NNE', 'CRNH0203-%d-TX_Edinburg_17_NNE', \
                 'CRNH0203-%d-TX_Monahans_6_ENE', 'CRNH0203-%d-TX_Muleshoe_19_S', 'CRNH0203-%d-TX_Palestine_6_WNW', \
                 'CRNH0203-%d-TX_Panther_Junction_2_N', 'CRNH0203-%d-TX_Port_Aransas_32_NNE']
    
#    uscrnList = ['CRNH0203-%d-ME_Limestone_4_NNW', 'CRNH0203-%d-ME_Old_Town_2_W', 'CRNH0203-%d-NH_Durham_2_SSW']

#    uscrnList = ['CRNH0203-%d-CA_Bodega_6_WSW', 'CRNH0203-%d-CA_Fallbrook_5_NE', 'CRNH0203-%d-CA_Merced_23_WSW', \
#                 'CRNH0203-%d-CA_Redding_12_WNW', 'CRNH0203-%d-CA_Santa_Barbara_11_W', 'CRNH0203-%d-CA_Stovepipe_Wells_1_SW', \
#                 'CRNH0203-%d-CA_Yosemite_Village_12_W']                 

    uscrn = {'year':[], 'month':[], 'day':[], 'hour':[], \
                      'station':[], 'lat':[], 'lon':[], 'temp':[], 'rh':[]}
    
    for cityPath in uscrnList:
        
        for year in range(2015, 2018+1):    
            curCity = cityPath % year
            print('loading %s for %d...' % (curCity, year))
            filePath = '%s/USCRN/%d/%s.txt' % (dataDir, year, curCity)
            curUSCRN = el_readUSCRN.readUSCRN(filePath)
            
            uscrn['station'].extend([curUSCRN['station']]*len(curUSCRN['year']))
            uscrn['lat'].extend([curUSCRN['lat']]*len(curUSCRN['year']))
            uscrn['lon'].extend([curUSCRN['lon']]*len(curUSCRN['year']))
            uscrn['year'].extend(curUSCRN['year'])
            uscrn['month'].extend(curUSCRN['month'])
            uscrn['day'].extend(curUSCRN['day'])
            uscrn['hour'].extend(curUSCRN['hour'])
            uscrn['temp'].extend(curUSCRN['temp'])
            uscrn['rh'].extend(curUSCRN['rh'])
        
    uscrn['station'] = np.array(uscrn['station'])
    uscrn['lat'] = np.array(uscrn['lat'])
    uscrn['lon'] = np.array(uscrn['lon'])
    uscrn['year'] = np.array(uscrn['year'])
    uscrn['month'] = np.array(uscrn['month'])
    uscrn['day'] = np.array(uscrn['day'])
    uscrn['hour'] = np.array(uscrn['hour'])
    uscrn['temp'] = np.array(uscrn['temp'])
    uscrn['rh'] = np.array(uscrn['rh'])
    
    
    
if not 'dailySeries' in locals():
    print('building daily electricity data...')
    dailySeries = {'year':[], 'month':[], 'day':[], 'tempData':[], 'rhData':[], \
                   'genData':[], 'intData':[], 'demData':[], 'demFctData':[]}
    
    lastDay = -1
    o = 0
    # loop through all obs from the uscrn data
    while o < len(uscrn['day']):
    
        # select only summer
        if not uscrn['month'][o] in [6, 7, 8, 9]:
            o += 1
            continue
        
        if lastDay == -1: 
            lastDay = uscrn['day'][o]
        
        # we are on the last hour in the current day
        if uscrn['day'][o] != lastDay:
            lastDay = uscrn['day'][o]
            
            # find matching TX generation data
            indGen = np.where((eba[genId]['year'] == uscrn['year'][o-1]) & \
                           (eba[genId]['month'] == uscrn['month'][o-1]) & \
                           (eba[genId]['day'] == uscrn['day'][o-1]))[0]
            
            # and find TX interchange data
            indInt = np.where((eba[intId]['year'] == uscrn['year'][o-1]) & \
                           (eba[intId]['month'] == uscrn['month'][o-1]) & \
                           (eba[intId]['day'] == uscrn['day'][o-1]))[0]
            
            # and find TX demand data
            indDem = np.where((eba[demId]['year'] == uscrn['year'][o-1]) & \
                           (eba[demId]['month'] == uscrn['month'][o-1]) & \
                           (eba[demId]['day'] == uscrn['day'][o-1]))[0]
            
            # and find TX demand forecast data
            indDemFct = np.where((eba[demFctId]['year'] == uscrn['year'][o-1]) & \
                           (eba[demFctId]['month'] == uscrn['month'][o-1]) & \
                           (eba[demFctId]['day'] == uscrn['day'][o-1]))[0]
            
            # and find matching wx obs
            indUSCRN = np.where((uscrn['year'] == uscrn['year'][o-1]) & \
                               (uscrn['month'] == uscrn['month'][o-1]) & \
                               (uscrn['day'] == uscrn['day'][o-1]))[0]
            
            # for all complete days
            if len(indGen) == 24 and len(indInt) == 24 and len(indDem) == 24 and len(indDemFct) == 24:
                #print('processed %d/%d/%d'%(uscrn[-1]['year'][o-1], uscrn[-1]['month'][o-1], uscrn[-1]['day'][o-1]))
                dailySeries['genData'].append(eba[genId]['dataSmooth'][indGen])
                dailySeries['intData'].append(eba[intId]['dataSmooth'][indInt])
                dailySeries['demData'].append(eba[demId]['dataSmooth'][indDem])
                dailySeries['demFctData'].append(eba[demFctId]['dataSmooth'][indDemFct])
                
                # average uscrn data for each hour of current day across regional cities
                
                # add list for current day
                dailySeries['tempData'].append([])
                dailySeries['rhData'].append([])
                
                for h in range(0, 24):
                    # find all indices for current hour in current day
                    indUscrnCurHr = np.where(uscrn['hour'][indUSCRN] == h)[0]
                    
                    # add regionally averaged T/RH to current day
                    if len(indUscrnCurHr) == len(uscrnList):
                        dailySeries['tempData'][-1].append(np.nanmean(uscrn['temp'][indUSCRN[indUscrnCurHr]]))
                        dailySeries['rhData'][-1].append(np.nanmean(uscrn['rh'][indUSCRN[indUscrnCurHr]]))
                    else:
                        dailySeries['tempData'][-1].append(np.nan)
                        dailySeries['rhData'][-1].append(np.nan)
        o += 1
    
    dailySeries['genData'] = np.array(dailySeries['genData'])
    dailySeries['intData'] = np.array(dailySeries['intData'])
    dailySeries['demData'] = np.array(dailySeries['demData'])
    dailySeries['demFctData'] = np.array(dailySeries['demFctData'])
    dailySeries['tempData'] = np.array(dailySeries['tempData'])
    dailySeries['rhData'] = np.array(dailySeries['rhData'])
    
    dailySeries['tempData'][dailySeries['tempData']<-100] = np.nan
    dailySeries['rhData'][dailySeries['rhData']<-100] = np.nan


# find days above 95 percentile tx
dailyTx = np.nanmax(dailySeries['tempData'], axis=1)
intTx = []
genTx = []
demTx = []
demFctTx = []

range1 = 0
range2 = 100
step = 5
for p in range(range1, range2, step):
    dailyTxP1 = np.nanpercentile(dailyTx, p)
    dailyTxP2 = np.nanpercentile(dailyTx, p+step)
    indTx = np.where((dailyTx >= dailyTxP1) & (dailyTx < dailyTxP2))[0]
    intTx.append(np.min(np.nanmean(dailySeries['intData'][indTx], axis = 0)))
    genTx.append(np.max(np.nanmean(dailySeries['genData'][indTx], axis = 0)))
    demTx.append(np.max(np.nanmean(dailySeries['demData'][indTx], axis = 0)))
    demFctTx.append(np.max(np.nanmean(dailySeries['demFctData'][indTx], axis = 0)))
    
    y = np.max(dailySeries['demData'][indTx], axis=1)
    x = dailyTx[indTx]
    nn = np.where((~np.isnan(y)) & (~np.isnan(x)))
    modelDem = sm.OLS(y[nn], x[nn]).fit()
    
    y = np.max(dailySeries['genData'][indTx], axis=1)
    x = dailyTx[indTx]
    nn = np.where((~np.isnan(y)) & (~np.isnan(x)))
    modelGen = sm.OLS(y[nn], x[nn]).fit()
    
    y = np.max(dailySeries['demData'][indTx]-dailySeries['genData'][indTx], axis=1)
    x = dailyTx[indTx]
    nn = np.where((~np.isnan(y)) & (~np.isnan(x)))
    modelDiff = sm.OLS(y[nn], x[nn]).fit()
    print('dem = %.2f, gen = %.2f, diff = %.2f, p = %.2f, n = %d'%(modelDem.params[0], \
                                                        modelGen.params[0], modelDiff.params[0], modelDiff.pvalues[0], len(indTx)))

intTx = np.array(intTx)
genTx = np.array(genTx)
demTx = np.array(demTx)
demFctTx = np.array(demFctTx)

plt.figure()
plt.plot(range(range1, range2, step), demTx, label='Demand')
plt.plot(range(range1, range2, step), demFctTx, label='Demand Forecast')
plt.plot(range(range1, range2, step), genTx, label='Generation')
plt.plot(range(range1, range2, step), intTx, label='Interchange')
plt.plot([0, 100], [0, 0], '--k')
plt.xticks(range(0, 110, 10))
plt.xlabel('Summer Tx percentile')
plt.ylabel('Electricity anomaly (MWh)')
plt.legend()


range1 = 0
range2 = 100
step = 2

eGen = np.reshape(dailySeries['genData'],[dailySeries['genData'].size, 1])
eDem = np.reshape(dailySeries['demData'],[dailySeries['demData'].size, 1])
eInt = np.reshape(dailySeries['intData'],[dailySeries['intData'].size, 1])
t = np.reshape(dailySeries['tempData'],[dailySeries['tempData'].size, 1])

nn = np.where((~np.isnan(eGen)) & (~np.isnan(t)) & (~np.isnan(eDem)) & (~np.isnan(eInt)))
eGen = eGen[nn]
eDem = eDem[nn]
eInt = eInt[nn]
t = t[nn]

coefsDem = []
coefsGen = []
coefsInt = []
coefsDiff = []

for p in np.arange(range1, range2, step):
    hourlyTempP1 = np.nanpercentile(t, p)
    hourlyTempP2 = np.nanpercentile(t, p+step)

    indTx = np.where((t >= hourlyTempP1) & (t < hourlyTempP2))

    y = eGen[indTx]
    x = t[indTx]
    modelGen = sm.OLS(y, x).fit()
    coefsGen.append(modelGen.params[0])
    
    y = eDem[indTx]
    x = t[indTx]
    modelDem = sm.OLS(y, x).fit()
    coefsDem.append(modelDem.params[0])
    
    y = eInt[indTx]
    x = t[indTx]
    modelInt = sm.OLS(y, x).fit()
    coefsInt.append(modelInt.params[0])
    
    y = eDem[indTx] - eGen[indTx]
    x = t[indTx]
    modelDiff = sm.OLS(y, x).fit()
    coefsDiff.append(modelDiff.params[0])
    #print('gen = %.2f, dem = %.2f, diff = %.2f, p = %.2f, n = %d'%(modelGen.params[0], modelDem.params[0], modelDiff.params[0], modelDiff.pvalues[0], len(y)))

plt.figure()
plt.plot(range(range1, range2, step), coefsDiff, label = 'Demand - Generation')
plt.plot(range(range1, range2, step), coefsInt, label = 'Interchange')
plt.plot([0, 100], [0, 0], '--k')
plt.xlabel('Summer hourly temperature percentile')
plt.ylabel('MWh anomaly / degree C')
plt.xticks(range(range1, range2+10, 10))
plt.legend()


plt.figure()
plt.plot(range(range1, range2, step), coefsGen)
plt.plot(range(range1, range2, step), coefsDem)


print('done')
sys.exit()



#eff = []
#curtail = []
#
#for i in t99Ind:
#    (e, c) = el_cooling_tower_model.coolingTowerEfficiency(tempNn[i], rhNn[i], t99, rh99Mean)
#    eff.append(e)
#    curtail.append(c)
#
#
#
#
for e in range(0, 100):#len(eba)):
    print(eba[e]['name'], e)
    
