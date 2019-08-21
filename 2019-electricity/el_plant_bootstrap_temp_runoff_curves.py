# -*- coding: utf-8 -*-
"""
Created on Thu May  2 16:56:07 2019

@author: Ethan
"""

import numpy as np
import matplotlib.pyplot as plt
import matplotlib.cm as cmx
import seaborn as sns
import el_build_temp_pp_model
import pickle, gzip
import sys, os

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDir = 'e:/data/'

plotFigs = False
dumpData = False

# load historical weather data for plants to compute mean temps 
# to display on bootstrap temp curve
fileName = 'entsoe-nuke-pp-tx-all.csv'
plantTxData = np.genfromtxt(fileName, delimiter=',', skip_header=0)
plantYearData = plantTxData[0,:].copy()
plantMonthData = plantTxData[1,:].copy()
plantDayData = plantTxData[2,:].copy()
plantTxData = plantTxData[3:,:].copy()

fileName = 'entsoe-nuke-pp-runoff-anom-all.csv'
plantQsData = np.genfromtxt(fileName, delimiter=',', skip_header=0)
plantQsData = plantQsData[3:,:].copy()


summerInd = np.where((plantMonthData == 7) | (plantMonthData == 8))[0]
plantMeanTemps = np.nanmean(plantTxData[:,summerInd], axis=1)
plantMeanRunoff = np.nanmean(plantQsData[:,summerInd], axis=1)


models = el_build_temp_pp_model.buildNonlinearTempQsPPModel('txSummer', 'qsGrdcAnomSummer', 1000)


# find fit percentiles for temperature
t = 50
q = 0

pcEval = []
for i in range(len(models)):
    pcEval.append(models[i].predict([1, t, t**2, t**3, \
                                     q, q**2, q**3, q**4, q**5, q*t, 0])[0])

pc10 = np.percentile(pcEval, 10)
pc50 = np.percentile(pcEval, 50)
pc90 = np.percentile(pcEval, 90)

indPc10 = np.where(abs(pcEval-pc10) == np.nanmin(abs(pcEval-pc10)))[0]
indPc50 = np.where(abs(pcEval-pc50) == np.nanmin(abs(pcEval-pc50)))[0]
indPc90 = np.where(abs(pcEval-pc90) == np.nanmin(abs(pcEval-pc90)))[0]


# find fit percentiles for runoff
t = 35
q = -3

pcEval = []
for i in range(len(models)):
    pcEval.append(models[i].predict([1, t, t**2, t**3, \
                                     q, q**2, q**3, q**4, q**5, q*t, 0])[0])

pc10 = np.percentile(pcEval, 10)
pc50 = np.percentile(pcEval, 50)
pc90 = np.percentile(pcEval, 90)

indPcQs10 = np.where(abs(pcEval-pc10) == np.nanmin(abs(pcEval-pc10)))[0]
indPcQs50 = np.where(abs(pcEval-pc50) == np.nanmin(abs(pcEval-pc50)))[0]
indPcQs90 = np.where(abs(pcEval-pc90) == np.nanmin(abs(pcEval-pc90)))[0]


pPolyData = {'pcModel10':models[indPc10], 'pcModel50':models[indPc50], 'pcModel90':models[indPc90]}
if dumpData:
    with gzip.open('pPolyData.dat', 'wb') as f:
        pickle.dump(pPolyData, f)


xd = np.linspace(20, 50, 50)
qd = np.array([0]*50)

ydAll = []
for i in range(len(models)):
    ydAll.append([])
    for k in range(len(xd)):
        ydAll[i].append(models[i].predict([1, xd[k], xd[k]**2, xd[k]**3, \
                                                qd[k], qd[k]**2, qd[k]**3, qd[k]**4, qd[k]**5, qd[k]*xd[k], 0])[0])
ydAll = np.array(ydAll)

yd10 = []
yd50 = []
yd90 = []

for k in range(len(xd)):
    yd10.append(models[indPc10[0]].predict([1, xd[k], xd[k]**2, xd[k]**3, \
                                        qd[k], qd[k]**2, qd[k]**3, qd[k]**4, qd[k]**5, qd[k]*xd[k], 0])[0])
    
    yd50.append(models[indPc50[0]].predict([1, xd[k], xd[k]**2, xd[k]**3, \
                                        qd[k], qd[k]**2, qd[k]**3, qd[k]**4, qd[k]**5, qd[k]*xd[k], 0])[0])
    
    yd90.append(models[indPc90[0]].predict([1, xd[k], xd[k]**2, xd[k]**3, \
                                        qd[k], qd[k]**2, qd[k]**3, qd[k]**4, qd[k]**5, qd[k]*xd[k], 0])[0])
    

snsColors = sns.color_palette(["#3498db", "#e74c3c"])

plt.figure(figsize=(4,4))
plt.xlim([19, 51])
plt.ylim([75, 100])
plt.grid(True, color=[.9, .9, .9])

