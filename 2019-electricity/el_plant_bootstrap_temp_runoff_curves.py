# -*- coding: utf-8 -*-
"""
Created on Thu May  2 16:56:07 2019

@author: Ethan
"""

import numpy as np
import matplotlib.pyplot as plt
import matplotlib.cm as cmx
import pandas as pd
import seaborn as sns
import el_build_temp_pp_model
import pickle, gzip
import random
import sys, os

#dataDir = '
dataDirDiscovery = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/projects/electricity'

tempVar = 'txSummer'
qsVar = 'qsGrdcAnomSummer'

modelPower = 'pow2'

plotFigs = True
dumpData = False


if not 'models' in locals():
    print('building models...')
    models, plantIds, plantYears, plantTxData, plantQsData = el_build_temp_pp_model.buildNonlinearTempQsPPModel(tempVar, qsVar, 1000)

    plantIdsTmp = np.unique(plantIds)
    plantIds = np.array(list(np.unique(plantIds))*len(np.unique(plantYears)))
    tmp = []
    for p in np.unique(plantYears):
        tmp.extend([p]*len(plantIdsTmp))
    plantYears = np.array(tmp)


snsColors = sns.color_palette(["#3498db", "#e74c3c"])

plt.figure(figsize=(8,1))
if 'percentile' in qsVar.lower():
    plt.xlim([0,1])
else:
    plt.xlim([-4, 4])
plt.grid(True, color=[.9, .9, .9])
n, bins, patches = plt.hist(plantQsData, bins=100, density=True, color='#917529');

plt.gca().get_xaxis().set_visible(False)
plt.gca().get_yaxis().set_visible(False)
plt.gca().axis('off')

if plotFigs:
    plt.savefig('runoff-dist-%s.png'%qsVar, format='png', dpi=500, bbox_inches = 'tight', pad_inches = 0, transparent=True)

plt.figure(figsize=(8,1))
plt.xlim([27, 50])
plt.grid(True, color=[.9, .9, .9])
n, bins, patches = plt.hist(plantTxData, bins=100, density=True, color=snsColors[1]);

plt.gca().get_xaxis().set_visible(False)
plt.gca().get_yaxis().set_visible(False)
plt.gca().axis('off')

if plotFigs:
    plt.savefig('temp-dist-%s.png'%tempVar, format='png', dpi=500, bbox_inches = 'tight', pad_inches = 0, transparent=True)

plantMeanTemps = np.nanmean(plantTxData)
plantMeanRunoff = np.nanmean(plantQsData)

#txrange = np.arange(20,51,1)
#qsrange = [1]
#tBase = 27
#qBase = 1
#nModelsTxRange = []
#for t in txrange:
#    nModels = 0
#    for m in range(len(models)):
#        basePred = models[m].get_prediction([1, tBase, tBase**2, qBase, qBase**2, qBase*tBase, (qBase**2)*(tBase**2), 0])
#        cBase = basePred.conf_int()[0]
#        pred = models[m].predict([1, t, t**2, qBase, qBase**2, qBase*t, (qBase**2)*(t**2), 0])
#        
#        if pred < cBase[0] or pred > cBase[1]:
#            nModels += 1
#    nModelsTxRange.append(nModels)
#nModelsTxRange = np.array(nModelsTxRange)/1000.0*100
#
#plt.figure(figsize=(4,4))
#plt.xlim([20,50])
#plt.ylim([0,101])
#plt.grid(True, color=[.9, .9, .9])
#
#plt.plot(txrange, nModelsTxRange, 'k-', linewidth = 2)
#
#plt.gca().set_xticks(range(20,51,5))
#plt.gca().set_yticks([0, 25, 50, 75, 100])
#
#for tick in plt.gca().xaxis.get_major_ticks():
#    tick.label.set_fontname('Helvetica')
#    tick.label.set_fontsize(14)
#for tick in plt.gca().yaxis.get_major_ticks():
#    tick.label.set_fontname('Helvetica')    
#    tick.label.set_fontsize(14)
#
#plt.xlabel('Tx ($\degree$C)', fontname = 'Helvetica', fontsize=16)
#plt.ylabel('% bootstraps significant', fontname = 'Helvetica', fontsize=16)
#
#x0,x1 = plt.gca().get_xlim()
#y0,y1 = plt.gca().get_ylim()
#plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))
#
#if plotFigs:
#    plt.savefig('significant-bootstraps.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)

# find fit percentiles for temperature
t = 50
if 'percentile' in qsVar.lower():
    q = 0.5
else:
    q = 0

print('finding regression percentiles for temperature')
pcEval = []
dfpred = pd.DataFrame({'T1':[t]*len(plantIds), 'T2':[t**2]*len(plantIds), \
                         'QS1':[q]*len(plantIds), 'QS2':[q**2]*len(plantIds), \
                         'QST':[t*q]*len(plantIds), 'QS2T2':[(t**2)*(q**2)]*len(plantIds), \
                         'PlantIds':plantIds, 'PlantYears':plantYears})
