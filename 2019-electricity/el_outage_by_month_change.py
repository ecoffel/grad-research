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
import sys, os

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDir = 'e:/data/'

plotFigs = False

models = ['bcc-csm1-1-m', 'canesm2', \
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cnrm-cm5', 'csiro-mk3-6-0', \
              'gfdl-esm2g', 'gfdl-esm2m', \
              'inmcm4', 'miroc5', 'miroc-esm', \
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m']


if not 'eData' in locals():
    eData = {}
    with open('eData.dat', 'rb') as f:
        eData = pickle.load(f)

nukePlants = eData['nukePlantDataAll']
nukeData = eData['nukeAgDataAll']
entsoePlants = eData['entsoePlantDataAll']

# load temp-runoff outage models
pcModel10 = []
pcModel50 = []
pcModel90 = []
with gzip.open('pPolyData.dat', 'rb') as f:
    pPolyData = pickle.load(f)
    # these are mislabeled in dict for now (90 is 10, 10 is 90)
    pcModel10 = pPolyData['pcModel90'][0]
    pcModel50 = pPolyData['pcModel50'][0]
    pcModel90 = pPolyData['pcModel10'][0]


# find historical monthly mean qs and tx for plants
qsAnomMonthlyMean = []
txMonthlyMean = []
txMonthlyMax = []

# first for entsoe plants....
for p in range(entsoePlants['tx'].shape[0]):
    plantMonthlyTxMean = []
    plantMonthlyTxMax = []
    plantMonthlyQsAnomMean = []
    
    for m in range(1, 13):
        ind = np.where(entsoePlants['months'] == m)[0]
        plantMonthlyTxMean.append(np.nanmean(entsoePlants['tx'][p, ind]))
        plantMonthlyQsAnomMean.append(np.nanmean(entsoePlants['qsAnom'][p][ind]))
    
    qsAnomMonthlyMean.append(plantMonthlyQsAnomMean)
    txMonthlyMean.append(plantMonthlyTxMean)
    
    for m in range(0,12):
        plantMonthlyTxMax.append([])
        for y in np.unique(entsoePlants['years']):
            ind = np.where((entsoePlants['years']==y) & (entsoePlants['months']==(m+1)))[0]
            plantMonthlyTxMax[m].append(np.nanmax(entsoePlants['tx'][p][ind]))

    txMonthlyMax.append(np.nanmean(np.array(plantMonthlyTxMax), axis=1))

# then for nuke plants
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

    txMonthlyMax.append(np.nanmean(np.array(plantMonthlyTxMax), axis=1))

qsAnomMonthlyMean = np.array(qsAnomMonthlyMean)
txMonthlyMean = np.array(txMonthlyMean)
txMonthlyMax = np.array(txMonthlyMax)


# find future monthly mean qs and tx for plants using RCP 85
qsAnomMonthlyMeanFut = []
txMonthlyMeanFut = []
txMonthlyMaxFut = []
    
# loop over all models
for m in range(len(models)):
    fileNameTemp = 'future-temps/us-eu-pp-rcp85-tx-cmip5-%s-2050-2080.csv'%(models[m])
    plantTxData = np.genfromtxt(fileNameTemp, delimiter=',', skip_header=0)
    plantTxYearData = plantTxData[0,1:].copy()
    plantTxMonthData = plantTxData[1,1:].copy()
    plantTxDayData = plantTxData[2,1:].copy()
    plantTxData = plantTxData[3:,1:].copy()
    
    fileNameRunoff = 'future-temps/us-eu-pp-rcp85-runoff-cmip5-%s-2050-2080.csv'%(models[m])
    plantQsData = np.genfromtxt(fileNameRunoff, delimiter=',', skip_header=0)
    plantQsYearData = plantTxData[0,1:].copy()
    plantQsMonthData = plantTxData[1,1:].copy()
    plantQsDayData = plantTxData[2,1:].copy()
    plantQsData = plantQsData[3:,1:].copy()

    qsAnomMonthlyMeanFutCurModel = []
    txMonthlyMeanFutCurModel = []
    txMonthlyMaxFutCurModel = []

    for p in range(plantTxData.shape[0]):
        plantMonthlyTxMeanFut = []
        plantMonthlyTxMaxFut = []
        plantMonthlyQsAnomMeanFut = []
        
        for month in range(1,13):
            ind = np.where((plantTxMonthData==month))[0]
            plantMonthlyTxMeanFut.append(np.nanmean(plantTxData[p,ind]))
            plantMonthlyQsAnomMeanFut.append(np.nanmean(plantQsData[p,ind]))
        
        qsAnomMonthlyMeanFutCurModel.append(plantMonthlyQsAnomMeanFut)
        txMonthlyMeanFutCurModel.append(plantMonthlyTxMeanFut)
        
        for month in range(0,12):
            plantMonthlyTxMaxFut.append([])
            for y in np.unique(plantTxYearData):
                ind = np.where((plantTxYearData==y) & (plantTxMonthData==(month+1)))[0]
                plantMonthlyTxMaxFut[month].append(np.nanmax(plantTxData[p,ind]))
    
        txMonthlyMaxFutCurModel.append(plantMonthlyTxMaxFut)
    qsAnomMonthlyMeanFutCurModel = np.array(qsAnomMonthlyMeanFutCurModel)
    txMonthlyMeanFutCurModel = np.array(txMonthlyMeanFutCurModel)
    txMonthlyMaxFutCurModel = np.nanmean(np.array(txMonthlyMaxFutCurModel), axis=2)
    
    qsAnomMonthlyMeanFut.append(qsAnomMonthlyMeanFutCurModel)
    txMonthlyMeanFut.append(txMonthlyMeanFutCurModel)
    txMonthlyMaxFut.append(txMonthlyMaxFutCurModel)