plt.plot(xd, ydAll.T, '-', linewidth = 1, color = [.65, .65, .65], alpha = .2)
p1 = plt.plot(xd, yd10, '-', linewidth = 2.5, color = snsColors[1], label='90th Percentile')
p2 = plt.plot(xd, yd50, '-', linewidth = 2.5, color = [0, 0, 0], label='50th Percentile')
p3 = plt.plot(xd, yd90, '-', linewidth = 2.5, color = snsColors[0], label='10th Percentile')


colors = plt.get_cmap('Reds')

for m in plantMeanTemps:
    plt.plot([m, m], [75,77], color=colors(m/max(plantMeanTemps)), linewidth=1)

plt.gca().set_xticks(range(20, 51, 5))

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

plt.xlabel('Daily Tx ($\degree$C)', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Mean plant capacity (%)', fontname = 'Helvetica', fontsize=16)

leg = plt.legend(prop = {'size':12, 'family':'Helvetica'}, loc = 'center left')
leg.get_frame().set_linewidth(0.0)
    
x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

if plotFigs:
    plt.savefig('hist-pc-temp-regression-perc.png', format='png', dpi=500, bbox_inches = 'tight', pad_inches = 0)







xd = np.array([35]*50)
qd = np.linspace(-3, 3, 50)

ydAll = []
for i in range(len(models)):
    ydAll.append([])
    for k in range(len(xd)):
        ydAll[i].append(models[i].predict([1, xd[k], xd[k]**2, xd[k]**3, \
                                                qd[k], qd[k]**2, qd[k]**3, qd[k]**4, qd[k]**5, qd[k]*xd[k], 0])[0])
ydAll = np.array(ydAll)

yd10 = []
yd50 = []
yd90 = []

for k in range(len(xd)):
    yd10.append(models[indPcQs10[0]].predict([1, xd[k], xd[k]**2, xd[k]**3, \
                                        qd[k], qd[k]**2, qd[k]**3, qd[k]**4, qd[k]**5, qd[k]*xd[k], 0])[0])
    
    yd50.append(models[indPcQs50[0]].predict([1, xd[k], xd[k]**2, xd[k]**3, \
                                        qd[k], qd[k]**2, qd[k]**3, qd[k]**4, qd[k]**5, qd[k]*xd[k], 0])[0])
    
    yd90.append(models[indPcQs90[0]].predict([1, xd[k], xd[k]**2, xd[k]**3, \
                                        qd[k], qd[k]**2, qd[k]**3, qd[k]**4, qd[k]**5, qd[k]*xd[k], 0])[0])
    



plt.figure(figsize=(4,4))
plt.xlim([-3.1, 3.1])
plt.ylim([75, 100])
plt.grid(True, color=[.9, .9, .9])

plt.plot(qd, ydAll.T, '-', linewidth = 1, color = [.6, .6, .6], alpha = .2)
p1 = plt.plot(qd, yd10, '-', linewidth = 2.5, color = snsColors[1], label='90th Percentile')
p2 = plt.plot(qd, yd50, '-', linewidth = 2.5, color = [0, 0, 0], label='50th Percentile')
p3 = plt.plot(qd, yd90, '-', linewidth = 2.5, color = snsColors[0], label='10th Percentile')

colors = plt.get_cmap('BrBG')

for m in plantMeanRunoff:
    plt.plot([m, m], [75,77], color=colors(m/max(plantMeanRunoff)), linewidth=1)

plt.gca().set_xticks(range(-3, 4, 1))

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

plt.xlabel('Runoff anomaly (SD)', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Mean plant capacity (%)', fontname = 'Helvetica', fontsize=16)

leg = plt.legend(prop = {'size':12, 'family':'Helvetica'}, loc = 'center right')
leg.get_frame().set_linewidth(0.0)
    
x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

if plotFigs:
    plt.savefig('hist-pc-runoff-regression-perc.png', format='png', dpi=500, bbox_inches = 'tight', pad_inches = 0)

plt.show()
sys.exit()







# OLD CODE to display the runoff days historgram

#binstep = .25
#bin_x1 = -3
#bin_x2 = 3
#
#
#bincounts = []
#for t in np.arange(bin_x1, bin_x2+1, binstep):
#    bincounts.append(len(qstotal[(qstotal >= t) & (qstotal < t+binstep)]))
#
#
## plot hist of days in each temp bin
#plt.figure(figsize=(6,1))
#plt.xlim([-3.1, 3.1])
#
#plt.bar(np.arange(bin_x1, bin_x2+1, binstep), bincounts, \
#        facecolor = [.75, .75, .75], \
#        edgecolor = [0, 0, 0], width = binstep, align = 'edge', \
#        zorder=0)
#
##plt.gca().set_xticks([])
##plt.gca().set_xticklabels([])
#plt.gca().set_yticks([])
#plt.gca().set_yticklabels([])
#
#for tick in plt.gca().xaxis.get_major_ticks():
#    tick.label.set_fontname('Helvetica')
#    tick.label.set_fontsize(14)
#for tick in plt.gca().yaxis.get_major_ticks():
#    tick.label.set_fontname('Helvetica')    
#    tick.label.set_fontsize(14)
#    
#
#if plotFigs:
#    plt.savefig('hist-pc-qs-hist.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)
#
#
#plt.show()
    