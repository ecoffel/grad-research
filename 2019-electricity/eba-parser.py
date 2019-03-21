
# -*- coding: utf-8 -*-
"""
Created on Wed Mar  6 15:09:30 2019

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

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDir = 'e:/data/'

months = range(6,10)

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
                # restrict to summer months
                if not int(datapt[0][4:6]) in months:
                    continue
                
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
            
            # remove 15 day mean (360 hr)
            tmpSmooth = pd.rolling_mean(curLineNew['dataSmooth'], 360)
            indNn = np.where(~np.isnan(tmpSmooth))[0]
            indNan = np.where(np.isnan(tmpSmooth))[0]
            curLineNew['dataSmooth'][indNn] = curLineNew['dataSmooth'][indNn] - tmpSmooth[indNn]
            curLineNew['dataSmooth'][indNan] = np.nan
                                        
            for h in range(0, 24):
                indH = np.where((curLineNew['hour'] == h) & (~np.isnan(curLineNew['dataSmooth'])))[0]
                curLineNew['dataSmooth'][indH] = curLineNew['dataSmooth'][indH] - np.nanmean(curLineNew['dataSmooth'][indH])
                
            
            eba.append(curLineNew)

#subgrids = {}
#
#subgrids['ERCO'] = {'genId':547, \
#                    }

# TX
#genId = 547
#intId = 548
#demId = 69 
#demFctId = 546

# ISNE
#genId = 474
#intId = 432
#demId = 73
#demFctId = 473 

# PJM
genId = 567
intId = 568
demId = 51
demFctId = 566

# CISO
#genId = 508
#intId = 509
#demId = 65
#demFctId = 507

# NYIS
#genId = 576
#intId = 577
#demId = 28
#demFctId = 575

if not 'uscrn' in locals():
    uscrnDir = '%s/USCRN' % dataDir
    
    # ISNE
    #uscrnStateList = ['ME', 'MA', 'CT', 'RI', 'NH', 'VT']
    
    # TX
    #uscrnStateList = ['TX']
    
    # NYIS
    #uscrnStateList = ['NY']
    
    # CISO
    #uscrnStateList = ['CA']
    
    # PJM
    uscrnStateList = ['OH', 'PA', 'NJ', 'DE', 'WV', 'VA', 'MD']

    uscrnListN = 0    
    uscrnList = []
    for year in range(2014, 2018+1):
        for state in uscrnStateList:
            tmp = glob.glob('%s/%d/CRNH0203-%d-%s*' % (uscrnDir, year, year, state))
            uscrnList.extend(tmp)
            if year == 2014:
                uscrnListN = len(tmp)
                
    for f in range(len(uscrnList)):
        uscrnList[f] = uscrnList[f].replace('//', '/')
        uscrnList[f] = uscrnList[f].replace('\\', '/')
    
    uscrn = {'year':[], 'month':[], 'day':[], 'hour':[], \
                      'station':[], 'lat':[], 'lon':[], 'temp':[], 'rh':[]}
    
    for cityPath in uscrnList:  
        print('loading %s...' % (cityPath))
        curUSCRN = el_readUSCRN.readUSCRN(cityPath)
        
        uscrn['station'].extend([curUSCRN['station']]*len(curUSCRN['year']))
        uscrn['lat'].extend([curUSCRN['lat']]*len(curUSCRN['year']))
        uscrn['lon'].extend([curUSCRN['lon']]*len(curUSCRN['year']))
        uscrn['year'].extend(curUSCRN['year'])
        uscrn['month'].extend(curUSCRN['month'])
        uscrn['day'].extend(curUSCRN['day'])
        uscrn['hour'].extend(curUSCRN['hour'])
        uscrn['temp'].extend(curUSCRN['temp'])
        uscrn['rh'].extend(curUSCRN['rh'])
    
    uscrn['wb'] = []
    for h in range(len(uscrn['hour'])):
        if uscrn['temp'][h] > 0 and uscrn['rh'][h] > 0:
            uscrn['wb'].append(el_wet_bulb.wetBulb(uscrn['temp'][h], uscrn['rh'][h]))
        else:
            uscrn['wb'].append(-9999)
            
    uscrn['station'] = np.array(uscrn['station'])
    uscrn['lat'] = np.array(uscrn['lat'])
    uscrn['lon'] = np.array(uscrn['lon'])
    uscrn['year'] = np.array(uscrn['year'])
    uscrn['month'] = np.array(uscrn['month'])
    uscrn['day'] = np.array(uscrn['day'])
    uscrn['hour'] = np.array(uscrn['hour'])
    uscrn['temp'] = np.array(uscrn['temp'])
    uscrn['rh'] = np.array(uscrn['rh'])
    uscrn['wb'] = np.array(uscrn['wb'])
    
    uscrn['temp'][uscrn['temp'] < -100] = np.nan
    uscrn['rh'][uscrn['rh'] < -100] = np.nan
    uscrn['wb'][uscrn['wb'] < -100] = np.nan

    
if not 'dailySeries' in locals():
    print('building daily electricity data...')
    dailySeries = {'year':[], 'month':[], 'day':[], 'tempData':[], 'rhData':[], 'wbData':[], \
                   'genData':[], 'intData':[], 'demData':[], 'demFctData':[]}
    
    lastDay = -1
    o = 0
    # loop through all obs from the uscrn data
    for year in np.unique(uscrn['year']):
        for month in np.unique(uscrn['month']):
        #   
            # select only summer
            if not month in months:
                continue

            for day in np.unique(uscrn['day']):

                # find matching TX generation data
                indGen = np.where((eba[genId]['year'] == year) & \
                               (eba[genId]['month'] == month) & \
                               (eba[genId]['day'] == day))[0]
                
                # and find TX interchange data
                indInt = np.where((eba[intId]['year'] == year) & \
                               (eba[intId]['month'] == month) & \
                               (eba[intId]['day'] == day))[0]
                
                # and find TX demand data
                indDem = np.where((eba[demId]['year'] == year) & \
                               (eba[demId]['month'] == month) & \
                               (eba[demId]['day'] == day))[0]
                
                # and find TX demand forecast data
                indDemFct = np.where((eba[demFctId]['year'] == year) & \
                               (eba[demFctId]['month'] == month) & \
                               (eba[demFctId]['day'] == day))[0]
                
                # and find matching wx obs
                indUSCRN = np.where((uscrn['year'] == year) & \
                                   (uscrn['month'] == month) & \
                                   (uscrn['day'] == day))[0]
                    
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
                    dailySeries['wbData'].append([])
                    
                    for h in range(0, 24):
                        # find all indices for current hour in current day
                        indUscrnCurHr = np.where(uscrn['hour'][indUSCRN] == h)[0]
                        # add regionally averaged T/RH to current day
                        if len(indUscrnCurHr) > .75*uscrnListN:
                            dailySeries['tempData'][-1].append(np.nanmean(uscrn['temp'][indUSCRN[indUscrnCurHr]]))
                            dailySeries['rhData'][-1].append(np.nanmean(uscrn['rh'][indUSCRN[indUscrnCurHr]]))
                            dailySeries['wbData'][-1].append(np.nanmean(uscrn['wb'][indUSCRN[indUscrnCurHr]]))
                        else:
                            dailySeries['tempData'][-1].append(np.nan)
                            dailySeries['rhData'][-1].append(np.nan)
                            dailySeries['wbData'][-1].append(np.nan)
    
    dailySeries['genData'] = np.array(dailySeries['genData'])
    dailySeries['intData'] = np.array(dailySeries['intData'])
    dailySeries['demData'] = np.array(dailySeries['demData'])
    dailySeries['demFctData'] = np.array(dailySeries['demFctData'])
    dailySeries['tempData'] = np.array(dailySeries['tempData'])
    dailySeries['rhData'] = np.array(dailySeries['rhData'])
    dailySeries['wbData'] = np.array(dailySeries['wbData'])
    
    dailySeries['tempData'][dailySeries['tempData']<-100] = np.nan
    dailySeries['rhData'][dailySeries['rhData']<-100] = np.nan
    dailySeries['wbData'][dailySeries['wbData']<-100] = np.nan


# find days above 95 percentile tx
dailyTx = np.nanmax(dailySeries['wbData'], axis=1)
intTx = []
genTx = []
demTx = []
demFctTx = []

dailyCoefsDiff = []
dailyCoefsInt = []

indTxRange = []

range1 = 0
range2 = 100
step = 10
for p in range(range1, range2, step):
    dailyTxP1 = np.nanpercentile(dailyTx, p)
    dailyTxP2 = np.nanpercentile(dailyTx, p+step)
    indTx = np.where((dailyTx >= dailyTxP1) & (dailyTx < dailyTxP2))[0]
    indTxRange.append(indTx)
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
    
    y = np.min(dailySeries['intData'][indTx], axis=1)
    x = dailyTx[indTx]
    nn = np.where((~np.isnan(y)) & (~np.isnan(x)))
    modelInt = sm.OLS(y[nn], x[nn]).fit()
    
    dailyCoefsDiff.append(modelDiff.params[0])
    dailyCoefsInt.append(modelInt.params[0])
    #print('dem = %.2f, gen = %.2f, diff = %.2f, p = %.2f, n = %d'%(modelDem.params[0], \
    #                                                    modelGen.params[0], modelDiff.params[0], modelDiff.pvalues[0], len(indTx)))

f, axs = plt.subplots(5,2,figsize=(5,7))
cnt = 0
for i in range(0,5):
    for j in range(0,2):
        axs[i,j].plot(np.nanmean(dailySeries['demData'][indTxRange[cnt]],axis=0)-np.nanmean(dailySeries['genData'][indTxRange[cnt]],axis=0))
        axs[i,j].plot([0, 25], [0, 0], '--k')
        axs[i,j].set_ylim(-500,800)
        cnt+=1
#    
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
plt.xlabel('Summer daily max Tw percentile')
plt.ylabel('Electricity anomaly (MWh)')
plt.legend()


plt.figure()
plt.plot(range(range1, range2, step), demTx-genTx, label='Demand - Generation')
plt.plot(range(range1, range2, step), intTx, label='Interchange')
plt.plot([0, 100], [0, 0], '--k')
plt.xticks(range(0, 110, 10))
plt.xlabel('Summer daily max Tw percentile')
plt.ylabel('Electricity anomaly (MWh)')
plt.legend()

plt.figure()
plt.plot(range(range1, range2, step), dailyCoefsDiff, label='Demand - Generation')
plt.plot(range(range1, range2, step), dailyCoefsInt, label='Interchange')
plt.plot([0, 100], [0, 0], '--k')
plt.xticks(range(0, 110, 10))
plt.xlabel('Summer daily max Tw percentile')
plt.ylabel('MWh / degree C')
plt.legend()



range1 = 0
range2 = 100
step = 10

eGen = np.reshape(dailySeries['genData'],[dailySeries['genData'].size, 1])
eDem = np.reshape(dailySeries['demData'],[dailySeries['demData'].size, 1])
eInt = np.reshape(dailySeries['intData'],[dailySeries['intData'].size, 1])
t = np.reshape(dailySeries['wbData'],[dailySeries['wbData'].size, 1])

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
plt.xlabel('Summer hourly Tw percentile')
plt.ylabel('MWh anomaly / degree C')
plt.xticks(range(range1, range2+10, 10))
plt.legend()




demDiff = []
genDiff = []
# loop over each day
for d in range(dailySeries['demData'].shape[0]):
    demDiff.append([])
    genDiff.append([])
    for i in range(1,24):
        demDiff[-1].append(dailySeries['demData'][d,i]-dailySeries['demData'][d,i-1])
        genDiff[-1].append(dailySeries['genData'][d,i]-dailySeries['genData'][d,i-1])
demDiff = np.array(demDiff)
genDiff = np.array(genDiff)

f, axs = plt.subplots(5,2,figsize=(5,7))
cnt = 0
for i in range(0,5):
    for j in range(0,2):
        axs[i,j].plot(np.nanmean(demDiff[indTxRange[cnt],:]-genDiff[indTxRange[cnt],:],axis=0))
        axs[i,j].plot([0, 25], [0, 0], '--k')
        axs[i,j].set_ylim(-150,150)
        cnt+=1

#f,ax = plt.subplots(3,4, figsize=(10,5))
#cnt=0
#for i in range(0,3):
#    for j in range(0,4):
#        
#        ax[i,j].plot(np.nanmean(demDiff[indTxRange[cnt],:],axis=0))
#        ax[i,j].plot(np.nanmean(genDiff[indTxRange[cnt],:],axis=0))
#        cnt+=1




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
for e in range(0, len(eba)):
    print(eba[e]['name'], e)
    