qsAnomMonthlyMeanFut = np.array(qsAnomMonthlyMeanFut)
txMonthlyMeanFut = np.array(txMonthlyMeanFut)
txMonthlyMaxFut = np.array(txMonthlyMaxFut)






# load future mean warming data for GMT levels

# load future mean warming data and recompute PC
txMonthlyMeanFutGMT = []
txMonthlyMaxFutGMT = []
qsMonthlyMeanFutGMT = []

for w in range(1, 4+1):
    curTxMonthlyMeanGMT = []
    curTxMonthlyMaxGMT = []
    curQsMonthlyMeanGMT = []
    
    for m in range(len(models)):
        
        curModelTxMonthlyMeanGMT = []
        curModelTxMonthlyMaxGMT = []
        curModelQsMonthlyMeanGMT = []
        
        # load data for current model and warming level
        fileNameTemp = 'gmt-anomaly-temps/us-eu-pp-%ddeg-tx-cmip5-%s.csv'%(w, models[m])
    
        if not os.path.isfile(fileNameTemp):
            # add a nan for each plant in current model
            filler = []
            for p in range(90):
                f1 = []
                for mon in range(1, 13):
                    f1.append(np.nan)
                filler.append(f1)
            curTxMonthlyMeanGMT.append(filler)
            curTxMonthlyMaxGMT.append(filler)
            curQsMonthlyMeanGMT.append(filler)
            continue
    
        plantTxData = np.genfromtxt(fileNameTemp, delimiter=',', skip_header=0)
        
        if len(plantTxData) == 0:
            # add a nan for each plant in current model
            filler = []
            for p in range(90):
                f1 = []
                for mon in range(1, 13):
                    f1.append(np.nan)
                filler.append(f1)
            curTxMonthlyMeanGMT.append(filler)
            curTxMonthlyMaxGMT.append(filler)
            curQsMonthlyMeanGMT.append(filler)
            continue
        
        plantTxYearData = plantTxData[0,1:].copy()
        plantTxMonthData = plantTxData[1,1:].copy()
        plantTxDayData = plantTxData[2,1:].copy()
        plantTxData = plantTxData[3:,1:].copy()
        
        fileNameRunoff = 'gmt-anomaly-temps/us-eu-pp-%ddeg-runoff-cmip5-%s.csv'%(w, models[m])
        
        if not os.path.isfile(fileNameRunoff):
            # add a nan for each plant in current model
            filler = []
            for p in range(90):
                f1 = []
                for mon in range(1, 13):
                    f1.append(np.nan)
                filler.append(f1)
            curTxMonthlyMeanGMT.append(filler)
            curTxMonthlyMaxGMT.append(filler)
            curQsMonthlyMeanGMT.append(filler)
            continue
        
        plantQsData = np.genfromtxt(fileNameRunoff, delimiter=',', skip_header=0)
        
        if len(plantQsData) == 0:
            # add a nan for each plant in current model
            filler = []
            for p in range(90):
                f1 = []
                for mon in range(1, 13):
                    f1.append(np.nan)
                filler.append(f1)
            curTxMonthlyMeanGMT.append(filler)
            curTxMonthlyMaxGMT.append(filler)
            curQsMonthlyMeanGMT.append(filler)
            continue
        
        plantQsYearData = plantTxData[0,1:].copy()
        plantQsMonthData = plantTxData[1,1:].copy()
        plantQsDayData = plantTxData[2,1:].copy()
        plantQsData = plantQsData[3:,1:].copy()
        
        # loop over all plants
        for p in range(plantTxData.shape[0]):
            
            plantTxMonthlyMeanGMT = []
            plantTxMonthlyMaxGMT = []
            plantQsMonthlyMeanGMT = []
            
            # tx,qs for current plant
            tx = plantTxData[p, :]
            qs = plantQsData[p, :]
            
            # loop over all years for current model/GMT anomaly
            for year in range(int(min(plantTxYearData)), int(max(plantTxYearData))+1):
        
                plantCurYearTxMonthlyMeanGMT = []
                plantCurYearTxMonthlyMaxGMT = []
                plantCurYearQsMonthlyMeanGMT = []
            
                # and over all months
                for month in range(1, 13):
                
                    # tx for current year's current month
                    ind = np.where((plantTxYearData == year) & (plantTxMonthData == month))[0]
                    
                    curTx = tx[ind]
                    curQs = qs[ind]
                    
                    nn = np.where((~np.isnan(curTx)) & (~np.isnan(curQs)))[0]
                    
                    if len(nn) == 0:
                        plantCurYearTxMonthlyMeanGMT.append(np.nan)
                        plantCurYearTxMonthlyMaxGMT.append(np.nan)
                        plantCurYearQsMonthlyMeanGMT.append(np.nan)
                        continue
                
                    curTx = curTx[nn]
                    curQs = curQs[nn]
                    
                    # ind of the txx day in this year/month
                    indTxx = np.where(curTx == np.nanmax(curTx))[0][0]
                    
                    curTxx = curTx[indTxx]
                    curQsTxx = curQs[indTxx]
                         
                    plantCurYearTxMonthlyMeanGMT.append(np.nanmean(curTx))
                    plantCurYearTxMonthlyMaxGMT.append(curTxx)
                    plantCurYearQsMonthlyMeanGMT.append(np.nanmean(curQs))
                
                plantTxMonthlyMeanGMT.append(plantCurYearTxMonthlyMeanGMT)
                plantTxMonthlyMaxGMT.append(plantCurYearTxMonthlyMaxGMT)
                plantQsMonthlyMeanGMT.append(plantCurYearQsMonthlyMeanGMT)
            
            curModelTxMonthlyMeanGMT.append(np.nanmean(np.array(plantTxMonthlyMeanGMT), axis=0))
            curModelTxMonthlyMaxGMT.append(np.nanmean(np.array(plantTxMonthlyMaxGMT), axis=0))
            curModelQsMonthlyMeanGMT.append(np.nanmean(np.array(plantQsMonthlyMeanGMT), axis=0))
        
        curTxMonthlyMeanGMT.append(curModelTxMonthlyMeanGMT)
        curTxMonthlyMaxGMT.append(curModelTxMonthlyMaxGMT)
        curQsMonthlyMeanGMT.append(curModelQsMonthlyMeanGMT)
    
    txMonthlyMeanFutGMT.append(curTxMonthlyMeanGMT)
    txMonthlyMaxFutGMT.append(curTxMonthlyMaxGMT)
    qsMonthlyMeanFutGMT.append(curQsMonthlyMeanGMT)

