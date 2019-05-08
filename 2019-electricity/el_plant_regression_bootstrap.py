# -*- coding: utf-8 -*-
"""
Created on Tue May  7 12:24:42 2019

@author: Ethan
"""

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


import matplotlib.pyplot as plt 
import numpy as np
import pandas as pd
import statsmodels.api as sm
from sklearn import linear_model
import seaborn as sns
import el_entsoe_utils
import el_nuke_utils
import sys

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDir = 'e:/data/'

useEra = False
plotFigs = False

dataset = 'nuke'

if not 'entsoeAgData' in locals():
    entsoeData = el_entsoe_utils.loadEntsoeWithLatLon(dataDir)
    entsoePlantData = el_entsoe_utils.matchEntsoeWxPlantSpecific(entsoeData, useEra=useEra)
#    entsoePlantData = el_entsoe_utils.matchEntsoeWxCountry(entsoeData, useEra=useEra)
    entsoeAgData = el_entsoe_utils.aggregateEntsoeData(entsoePlantData)

if not 'nukeAgData' in locals():
    nukeData = el_nuke_utils.loadNukeData(dataDir)
    nukeTx, nukeTxIds = el_nuke_utils.loadWxData(nukeData, useEra=useEra)
    nukeAgData = el_nuke_utils.accumulateNukeWxData(nukeData, nukeTx, nukeTxIds)


xtotal = []
if dataset == 'nuke' or dataset == 'all':
    xtotal.extend(nukeAgData['txSummer'])

if dataset == 'entsoe' or dataset == 'all':
    xtotal.extend(entsoeAgData['txSummer'])
xtotal = np.array(xtotal)

ytotal = []
if dataset == 'nuke' or dataset == 'all':
    ytotal.extend(nukeAgData['capacitySummer'])
if dataset == 'entsoe' or dataset == 'all':
    ytotal.extend(100*entsoeAgData['capacitySummer'])
ytotal = np.array(ytotal)

plantid = []
if dataset == 'nuke' or dataset == 'all':
    plantid.extend(nukeAgData['plantIds'])
if dataset == 'entsoe' or dataset == 'all':
    plantid.extend(entsoeAgData['plantIds'])
plantid = np.array(plantid)

plantMonths = []
if dataset == 'nuke' or dataset == 'all':
    plantMonths.extend(nukeAgData['plantMonths'])
if dataset == 'entsoe' or dataset == 'all':
    plantMonths.extend(entsoeAgData['plantMonths'])
plantMonths = np.array(plantMonths)

plantDays = []
if dataset == 'nuke' or dataset == 'all':
    plantDays.extend(nukeAgData['plantDays'])
if dataset == 'entsoe' or dataset == 'all':
    plantDays.extend(entsoeAgData['plantDays'])
plantDays = np.array(plantDays)

np.random.seed(1493)

tempInt = []
tempCoef = []

tempNonlinCoef1 = []
tempNonlinCoef2 = []
tempNonlinCoef3 = []

ind = np.where(ytotal <= 101)[0]
xtotal = xtotal[ind]
ytotal = ytotal[ind]

for i in range(1000):
    resampleInd = np.random.choice(len(xtotal), int(.25 * len(xtotal)))
    
    
    data = {'Temp':xtotal[resampleInd], 'PlantID':plantid[resampleInd], \
            'PlantMonths':plantMonths[resampleInd], 'PlantDays':plantDays[resampleInd], \
            'PC':ytotal[resampleInd]}
    df = pd.DataFrame(data, \
                      columns=['Temp', 'PlantID', 'PlantMonths', 'PlantDays', 'PC'])
    
    X = df[['Temp', 'PlantID', 'PlantMonths', 'PlantDays']]
    Y = df['PC']
    
    regr = linear_model.LinearRegression()
    regr.fit(X, Y)
        
    tempCoef.append(regr.coef_[0])
    tempInt.append(regr.intercept_)
    
    z = np.polyfit(df['Temp'], df['PC'], 1)
    p = np.poly1d(z)
    tempNonlinCoef1.append(p)
    
    z = np.polyfit(df['Temp'], df['PC'], 2)
    p = np.poly1d(z)
    tempNonlinCoef2.append(p)

    z = np.polyfit(df['Temp'], df['PC'], 3)
    p = np.poly1d(z)
    tempNonlinCoef3.append(p)

#plt.plot(range(21, 44), p(range(20, 43)), "--", linewidth = 2, color = [234/255., 49/255., 49/255.])

