# -*- coding: utf-8 -*-
"""
Created on Tue May 14 11:52:17 2019

@author: Ethan
"""

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
import pickle
import sys

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDir = 'e:/data/'

plotFigs = False

dataset = 'all'
wxdataset = 'all'

if not 'eData' in locals():
    eData = {}
    with open('eData.dat', 'rb') as f:
        eData = pickle.load(f)

entsoeAgDataEra = eData['entsoeAgDataEra']
entsoeAgDataCpc = eData['entsoeAgDataCpc']
entsoeAgDataNcep = eData['entsoeAgDataNcep']
entsoeAgDataAll = eData['entsoeAgDataAll']

nukeAgDataEra = eData['nukeAgDataEra']
nukeAgDataCpc = eData['nukeAgDataCpc']
nukeAgDataNcep = eData['nukeAgDataNcep']
nukeAgDataAll = eData['nukeAgDataAll']



perc1 = -1
perc2 = 80



tempVar = 'txAvgSummer'
xlim_1 = 0
xlim_2 = 44
#xlim_1 = 0
#xlim_2 = 125



xtotal = []
if dataset == 'nuke' or dataset == 'all':
    if wxdataset == 'era':
        xtotal.extend(nukeAgDataEra[tempVar])
    
    if wxdataset == 'cpc':
        xtotal.extend(nukeAgDataCpc[tempVar])
        
    if wxdataset == 'ncep':
        xtotal.extend(nukeAgDataNcep[tempVar])
        
    if wxdataset == 'all':
        xtotal.extend(nukeAgDataAll[tempVar])

if dataset == 'entsoe' or dataset == 'all':
    if wxdataset == 'era':
        xtotal.extend(entsoeAgDataEra[tempVar])
    
    if wxdataset == 'cpc':
        xtotal.extend(entsoeAgDataCpc[tempVar])
    
    if wxdataset == 'ncep':
        xtotal.extend(entsoeAgDataNcep[tempVar])
        
    if wxdataset == 'all':
        xtotal.extend(entsoeAgDataAll[tempVar])
    
xtotal = np.array(xtotal)

ytotal = []
if dataset == 'nuke' or dataset == 'all':
    if wxdataset == 'era':
        ytotal.extend(nukeAgDataEra['capacitySummer'])
        
    if wxdataset == 'cpc':
        ytotal.extend(nukeAgDataCpc['capacitySummer'])
        
    if wxdataset == 'ncep':
        ytotal.extend(nukeAgDataNcep['capacitySummer'])
        
    if wxdataset == 'all':
        ytotal.extend(nukeAgDataAll['capacitySummer'])
    
if dataset == 'entsoe' or dataset == 'all':
    if wxdataset == 'era':
        ytotal.extend(100*entsoeAgDataEra['capacitySummer'])
        
    if wxdataset == 'cpc':
        ytotal.extend(100*entsoeAgDataCpc['capacitySummer'])
        
    if wxdataset == 'ncep':
        ytotal.extend(100*entsoeAgDataNcep['capacitySummer'])
        
    if wxdataset == 'all':
        ytotal.extend(100*entsoeAgDataAll['capacitySummer'])
    
ytotal = np.array(ytotal)

np.random.seed(1493)

tempInt = []
tempCoef = []

tempNonlinCoef1 = []
tempNonlinCoef2 = []
tempNonlinCoef3 = []

ind = np.where(ytotal <= 101)[0]
indPerc = []
if perc1 == -1:
    indPerc = np.where(xtotal >= np.percentile(xtotal, perc2))[0]
elif perc2 == -1:
    indPerc = np.where(xtotal <= np.percentile(xtotal, perc1))[0]
else:
    indPerc = np.where((xtotal >= np.percentile(xtotal, perc1)) & (xtotal <= np.percentile(xtotal, perc2)))[0]

xtotal = xtotal[np.intersect1d(ind, indPerc)]
ytotal = ytotal[np.intersect1d(ind, indPerc)]

for i in range(1000):
    resampleInd = np.random.choice(len(xtotal), int(len(xtotal)))
    
    data = {'Temp':xtotal[resampleInd], 'PC':ytotal[resampleInd]}
    df = pd.DataFrame(data, \
                      columns=['Temp', 'PC'])
    
    
    df = df.dropna()
    
    X = df[['Temp']]
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

xd = np.linspace(xlim_1, xlim_2, 200)
yd = np.array([tempInt[i] + tempCoef[i] * xd for i in range(len(tempCoef))])
yPolyd1 = np.array([tempNonlinCoef1[i](xd) for i in range(len(tempNonlinCoef1))])
yPolyd2 = np.array([tempNonlinCoef2[i](xd) for i in range(len(tempNonlinCoef2))])
yPolyd3 = np.array([tempNonlinCoef3[i](xd) for i in range(len(tempNonlinCoef3))])

plt.figure(figsize=(2,4))
plt.xlim([xlim_1-1, xlim_2+1])
plt.ylim([75, 100])
plt.grid(True)
#plt.plot(xd, yd.T, '-', linewidth = 1, color = [234/255., 49/255., 49/255.], alpha = .2)
#plt.plot(xd, np.nanmean(yd, axis=0), '-', linewidth = 3, color = [0, 0, 0])

plt.plot(xd, yPolyd1.T, '-', linewidth = 1, color = [234/255., 49/255., 49/255.], alpha = .2)
plt.plot(xd, np.nanmean(yPolyd1, axis=0), '-', linewidth = 3, color = [0, 0, 0])


plt.gca().set_xticks(range(xlim_1,xlim_2+1,8))
plt.gca().set_xticklabels(range(xlim_1,xlim_2+1,8))

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