for i in range(len(models)):
    pcEval.append(np.nanmean(models[i].predict(dfpred)))

pc10 = np.percentile(pcEval, 10)
pc50 = np.percentile(pcEval, 50)
pc90 = np.percentile(pcEval, 90)

indPc10 = np.where(abs(pcEval-pc10) == np.nanmin(abs(pcEval-pc10)))[0]
indPc50 = np.where(abs(pcEval-pc50) == np.nanmin(abs(pcEval-pc50)))[0]
indPc90 = np.where(abs(pcEval-pc90) == np.nanmin(abs(pcEval-pc90)))[0]


# find fit percentiles for runoff
t = 32#np.nanmean(plantMeanTemps)
if 'percentile' in qsVar.lower():
    q = 0
else:
    q = -4

print('finding regression percentiles for runoff')
pcEval = []
dfpred = pd.DataFrame({'T1':[t]*len(plantIds), 'T2':[t**2]*len(plantIds), \
                         'QS1':[q]*len(plantIds), 'QS2':[q**2]*len(plantIds), \
                         'QST':[t*q]*len(plantIds), 'QS2T2':[(t**2)*(q**2)]*len(plantIds), \
                         'PlantIds':plantIds, 'PlantYears':plantYears})
for i in range(len(models)):
    pcEval.append(np.nanmean(models[i].predict(dfpred)))

pc10 = np.percentile(pcEval, 10)
pc50 = np.percentile(pcEval, 50)
pc90 = np.percentile(pcEval, 90)

indPcQs10 = np.where(abs(pcEval-pc10) == np.nanmin(abs(pcEval-pc10)))[0]
indPcQs50 = np.where(abs(pcEval-pc50) == np.nanmin(abs(pcEval-pc50)))[0]
indPcQs90 = np.where(abs(pcEval-pc90) == np.nanmin(abs(pcEval-pc90)))[0]


pPolyData = {'pcModel10':models[indPc10], 'pcModel50':models[indPc50], 'pcModel90':models[indPc90], \
             'plantIds':plantIds, 'plantYears':plantYears}
if dumpData:
    print('dumping model data')
    prcStr = ''
    if 'percentile' in qsVar.lower():
        prcStr = '-perc'
    if 'grdc' in qsVar.lower():
        polyDataTitle = 'pPolyData-grdc-pow2%s'%prcStr
    elif 'nldas' in qsVar.lower():
        polyDataTitle = 'pPolyData-nldas-pow2%s'%prcStr
    else:
        polyDataTitle = 'pPolyData-gldas-pow2%s'%prcStr
    with gzip.open('%s/script-data/%s.dat'%(dataDirDiscovery, polyDataTitle), 'wb') as f:
        pickle.dump(pPolyData, f)

xd = np.linspace(20, 50, 25)
if 'percentile' in qsVar.lower():
    qd = np.array([.5]*25)
else:
    qd = np.array([np.nanmean(plantMeanRunoff)]*25)

print('calculating regression across T distribution')
ydAll = np.zeros([len(models), len(xd)])
ydAll[ydAll == 0] = np.nan

for k in range(len(xd)):
    print('k = %d'%(k))    
    dfpred = pd.DataFrame({'T1':[xd[k]]*len(plantIds), 'T2':[xd[k]**2]*len(plantIds), \
                     'QS1':[qd[k]]*len(plantIds), 'QS2':[qd[k]**2]*len(plantIds), \
                     'QST':[xd[k]*qd[k]]*len(plantIds), 'QS2T2':[(xd[k]**2)*(qd[k]**2)]*len(plantIds), \
                     'PlantIds':plantIds, 'PlantYears':plantYears})
    for i in range(len(models)):
        ydAll[i, k] = np.nanmean(models[i].predict(dfpred))
        
ydAll = np.array(ydAll)

yd10 = []
yd50 = []
yd90 = []


for k in range(len(xd)):
    
    dfpred = pd.DataFrame({'T1':[xd[k]]*len(plantIds), 'T2':[xd[k]**2]*len(plantIds), \
                     'QS1':[qd[k]]*len(plantIds), 'QS2':[qd[k]**2]*len(plantIds), \
                     'QST':[xd[k]*qd[k]]*len(plantIds), 'QS2T2':[(xd[k]**2)*(qd[k]**2)]*len(plantIds), \
                     'PlantIds':plantIds, 'PlantYears':plantYears})
    yd10.append(np.nanmean(models[indPc10[0]].predict(dfpred)))
    yd50.append(np.nanmean(models[indPc50[0]].predict(dfpred)))   
    yd90.append(np.nanmean(models[indPc90[0]].predict(dfpred)))



baseY = 80
plotYTicks = [80, 85, 90, 95, 100]

plt.figure(figsize=(4,4))
plt.xlim([27, 50])
plt.ylim([baseY, 100])
plt.grid(True, color=[.9, .9, .9])

