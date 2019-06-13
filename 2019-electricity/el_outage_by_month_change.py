# -*- coding: utf-8 -*-
"""
Created on Tue Jun 11 15:14:28 2019

@author: Ethan
"""

# -*- coding: utf-8 -*-
"""
Created on Mon Apr  8 17:49:10 2019

@author: Ethan
"""


import matplotlib.pyplot as plt 
import seaborn as sns
import numpy as np
import statsmodels.api as sm
import pickle, gzip
import sys

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDir = 'e:/data/'

plotFigs = False

models = ['bcc-csm1-1-m', 'canesm2', \
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cnrm-cm5', 'csiro-mk3-6-0', \
              'gfdl-esm2g', 'gfdl-esm2m', \
              'inmcm4', 'miroc5', 'miroc-esm', \
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m']


yearRangeHist = [1981, 2018]
yearRangeFut1 = [2020, 2050]
yearRangeFut2 = [2050, 2080]

if not 'eData' in locals():
    eData = {}
    with open('eData.dat', 'rb') as f:
        eData = pickle.load(f)

nukePlants = eData['nukePlantDataAll']
nukeData = eData['nukeAgDataAll']


# calculate the mean outage in the base nuke dataset
meanOutage = []
for m in range(1, 13):
    ind = np.where(mon[0,:] == m)[0]
    meanOutage.append(100-np.array(np.nanmean(cap[:,ind], axis=1)))
meanOutage = np.array(meanOutage)


# load temp-runoff outage models
pcModel10 = []
pcModel50 = []
pcModel90 = []
with gzip.open('pPolyData.dat', 'rb') as f:
    pPolyData = pickle.load(f)
    pcModel10 = pPolyData['pcModel10'][0]
    pcModel50 = pPolyData['pcModel50'][0]
    pcModel90 = pPolyData['pcModel90'][0]


# find historical monthly mean qs and tx for plants
qsAnomMonthlyMean = []
txMonthlyMean = []
txMonthlyMax = []

for p in range(nukePlants['qsAnom'].shape[0]):
    plantMonthlyTxMean = []
    plantMonthlyTxMax = []
    plantMonthlyQsAnomMean = []
    
    for m in range(1,13):
        ind = np.where((nukePlants['plantMonthsAll'][p]==m))[0]
        plantMonthlyTxMean.append(np.nanmean(nukePlants['tx'][p][ind]))
        plantMonthlyQsAnomMean.append(np.nanmean(nukePlants['qsAnom'][p][ind]))
    
    qsAnomMonthlyMean.append(plantMonthlyQsAnomMean)
    txMonthlyMean.append(plantMonthlyTxMean)
    
    for m in range(0,12):
        plantMonthlyTxMax.append([])
        for y in np.unique(nukePlants['plantYearsAll'][p]):
            ind = np.where((nukePlants['plantYearsAll'][p]==y) & (nukePlants['plantMonthsAll'][p]==(m+1)))[0]
            plantMonthlyTxMax[m].append(np.nanmax(nukePlants['tx'][p][ind]))

    txMonthlyMax.append(plantMonthlyTxMax)
qsAnomMonthlyMean = np.array(qsAnomMonthlyMean)
txMonthlyMean = np.array(txMonthlyMean)
txMonthlyMax = np.nanmean(np.array(txMonthlyMax), axis=2)


# find future monthly mean qs and tx for plants

qsAnomMonthlyMeanFut = []
txMonthlyMeanFut = []
txMonthlyMaxFut = []
    
# loop over all models
for m in range(len(models)):
    fileNameTemp = 'future-temps/us-pp-rcp85-tx-cmip5-%s-2020-2050.csv'%(models[m])
    plantTxData = np.genfromtxt(fileNameTemp, delimiter=',', skip_header=0)
    plantTxYearData = plantTxData[0,1:].copy()
    plantTxMonthData = plantTxData[1,1:].copy()
    plantTxDayData = plantTxData[2,1:].copy()
    plantTxData = plantTxData[3:,1:].copy()
    
#    fileNameRunoff = 'future-temps/us-eu-pp-rcp85-runoff-anom-cmip5-%s-2020-2050.csv'%(models[m])
#    plantQsData = np.genfromtxt(fileNameRunoff, delimiter=',', skip_header=0)
#    plantQsYearData = plantTxData[0,1:].copy()
#    plantQsMonthData = plantTxData[1,1:].copy()
#    plantQsDayData = plantTxData[2,1:].copy()
#    plantQsData = plantQsData[3:,1:].copy()

    qsAnomMonthlyMeanFutCurModel = []
    txMonthlyMeanFutCurModel = []
    txMonthlyMaxFutCurModel = []

    for p in range(plantTxData.shape[0]):
        plantMonthlyTxMeanFut = []
        plantMonthlyTxMaxFut = []
#        plantMonthlyQsAnomMeanFut = []
        
        for month in range(1,13):
            ind = np.where((plantTxMonthData==month))[0]
            plantMonthlyTxMeanFut.append(np.nanmean(plantTxData[p,ind]))
#            plantMonthlyQsAnomMeanFut.append(np.nanmean(plantQsData[p,ind]))
        
#        qsAnomMonthlyMeanFut.append(plantMonthlyQsAnomMeanFut)
        txMonthlyMeanFutCurModel.append(plantMonthlyTxMeanFut)
        
        for month in range(0,12):
            plantMonthlyTxMaxFut.append([])
            for y in np.unique(plantTxYearData):
                ind = np.where((plantTxYearData==y) & (plantTxMonthData==(month+1)))[0]
                plantMonthlyTxMaxFut[month].append(np.nanmax(plantTxData[p,ind]))
    
        txMonthlyMaxFutCurModel.append(plantMonthlyTxMaxFut)
