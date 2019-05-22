# -*- coding: utf-8 -*-
"""
Created on Mon May 20 14:57:18 2019

@author: Ethan
"""


import numpy as np
import matplotlib.pyplot as plt
import matplotlib.cm as cmx
import seaborn as sns
import statsmodels.api as sm
import el_temp_pp_model
import el_load_global_plants
import pickle
import sys

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDir = 'e:/data/'

plotFigs = False

globalPlants = el_load_global_plants.loadGlobalPlants()

pPolyData = {}
with open('pPolyData.dat', 'rb') as f:
    pPolyData = pickle.load(f)

eData = {}
with open('eData.dat', 'rb') as f:
    eData = pickle.load(f)

nukePlantData = eData['nukePlantDataAll']

yearRange = [1981, 2018]

# load wx data for global plants
fileName = 'global-pp-tx-era.csv'

plantList = []
with open(fileName, 'r') as f:
    i = 0
    for line in f:
        if i >= 3:
            parts = line.split(',')
            plantList.append(parts[0])
        i += 1
plantTxData = np.genfromtxt(fileName, delimiter=',', skip_header=0)
plantYearData = plantTxData[0,1:].copy()
plantMonthData = plantTxData[1,1:].copy()
plantDayData = plantTxData[2,1:].copy()
plantTxData = plantTxData[3:,1:].copy()


yearlyOutageAcc10 = []
yearlyOutageAcc50 = []
yearlyOutageAcc90 = []

warming = [0, 1, 2, 3, 4]

for w in range(len(warming)):
    yearlyOutageAcc10.append([])
    yearlyOutageAcc50.append([])
    yearlyOutageAcc90.append([])
    
    for p in range(0, nukePlantData['normalCapacity'].shape[0]):#plantTxData.shape[0]):
        
        normCap = nukePlantData['normalCapacity'][p]
        
        yearlyOutageAcc10[w].append([])
        yearlyOutageAcc50[w].append([])
        yearlyOutageAcc90[w].append([])
        for year in range(1981, 2018+1):
            ind = np.where((plantYearData==year) & ((plantMonthData == 7) | (plantMonthData == 8)))[0]
            yearlyOutageAcc10[w][-1].append(normCap*np.nansum(pPolyData['pPoly3'][pPolyData['indPoly10'][0]](plantTxData[p,ind]+warming[w])-pPolyData['pPoly3'][pPolyData['indPoly10'][0]](20)))
            yearlyOutageAcc50[w][-1].append(normCap*np.nansum(pPolyData['pPoly3'][pPolyData['indPoly50'][0]](plantTxData[p,ind]+warming[w])-pPolyData['pPoly3'][pPolyData['indPoly50'][0]](20)))
            yearlyOutageAcc90[w][-1].append(normCap*np.nansum(pPolyData['pPoly3'][pPolyData['indPoly90'][0]](plantTxData[p,ind]+warming[w])-pPolyData['pPoly3'][pPolyData['indPoly90'][0]](20)))

yearlyOutageAcc10 = np.array(yearlyOutageAcc10)/1000000*24
yearlyOutageAcc50 = np.array(yearlyOutageAcc50)/1000000*24
yearlyOutageAcc90 = np.array(yearlyOutageAcc90)/1000000*24

mean10 = np.nanmean(np.nanmean(yearlyOutageAcc10, axis=2), axis=1)
mean50 = np.nanmean(np.nanmean(yearlyOutageAcc50, axis=2), axis=1)
mean90 = np.nanmean(np.nanmean(yearlyOutageAcc90, axis=2), axis=1)


snsColors = sns.color_palette(["#3498db", "#e74c3c"])

plt.figure(figsize=(4,4))
plt.xlim([-.5, 4.5])
plt.ylim([-3.5, 0])
plt.grid(True, alpha=.5)

plt.plot(warming, mean10, 'ko', mfc=snsColors[0], ms = 8, marker='o', mec='black', mew=1, label='10th Percentile')
plt.plot(warming, mean50, 'ko', mfc='gray', marker='o', ms = 8, mec='black', mew=1, label='50th Percentile')
plt.plot(warming, mean90, 'ko', mfc=snsColors[1], marker='o', ms = 8, mec='black', mew=1, label='90th Percentile')

plt.plot([.5, .5], [-4, 1], '--', linewidth=2, color='black')

plt.ylabel('Summer total outage (TWh)', fontname = 'Helvetica', fontsize=16)

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

plt.gca().set_xticks([0, 1, 2, 3, 4])
plt.gca().set_xticklabels(['Hist', '1$\degree$C', '2$\degree$C', '3$\degree$C', '4$\degree$C'])

leg = plt.legend(prop = {'size':12, 'family':'Helvetica'}, loc = 'upper right')
leg.get_frame().set_linewidth(0.0)

x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))


if plotFigs:
    plt.savefig('accumulated-annual-summer-outage.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)



