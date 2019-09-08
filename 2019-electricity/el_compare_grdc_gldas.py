# -*- coding: utf-8 -*-
"""
Created on Sat Sep  7 11:00:35 2019

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
import pickle

plotFigs = True

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDir = 'e:/data/'

def normalize(v):
    nn = np.where(~np.isnan(v))[0]
    v2 = v[nn]
    norm = np.linalg.norm(v2)
    if norm == 0: 
       return v
    return v / norm

def running_mean(x, N):
    cumsum = np.cumsum(np.insert(x, 0, 0)) 
    return (cumsum[N:] - cumsum[:-N]) / float(N)

if not 'nukeData' in locals():
    nukeData = el_nuke_utils.loadNukeData(dataDir)
    nukeMatchDataAll = el_nuke_utils.loadWxData(nukeData, wxdata='all')

qs = nukeMatchDataAll['qs']
qsGrdc = nukeMatchDataAll['qsGrdc']

qsGldasAll = []
qsGrdcAll = []

slopes = []
corrs = []

nMissingGrdc = 0
nMissingGldas = 0

for p in range(qs.shape[0]):
    if len(qs[p]) == len(qsGrdc[p]):
        qsGldasAll.append(normalize(np.array(qs[p])))
        qsGrdcAll.append(normalize(np.array(qsGrdc[p])))
        
        nnGrdc = np.where((np.isnan(qsGrdcAll[-1])))[0]
        nMissingGrdc += len(nnGrdc)
        nnGldas = np.where((np.isnan(qsGldasAll[-1])))[0]
        nMissingGldas += len(nnGldas)
        
        nn = np.where((~np.isnan(qsGrdcAll[-1])) & (~np.isnan(qsGldasAll[-1])))[0]
        
        if len(nn) < .1*len(qsGrdcAll[-1]) or \
           len(nn) < .1*len(qsGldasAll[-1]):
               continue
        
        data = {'GLDAS':qsGldasAll[-1][nn], 'GRDC':qsGrdcAll[-1][nn]}
        
        df = pd.DataFrame(data, \
                          columns=['GLDAS', 'GRDC'])
        
        df = df.dropna()
        
        X = sm.add_constant(df['GLDAS'])
        mdl = sm.OLS(df['GRDC'], X).fit()
        
        corr = np.corrcoef(df['GLDAS'], df['GRDC'])
        
        slopes.append(mdl.params[1])
        corrs.append(corr[0,1])
        
#        print(mdl.params[1], corr[0,1])

qsGrdcAll = np.array(qsGrdcAll)
qsGldasAll = np.array(qsGldasAll)

print(nMissingGrdc/qsGrdcAll.size)
print(nMissingGldas/qsGldasAll.size)

plt.figure(figsize=(4,4))
plt.xlim([0, 1])
plt.ylim([0, 1])
plt.grid(True, color=[.9,.9,.9])
plt.plot(corrs, slopes, 'ok')

plt.xlabel('Correlation', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Slope (GRDC/GLDAS)', fontname = 'Helvetica', fontsize=16)

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

if plotFigs:
    plt.savefig('compare-grdc-gldas.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)