#    qsAnomMonthlyMeanFut = np.array(qsAnomMonthlyMeanFut)
    txMonthlyMeanFutCurModel = np.array(txMonthlyMeanFutCurModel)
    txMonthlyMaxFutCurModel = np.nanmean(np.array(txMonthlyMaxFutCurModel), axis=2)
    
    txMonthlyMeanFut.append(txMonthlyMeanFutCurModel)
    txMonthlyMaxFut.append(txMonthlyMaxFutCurModel)

txMonthlyMeanFut = np.array(txMonthlyMeanFut)
txMonthlyMaxFut = np.array(txMonthlyMaxFut)


sys.exit()



plantMonthlyOutageChg = [[], [], []]

# loop over all plants
for p in range(nukePlants['qsAnom'].shape[0]):
    curPlantMonthlyOutageChgQm10 = []
    curPlantMonthlyOutageChgQ0 = []
    curPlantMonthlyOutageChgQ10 = []
    
    for month in range(0,12):
        t0 = txMonthlyMax[p,month]
        
        if t0 >= 20:
            q0 = qsAnomMonthlyMean[p,month]
            
            t1 = np.nanmean(txMonthlyMaxFut[:,p,month], axis=0)
            q1 = qsAnomMonthlyMean[p,month]*.9
            
            pc0 = pcModel50.predict([1, t0, t0**2, t0**3, \
                             q0, q0**2, q0**3, q0**4, q0**5, \
                             0])
            pc1 = pcModel50.predict([1, t1, t1**2, t1**3, \
                                     q1, q1**2, q1**3, q1**4, q1**5, \
                                     0])
            curPlantMonthlyOutageChgQm10.append(pc1-pc0)
            
        
            t1 = np.nanmean(txMonthlyMaxFut[:,p,month], axis=0)
            q1 = qsAnomMonthlyMean[p,month]
            
            pc0 = pcModel50.predict([1, t0, t0**2, t0**3, \
                             q0, q0**2, q0**3, q0**4, q0**5, \
                             0])
            pc1 = pcModel50.predict([1, t1, t1**2, t1**3, \
                                     q1, q1**2, q1**3, q1**4, q1**5, \
                                     0])
            curPlantMonthlyOutageChgQ0.append(pc1-pc0)
            
            
            
            t1 = np.nanmean(txMonthlyMaxFut[:,p,month], axis=0)
            q1 = qsAnomMonthlyMean[p,month]*1.1
            
            pc0 = pcModel50.predict([1, t0, t0**2, t0**3, \
                             q0, q0**2, q0**3, q0**4, q0**5, \
                             0])
            pc1 = pcModel50.predict([1, t1, t1**2, t1**3, \
                                     q1, q1**2, q1**3, q1**4, q1**5, \
                                     0])
            curPlantMonthlyOutageChgQ10.append(pc1-pc0)
        else:
            curPlantMonthlyOutageChgQm10.append(0)
            curPlantMonthlyOutageChgQ0.append(0)
            curPlantMonthlyOutageChgQ10.append(0)
            
    plantMonthlyOutageChg[0].append(curPlantMonthlyOutageChgQm10)
    plantMonthlyOutageChg[1].append(curPlantMonthlyOutageChgQ0)
    plantMonthlyOutageChg[2].append(curPlantMonthlyOutageChgQ10)
plantMonthlyOutageChg = np.array(plantMonthlyOutageChg)


snsColors = sns.color_palette(["#3498db", "#e74c3c"])


fig = plt.figure(figsize=(4,1))
plt.xlim([0, 13])
plt.ylim([-1.4, 0.05])
plt.grid(True, alpha=.5)

plt.plot([0, 13], [0, 0], '--k', lw=1)
plt.plot(list(range(1,13)), np.nanmean(plantMonthlyOutageChg[0,:,:], axis=0), '-', lw=3, color=snsColors[1])

plt.yticks([-1.3, -.7, 0])

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(10)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(10)

plt.gca().spines['bottom'].set_visible(False)
plt.tick_params(
    axis='x',          # changes apply to the x-axis
    which='both',      # both major and minor ticks are affected
    bottom=False,      # ticks along the bottom edge are off
    top=False,         # ticks along the top edge are off
    labelbottom=False) # labels along the bottom edge are off

sys.exit()


if plotFigs:
    plt.savefig('outage-chg-by-month-wide.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)






                               
                               
plt.figure(figsize=(4,2))
plt.xlim([0, 13])
plt.ylim([0, 28])
plt.grid(True, alpha=.5)

b = plt.bar(range(1, 13), np.nanmean(meanOutage, axis=1), \
            yerr = np.nanstd(meanOutage, axis=1)/2, error_kw = dict(lw=1.5, capsize=3, capthick=1.5, ecolor=[.25, .25, .25]))
for i in range(len(b)):
    if i == 6 or i == 7:
        b[i].set_color(snsColors[1])
        b[i].set_edgecolor('black')
    else:
        b[i].set_color(snsColors[0])

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(10)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(10)

plt.xlabel('Month', fontname = 'Helvetica', fontsize=12)
#plt.ylabel('Mean outage (%)', fontname = 'Helvetica', fontsize=12)

#x0,x1 = plt.gca().get_xlim()
#y0,y1 = plt.gca().get_ylim()
#plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

if plotFigs:
    plt.savefig('outages-by-month-change-wide.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)
