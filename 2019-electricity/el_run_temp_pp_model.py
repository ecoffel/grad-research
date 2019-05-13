# -*- coding: utf-8 -*-
"""
Created on Thu May  2 16:56:07 2019

@author: Ethan
"""

import numpy as np
import pandas as pd
from sklearn import linear_model
import statsmodels.api as sm
import matplotlib.pyplot as plt
import el_temp_pp_model
import el_load_global_plants

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDir = 'e:/data/'

plotFigs = False

#regr, mdl = el_temp_pp_model.buildLinearTempPPModel()
zPoly3, pPoly3 = el_temp_pp_model.buildPoly3TempPPModel()

#globalPlants = el_load_global_plants.loadGlobalPlants()

yearRange = [1981, 2018]
# load wx data for global plants
fileName = 'entsoe-nuke-pp-tx-era.csv'

#fileName = 'entnsoe-nuke-pp-rcp85-tx-cmip5-canesm2-2020-2050.csv'

plantList = []
with open(fileName, 'r') as f:
    i = 0
    for line in f:
        if i > 3:
            parts = line.split(',')
            plantList.append(parts[0])
        i += 1
plantTxData = np.genfromtxt(fileName, delimiter=',', skip_header=0)
plantYearData = plantTxData[0,1:].copy()
plantMonthData = plantTxData[1,1:].copy()
plantDayData = plantTxData[2,1:].copy()
plantTxData = plantTxData[3:,1:].copy()

plantPredCaps = []

for p in range(len(plantList)):
    caps = []
    
    indTxMean = np.where((plantMonthData >= 7) & (plantMonthData <= 8))[0]
    txMean = np.nanmean(plantTxData[p, indTxMean])
    
    for year in range(yearRange[0], yearRange[1]):
        ind = np.where((plantYearData == year) & (plantMonthData >= 7) & (plantMonthData <= 8))[0]
#        ind = np.where((plantYearData == year))[0]
        tx = plantTxData[p, ind]
        tx2 = tx ** 2
        nn = np.where(~np.isnan(tx))[0]
        
        if len(nn) == 0:
            caps.append(np.nan)
            continue
        
        tx = np.nanmax(tx[nn])
#        tx = np.nanmean(tx[nn])
        tx2 = tx2[nn]
#        txMeanList = np.array([txMean]*len(nn))
        caps.append(pPoly3(tx))
        
#        caps.append(np.nanmean(regr.predict(tx)))
#        caps.append(np.nanmean(pPoly3(np.array(list(set(zip(tx)))))))
        
            
    plantPredCaps.append(np.array(caps))
    

plantPredCaps = np.array(plantPredCaps)

slopes = []
intercepts = []

for p in range(plantPredCaps.shape[0]):
    y = plantPredCaps[p,:]
    x = range(len(y))
    X = sm.add_constant(x)
    model = sm.OLS(y, X).fit()
    slopes.append(model._results.params[1])
    intercepts.append(model._results.params[0])

y = np.nanmean(plantPredCaps, axis=0)
x = range(len(y))
X = sm.add_constant(x)
model = sm.OLS(y, X).fit()

slopes = np.array(slopes)
intercepts = np.array(intercepts)

xd = np.array(list(range(1981, 2018)))-1981+1
yd = np.array([intercepts[i] + xd*slopes[i] for i in range(len(slopes))])


plt.figure(figsize=(4,4))
plt.xlim([0, 38])
plt.ylim([95,100])
plt.grid(True)
#plt.plot(xd, yd.T, '-', linewidth = 1, color = [234/255., 49/255., 49/255.], alpha = .2)
#plt.plot(xd, np.nanmean(yd, axis=0), '-', linewidth = 3, color = [0, 0, 0])

plt.plot(xd, plantPredCaps.T, '-', linewidth = 1, color = [.4, .4, .4], alpha = .2)
plt.plot(xd, np.nanmean(plantPredCaps, axis=0), '-', linewidth = 3, color = [0, 0, 0])
plt.plot(xd, np.nanmean(yd, axis=0), '-', linewidth = 2, color = [234/255., 49/255., 49/255.])
#plt.plot(xd, np.nanmean(yPolyd1, axis=0), '-', linewidth = 3, color = [0, 0, 0])


plt.gca().set_xticks(range(1,37,10))
plt.gca().set_xticklabels(range(1981,2018,10))

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

#plt.xlabel('Daily max temperature ($\degree$C)', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Plant capacity (%)', fontname = 'Helvetica', fontsize=16)



if plotFigs:
    plt.savefig('historical-pp-cap-change-linear-summer-txx.png', format='png', dpi=500, bbox_inches = 'tight', pad_inches = 0)