txMonthlyMeanFutGMT = np.array(txMonthlyMeanFutGMT)
txMonthlyMaxFutGMT = np.array(txMonthlyMaxFutGMT)
qsMonthlyMeanFutGMT = np.array(qsMonthlyMeanFutGMT)
qsMonthlyMeanFutGMT[qsMonthlyMeanFutGMT>5] = np.nan





plantMonthlyOutageChg = []

# loop over GMT warming levels
for w in range(0, 4):
    plantMonthlyOutageChgGMT = []
    # loop over all plants
    for p in range(nukePlants['qsAnom'].shape[0] + entsoePlants['tx'].shape[0]):
        curPlantMonthlyOutageChg = []
        
        for month in range(0,12):
            t0 = txMonthlyMax[p,month]
            
            curPlantMonthlyOutageChg.append([])
            
            if t0 >= 20:
                
                for model in range(len(models)):
                    q0 = qsAnomMonthlyMean[p,month]
                    
                    t1 = txMonthlyMaxFutGMT[w,model,p,month]
                    q1 = qsMonthlyMeanFutGMT[w,model,p,month]
                    
                    pc0 = pcModel90.predict([1, t0, t0**2, t0**3, \
                                     q0, q0**2, q0**3, q0**4, q0**5, \
                                     t1*q1,0])
                    pc1 = pcModel90.predict([1, t1, t1**2, t1**3, \
                                             q1, q1**2, q1**3, q1**4, q1**5, \
                                             t1*q1, 0])
        
                    # if projected PC < 0... limit to 0
                    if pc1 < 0:
                        curPlantMonthlyOutageChg[month].append(-pc0)
                    else:
                        curPlantMonthlyOutageChg[month].append(pc1-pc0)
                    
                
            else:
                for model in range(len(models)):
                    curPlantMonthlyOutageChg[month].append(0)
                
        plantMonthlyOutageChgGMT.append(curPlantMonthlyOutageChg)
    
    plantMonthlyOutageChg.append(plantMonthlyOutageChgGMT)