plt.plot(xd, ydAll.T, '-', linewidth = 1, color = [.65, .65, .65], alpha = .2)
p1 = plt.plot(xd, yd10, '-', linewidth = 2.5, color = snsColors[1], label='90th Percentile')
p2 = plt.plot(xd, yd50, '-', linewidth = 2.5, color = [0, 0, 0], label='50th Percentile')
p3 = plt.plot(xd, yd90, '-', linewidth = 2.5, color = snsColors[0], label='10th Percentile')


colors = plt.get_cmap('Reds')

plt.gca().set_xticks(range(30, 51, 5))
plt.gca().set_yticks(plotYTicks)

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

plt.xlabel('Daily Tx ($\degree$C)', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Mean plant capacity (%)', fontname = 'Helvetica', fontsize=16)

#                 bbox_to_anchor=(0.01, 0.3)
leg = plt.legend(prop = {'size':10, 'family':'Helvetica'}, loc = 'center left')
leg.get_frame().set_linewidth(0.0)
    
x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

if plotFigs:
    plt.savefig('hist-pc-tx-%s-%s-regression.png'%(tempVar, qsVar), format='png', dpi=500, bbox_inches = 'tight', pad_inches = 0)

xd = np.array([32]*25)#np.array([np.nanmean(plantMeanTemps)]*25)
if 'percentile' in qsVar.lower():
    qd = np.linspace(0, 1, 25)
else:
    qd = np.linspace(-4, 4, 25)

ydAll = np.zeros([len(models), len(xd)])
ydAll[ydAll == 0] = np.nan

for k in range(len(xd)):
    print('k = %d'%(k))    
    dfpred = pd.DataFrame({'T1':[xd[k]]*len(plantIds), 'T2':[xd[k]**2]*len(plantIds), \
                     'QS1':[qd[k]]*len(plantIds), 'QS2':[qd[k]**2]*len(plantIds), \
                     'QST':[xd[k]*qd[k]]*len(plantIds), 'QS2T2':[(xd[k]**2)*(qd[k]**2)]*len(plantIds), \
                     'PlantIds':plantIds, 'PlantYears':plantYears})
    for i in range(len(models)):
        ydAll[i, k] = np.nanmean(models[i].predict(dfpred))
        
ydAll = np.array(ydAll)

yd10 = []
yd50 = []
yd90 = []

for k in range(len(xd)):
    dfpred = pd.DataFrame({'T1':[xd[k]]*len(plantIds), 'T2':[xd[k]**2]*len(plantIds), \
                     'QS1':[qd[k]]*len(plantIds), 'QS2':[qd[k]**2]*len(plantIds), \
                     'QST':[xd[k]*qd[k]]*len(plantIds), 'QS2T2':[(xd[k]**2)*(qd[k]**2)]*len(plantIds), \
                     'PlantIds':plantIds, 'PlantYears':plantYears})
    yd10.append(np.nanmean(models[indPc10[0]].predict(dfpred)))
    yd50.append(np.nanmean(models[indPc50[0]].predict(dfpred)))   
    yd90.append(np.nanmean(models[indPc90[0]].predict(dfpred)))
    

yd10 = np.array(yd10)
yd50 = np.array(yd50)
yd90 = np.array(yd90)

plt.figure(figsize=(4,4))
if 'percentile' in qsVar.lower():
    plt.xlim([0,1])
else:
    plt.xlim([-4, 4])
plt.ylim([baseY, 100])
plt.grid(True, color=[.9, .9, .9])

plt.plot(qd, ydAll.T, '-', linewidth = 1, color = [.6, .6, .6], alpha = .2)
p1 = plt.plot(qd, yd10, '-', linewidth = 2.5, color = snsColors[1], label='90th Percentile')
p2 = plt.plot(qd, yd50, '-', linewidth = 2.5, color = [0, 0, 0], label='50th Percentile')
p3 = plt.plot(qd, yd90, '-', linewidth = 2.5, color = snsColors[0], label='10th Percentile')

colors = plt.get_cmap('BrBG')

# for m in plantMeanRunoff:
#    plt.plot([m, m], [baseY, baseY+2], color=colors(m/max(plantMeanRunoff)), linewidth=1)

plt.gca().set_yticks(plotYTicks)
if 'percentile' in qsVar.lower():
    plt.gca().set_xticks(np.arange(0, 1.1, .2))
else:
    plt.gca().set_xticks(np.arange(-4, 4.1, 1))

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

# plt.xlabel('Runoff anomaly (SD)', fontname = 'Helvetica', fontsize=16)
plt.xlabel('Runoff percentile', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Mean plant capacity (%)', fontname = 'Helvetica', fontsize=16)

#leg = plt.legend(prop = {'size':12, 'family':'Helvetica'}, loc = 'lower left')
#leg.get_frame().set_linewidth(0.0)
    
x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

if plotFigs:
    plt.savefig('hist-pc-runoff-%s-%s-regression.png'%(tempVar, qsVar), format='png', dpi=500, bbox_inches = 'tight', pad_inches = 0)

plt.show()
sys.exit()