tempInt = np.array(tempInt)
tempCoef = np.array(tempCoef)

xd = np.linspace(20, 44, 100)
yd = np.array([tempInt[i] + tempCoef[i] * xd for i in range(len(tempCoef))])
yPolyd1 = np.array([tempNonlinCoef1[i](xd) for i in range(len(tempNonlinCoef1))])
yPolyd2 = np.array([tempNonlinCoef2[i](xd) for i in range(len(tempNonlinCoef2))])
yPolyd3 = np.array([tempNonlinCoef3[i](xd) for i in range(len(tempNonlinCoef3))])

plt.figure(figsize=(2,4))
plt.xlim([19, 45])
plt.ylim([75, 100])
plt.grid(True)
#plt.plot(xd, yd.T, '-', linewidth = 1, color = [234/255., 49/255., 49/255.], alpha = .2)
#plt.plot(xd, np.nanmean(yd, axis=0), '-', linewidth = 3, color = [0, 0, 0])

plt.plot(xd, yPolyd1.T, '-', linewidth = 1, color = [234/255., 49/255., 49/255.], alpha = .2)
plt.plot(xd, np.nanmean(yPolyd1, axis=0), '-', linewidth = 3, color = [0, 0, 0])


plt.gca().set_xticks(range(20,45,8))
plt.gca().set_xticklabels(range(20,45,8))

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

#plt.xlabel('Daily max temperature ($\degree$C)', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Plant capacity (%)', fontname = 'Helvetica', fontsize=16)

#x0,x1 = plt.gca().get_xlim()
#y0,y1 = plt.gca().get_ylim()
#plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

if plotFigs:
    plt.savefig('pp-regression-bootstrap-poly1-%s.png'%dataset, format='png', dpi=1000, bbox_inches = 'tight', pad_inches = 0)







plt.figure(figsize=(2,4))
plt.xlim([19, 45])
plt.ylim([75, 100])
plt.grid(True)
#plt.plot(xd, yd.T, '-', linewidth = 1, color = [234/255., 49/255., 49/255.], alpha = .2)
#plt.plot(xd, np.nanmean(yd, axis=0), '-', linewidth = 3, color = [0, 0, 0])

plt.plot(xd, yPolyd2.T, '-', linewidth = 1, color = [234/255., 49/255., 49/255.], alpha = .2)
plt.plot(xd, np.nanmean(yPolyd2, axis=0), '-', linewidth = 3, color = [0, 0, 0])


plt.gca().set_xticks(range(20,45,8))
plt.gca().set_xticklabels(range(20,45,8))

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

#plt.xlabel('Daily max temperature ($\degree$C)', fontname = 'Helvetica', fontsize=16)
#plt.ylabel('Plant capacity (%)', fontname = 'Helvetica', fontsize=16)

#x0,x1 = plt.gca().get_xlim()
#y0,y1 = plt.gca().get_ylim()
#plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

if plotFigs:
    plt.savefig('pp-regression-bootstrap-poly2-%s.png'%dataset, format='png', dpi=1000, bbox_inches = 'tight', pad_inches = 0)







plt.figure(figsize=(2,4))
plt.xlim([19, 45])
plt.ylim([75, 100])
plt.grid(True)
#plt.plot(xd, yd.T, '-', linewidth = 1, color = [234/255., 49/255., 49/255.], alpha = .2)
#plt.plot(xd, np.nanmean(yd, axis=0), '-', linewidth = 3, color = [0, 0, 0])

plt.plot(xd, yPolyd3.T, '-', linewidth = 1, color = [234/255., 49/255., 49/255.], alpha = .2)
plt.plot(xd, np.nanmean(yPolyd3, axis=0), '-', linewidth = 3, color = [0, 0, 0])


plt.gca().set_xticks(range(20,45,8))
plt.gca().set_xticklabels(range(20,45,8))

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

#plt.xlabel('Daily max temperature ($\degree$C)', fontname = 'Helvetica', fontsize=16)
#plt.ylabel('Plant capacity (%)', fontname = 'Helvetica', fontsize=16)

#x0,x1 = plt.gca().get_xlim()
#y0,y1 = plt.gca().get_ylim()
#plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

if plotFigs:
    plt.savefig('pp-regression-bootstrap-poly3-%s.png'%dataset, format='png', dpi=1000, bbox_inches = 'tight', pad_inches = 0)