plantMonthlyOutageChg = np.array(plantMonthlyOutageChg)

plantMonthlyOutageChgSorted = np.sort(np.nanmean(plantMonthlyOutageChg,axis=1),axis=2)

snsColors = sns.color_palette(["#3498db", "#e74c3c"])


fig = plt.figure(figsize=(4,1))
plt.xlim([0, 13])
plt.ylim([-9, 0])
plt.grid(True, alpha=.5, color=[.9,.9,.9])

#plt.plot([0, 13], [0, 0], '--k', lw=1)
plt.plot(list(range(1,13)), np.nanmean(np.nanmean(plantMonthlyOutageChg[1,:,:,:],axis=2),axis=0), '-', lw=2, color='#ffb835')
plt.plot(list(range(1,13)), plantMonthlyOutageChgSorted[1,:,0], '--', lw=1, color='#ffb835')
plt.plot(list(range(1,13)), np.nanmean(np.nanmean(plantMonthlyOutageChg[3,:,:,:],axis=2),axis=0), '-', lw=2, color=snsColors[1])
plt.plot(list(range(1,13)), plantMonthlyOutageChgSorted[3,:,0], '--', lw=1, color=snsColors[1])


#plt.plot(list(range(1,13)), plantMonthlyOutageChgSorted[:,0], '--', lw=1, color=snsColors[1])
#plt.plot(list(range(1,13)), np.nanmean(plantMonthlyOutageChgSorted, axis=1), '-', lw=3, color=snsColors[1])
#plt.plot(list(range(1,13)), plantMonthlyOutageChgSorted[:,-1], '--', lw=1, color=snsColors[1])

plt.xticks(list(range(1,13)))
plt.yticks([-8, -4, 0])

plt.xticks(list(range(1,13)))

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(10)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(10)

#plt.gca().spines['bottom'].set_visible(False)
#plt.tick_params(
#    axis='x',          # changes apply to the x-axis
#    which='both',      # both major and minor ticks are affected
#    bottom=False,      # ticks along the bottom edge are off
#    top=False,         # ticks along the top edge are off
#    labelbottom=False) # labels along the bottom edge are off

plt.xlabel('Month', fontname = 'Helvetica', fontsize=12)



if plotFigs:
    plt.savefig('outage-chg-by-month-wide.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)





                               
#                               
#plt.figure(figsize=(4,2))
#plt.xlim([0, 13])
#plt.ylim([0, 28])
#plt.grid(True, alpha=.5)
#
#b = plt.bar(range(1, 13), np.nanmean(meanOutage, axis=1), \
#            yerr = np.nanstd(meanOutage, axis=1)/2, error_kw = dict(lw=1.5, capsize=3, capthick=1.5, ecolor=[.25, .25, .25]))
#for i in range(len(b)):
#    if i == 6 or i == 7:
#        b[i].set_color(snsColors[1])
#        b[i].set_edgecolor('black')
#    else:
#        b[i].set_color(snsColors[0])
#
#for tick in plt.gca().xaxis.get_major_ticks():
#    tick.label.set_fontname('Helvetica')
#    tick.label.set_fontsize(10)
#for tick in plt.gca().yaxis.get_major_ticks():
#    tick.label.set_fontname('Helvetica')    
#    tick.label.set_fontsize(10)
#
#plt.xlabel('Month', fontname = 'Helvetica', fontsize=12)
##plt.ylabel('Mean outage (%)', fontname = 'Helvetica', fontsize=12)
#
##x0,x1 = plt.gca().get_xlim()
##y0,y1 = plt.gca().get_ylim()
##plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))
#
#if plotFigs:
#    plt.savefig('outages-by-month-change-wide.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)
