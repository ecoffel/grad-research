# -*- coding: utf-8 -*-
"""
Created on Mon Apr  8 17:49:10 2019

@author: Ethan
"""


import matplotlib.pyplot as plt 
import seaborn as sns
import numpy as np
import statsmodels.api as sm
import pickle
import sys,os

import el_build_temp_demand_model

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDir = 'e:/data/'

plotFigs = False


if not 'eData' in locals():
    eData = {}
    with open('eData.dat', 'rb') as f:
        eData = pickle.load(f)

nukePlants = eData['nukePlantDataAll']
nukeData = eData['nukeAgDataAll']

normalCap = nukePlants['normalCapacity']
cap = nukeData['percCapacity']
mon = nukeData['plantMonthsAll']

entsoePlants = eData['entsoePlantDataAll']

models = ['bcc-csm1-1-m', 'canesm2', \
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cnrm-cm5', 'csiro-mk3-6-0', \
              'gfdl-esm2g', 'gfdl-esm2m', \
              'inmcm4', 'miroc5', 'miroc-esm', \
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m']


yearRangeHist = [1981, 2018]
yearRangeFut1 = [2020, 2050]
yearRangeFut2 = [2050, 2080]


meanOutage = []

for m in range(1, 13):
    curMonthOutage = []
    
    ind = np.where(mon[0,:] == m)[0]
    curMonthOutage.extend(np.nanmean(cap[:,ind], axis=1))
    
    ind = np.where(entsoePlants['months'] == m)[0]
    curMonthOutage.extend(100*np.nanmean(entsoePlants['capacity'][:,ind], axis=1))
    
    meanOutage.append(curMonthOutage)
meanOutage = 100-np.array(meanOutage)


snsColors = sns.color_palette(["#3498db", "#e74c3c"])

plt.figure(figsize=(4,2))
plt.xlim([0, 13])
plt.ylim([0, 22])
plt.grid(True, alpha=.5, color=[.9, .9, .9])
plt.gca().set_axisbelow(True)

b = plt.bar(range(1, 13), np.nanmean(meanOutage, axis=1), \
            yerr = np.nanstd(meanOutage, axis=1)/2, error_kw = dict(lw=1.5, capsize=3, capthick=1.5, ecolor=[.25, .25, .25]))
for i in range(len(b)):
    if i == 6 or i == 7:
        b[i].set_color(snsColors[1])
        b[i].set_edgecolor('black')
    else:
        b[i].set_color(snsColors[0])

plt.xticks(list(range(1,13)))
plt.gca().invert_yaxis()

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(10)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(10)

plt.tick_params(
    axis='x',          # changes apply to the x-axis
    which='both',      # both major and minor ticks are affected
    bottom=False,      # ticks along the bottom edge are off
    top=False,         # ticks along the top edge are off
    labelbottom=False) # labels along the bottom edge are off

#plt.xlabel('Month', fontname = 'Helvetica', fontsize=12)
#plt.ylabel('Mean outage (%)', fontname = 'Helvetica', fontsize=12)

#x0,x1 = plt.gca().get_xlim()
#y0,y1 = plt.gca().get_ylim()
#plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

if plotFigs:
    plt.savefig('outages-by-month-wide.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)





mon = nukeData['plantMonthsAll']
tx = nukePlants['tx']
histTempsByMonth = []

for m in range(1, 13):
    curMonth = []
    ind = np.where(entsoePlants['months'] == m)[0]
    curMonth.extend(np.nanmean(entsoePlants['tx'][:, ind], axis=1))
    
    ind = np.where(nukeData['plantMonthsAll'][0,:] == m)[0]
    curMonth.extend(np.nanmean(nukePlants['tx'][:, ind], axis=1))
    
    histTempsByMonth.append(curMonth)

histTempsByMonth = np.array(histTempsByMonth)
histTempsByMonth = np.nanmean(histTempsByMonth, axis=1)

# load future temps and runoff values
#qsAnomMonthlyMeanFut = []
#txMonthlyMeanFut = []
#txMonthlyMaxFut = []
#    
## loop over all models
#for m in range(len(models)):
#    fileNameTemp = 'future-temps/us-eu-pp-rcp85-tx-cmip5-%s-2050-2080.csv'%(models[m])
#    plantTxData = np.genfromtxt(fileNameTemp, delimiter=',', skip_header=0)
#    plantTxYearData = plantTxData[0,1:].copy()
#    plantTxMonthData = plantTxData[1,1:].copy()
#    plantTxDayData = plantTxData[2,1:].copy()
#    plantTxData = plantTxData[3:,1:].copy()
#    
#    fileNameRunoff = 'future-temps/us-eu-pp-rcp85-runoff-cmip5-%s-2050-2080.csv'%(models[m])
#    plantQsData = np.genfromtxt(fileNameRunoff, delimiter=',', skip_header=0)
#    plantQsYearData = plantTxData[0,1:].copy()
#    plantQsMonthData = plantTxData[1,1:].copy()
#    plantQsDayData = plantTxData[2,1:].copy()
#    plantQsData = plantQsData[3:,1:].copy()
#
#    qsAnomMonthlyMeanFutCurModel = []
#    txMonthlyMeanFutCurModel = []
#    txMonthlyMaxFutCurModel = []
#
#    for p in range(plantTxData.shape[0]):
#        plantMonthlyTxMeanFut = []
#        plantMonthlyTxMaxFut = []
#        plantMonthlyQsAnomMeanFut = []
#        
#        for month in range(1,13):
#            ind = np.where((plantTxMonthData==month))[0]
#            plantMonthlyTxMeanFut.append(np.nanmean(plantTxData[p,ind]))
#            plantMonthlyQsAnomMeanFut.append(np.nanmean(plantQsData[p,ind]))
#        
#        qsAnomMonthlyMeanFutCurModel.append(plantMonthlyQsAnomMeanFut)
#        txMonthlyMeanFutCurModel.append(plantMonthlyTxMeanFut)
#        
#        for month in range(0,12):
#            plantMonthlyTxMaxFut.append([])
#            for y in np.unique(plantTxYearData):
#                ind = np.where((plantTxYearData==y) & (plantTxMonthData==(month+1)))[0]
#                plantMonthlyTxMaxFut[month].append(np.nanmax(plantTxData[p,ind]))
#    
#        txMonthlyMaxFutCurModel.append(plantMonthlyTxMaxFut)
#    
#    qsAnomMonthlyMeanFutCurModel = np.array(qsAnomMonthlyMeanFutCurModel)
#    txMonthlyMeanFutCurModel = np.array(txMonthlyMeanFutCurModel)
#    txMonthlyMaxFutCurModel = np.nanmean(np.array(txMonthlyMaxFutCurModel), axis=2)
#    
#    qsAnomMonthlyMeanFut.append(qsAnomMonthlyMeanFutCurModel)
#    txMonthlyMeanFut.append(txMonthlyMeanFutCurModel)
#    txMonthlyMaxFut.append(txMonthlyMaxFutCurModel)
#
#qsAnomMonthlyMeanFut = np.array(qsAnomMonthlyMeanFut)
#txMonthlyMeanFut = np.array(txMonthlyMeanFut)
#txMonthlyMaxFut = np.array(txMonthlyMaxFut)
#
#








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


txMonthlyMeanFutGMTSorted = np.sort(np.nanmean(txMonthlyMeanFutGMT, axis=2), axis=1)


fig = plt.figure(figsize=(4,2))
plt.xlim([0, 13])
plt.ylim([4, 38])
plt.grid(True, alpha=.5, color=[.9, .9, .9])

plt.plot(list(range(1,13)), histTempsByMonth, '-', lw=2, color='black')

plt.plot(list(range(1,13)), np.nanmean(np.nanmean(txMonthlyMeanFutGMT[1,:,:,:],axis=1),axis=0), '-', lw=2, color='#ffb835')
plt.plot(list(range(1,13)), txMonthlyMeanFutGMTSorted[1,-1,:], '--', lw=1, color='#ffb835')
plt.plot(list(range(1,13)), np.nanmean(np.nanmean(txMonthlyMeanFutGMT[3,:,:,:],axis=1),axis=0), '-', lw=2, color=snsColors[1])
plt.plot(list(range(1,13)), txMonthlyMeanFutGMTSorted[3,-2,:], '--', lw=1, color=snsColors[1])

plt.xticks(list(range(1,13)))

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


#plt.xlabel('Month', fontname = 'Helvetica', fontsize=12)
#plt.ylabel('Mean temperature ($\degree$C)', fontname = 'Helvetica', fontsize=12)

#x0,x1 = plt.gca().get_xlim()
#y0,y1 = plt.gca().get_ylim()
#plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))



if plotFigs:
    plt.savefig('temps-by-month-wide.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)


# load data on demand, generation, and temperature across US subgrids
demData = {}
with open('genData.dat', 'rb') as f:
    demData = pickle.load(f)

demTempModels = el_build_temp_demand_model.buildNonlinearDemandModel(10)


# calculate monthly mean maximum temp for entsoe and nuke plants
entsoeMonthlyTxMaxHist = []
for y in np.unique(entsoePlants['years']):
    entsoeMonthlyTxMaxHistCurYear = []
    for m in range(1, 13):
        ind = np.where((entsoePlants['years'] == y) & (entsoePlants['months'] == m))[0]
        txx = np.nanmax(entsoePlants['tx'][:, ind], axis=1)
        entsoeMonthlyTxMaxHistCurYear.append(txx)
    entsoeMonthlyTxMaxHist.append(entsoeMonthlyTxMaxHistCurYear)
entsoeMonthlyTxMaxHist = np.nanmean(np.array(entsoeMonthlyTxMaxHist), axis=0)

nukeMonthlyTxMaxHist = []
for y in np.unique(nukePlants['plantYearsAll']):
    nukeMonthlyTxMaxHistCurYear = []
    for m in range(1, 13):
        ind = np.where((nukePlants['plantYearsAll'][0,:] == y) & (nukePlants['plantMonthsAll'][0,:] == m))[0]
        txx = np.nanmax(nukePlants['tx'][:, ind], axis=1)
        nukeMonthlyTxMaxHistCurYear.append(txx)
    nukeMonthlyTxMaxHist.append(nukeMonthlyTxMaxHistCurYear)
nukeMonthlyTxMaxHist = np.nanmean(np.array(nukeMonthlyTxMaxHist), axis=0)

monthlyTxMaxHist = np.concatenate((nukeMonthlyTxMaxHist, entsoeMonthlyTxMaxHist), axis=1)


demHist = []
for plant in range(monthlyTxMaxHist.shape[1]):
    demHistPlant = []
    for month in range(0,12):
        demHistMonth = []
        for d in range(len(demTempModels)):
            tx = monthlyTxMaxHist[month, plant]
            txProj = demTempModels[d].predict([1, tx, tx**2, tx**3])
            demHistMonth.append(txProj)
        
        demHistPlant.append(demHistMonth)
    demHist.append(demHistPlant)
demHist = np.squeeze(np.nanmean(np.nanmean(np.array(demHist), axis=2), axis=0))

# project future demand at GMT thresholds
demProj = []
for w in range(4):
    demProjCurGMT = []
    for model in range(txMonthlyMaxFutGMT.shape[1]):
        demProjCurModel = []
        for plant in range(txMonthlyMaxFutGMT.shape[2]):
            demProjCurPlant = []
            for month in range(txMonthlyMaxFutGMT.shape[3]):
                demProjCurMonth = []
                
                tx = txMonthlyMaxFutGMT[w, model, plant, month]
                
                for d in range(len(demTempModels)):
                    txProj = demTempModels[d].predict([1, tx, tx**2, tx**3])
                    demProjCurMonth.append(txProj)
                
                demProjCurPlant.append(demProjCurMonth)
            demProjCurModel.append(demProjCurPlant)
        demProjCurGMT.append(demProjCurModel)
    demProj.append(demProjCurGMT)
demProj = np.squeeze(np.array(demProj))
demProj = np.nanmean(np.nanmean(demProj, axis=4), axis=2)

# calculate change factor between future modeled demand and historical
demMult = []
for w in range(demProj.shape[0]):
    demMultGMT = []
    for model in range(demProj.shape[1]):
        demMultModel = []
        for month in range(0, 12):
            demMultModel.append(demProj[w, model, month] / demHist[month])
        demMultGMT.append(demMultModel)
    demMult.append(demMultGMT)
demMult = np.array(demMult)

tx = demData['txScatter']
dem = demData['demTxScatter']
mon = demData['monthScatter']    

txAll = []
demAll = []
monAll = []

for s in range(tx.shape[0]):
    txAll.extend(tx[s])
    demAll.extend(dem[s])
    monAll.extend(mon[s])

txAll = np.array(txAll)
demAll = np.array(demAll) * 100
monAll = np.array(monAll)
    

# calculate historical demand by month
demByMonth = []
for m in range(1, 13):    
    ind = np.where(monAll == m)[0]
    demByMonth.append(np.array(np.nanmean(demAll[ind])))
demByMonth = np.array(demByMonth)
demByMonth = 1 + ((demByMonth - np.nanmean(demByMonth)) / (np.nanmax(demByMonth) - np.nanmin(demByMonth)))


# and multiply that historical demand by the modeled demand change factor due to warming
demByMonthFut = []
for w in range(4):
    demByMonthFutCurGMT = []
    for model in range(demMult.shape[1]):
        demByMonthFutCurModel = []
        for month in range(12):
            demByMonthFutCurModel.append(demByMonth[month] * demMult[w,model,month])
        demByMonthFutCurGMT.append(demByMonthFutCurModel)
    demByMonthFut.append(demByMonthFutCurGMT)
demByMonthFut = np.array(demByMonthFut)

demByMonthFutSorted = np.sort(demByMonthFut, axis=1)

plt.figure(figsize=(4,1))
plt.xlim([0, 13])
plt.ylim([.5, 2.3])
plt.grid(True, alpha=.5, color=[.9, .9, .9])

plt.plot([0,13], [1,1], '--k', lw=1)
plt.plot(list(range(1,13)), np.squeeze(np.nanmean(demByMonthFut[1,:,:], axis=0)), '-', lw=2, color='#ffb835')
plt.plot(list(range(1,13)), np.squeeze(demByMonthFutSorted[1,-1,:]), '--', lw=1, color='#ffb835')
plt.plot(list(range(1,13)), np.squeeze(np.nanmean(demByMonthFut[3,:,:], axis=0)), '-', lw=2, color=snsColors[1])
plt.plot(list(range(1,13)), np.squeeze(demByMonthFutSorted[3,-2,:]), '--', lw=1, color=snsColors[1])
plt.plot(list(range(1,13)), demByMonth, '-k', lw=2)

plt.xticks(list(range(1,13)))
plt.yticks([.6, 1, 1.5, 2])

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

#plt.xlabel('Month', fontname = 'Helvetica', fontsize=12)
#plt.ylabel('Generation', fontname = 'Helvetica', fontsize=12)

if plotFigs:
    plt.savefig('dem-by-month-wide.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)


mon = nukeData['plantMonthsAll']
qsAnom = nukePlants['qsAnom']
histQsByMonth = []

for m in range(1, 13):
    curMonth = []
    ind = np.where(entsoePlants['months'] == m)[0]
    curMonth.extend(np.nanmean(entsoePlants['qsAnom'][:, ind], axis=1))
    
    ind = np.where(mon[0,:] == m)[0]
    curMonth.extend(np.nanmean(qsAnom[:, ind], axis=1))
    histQsByMonth.append(curMonth)
    
histQsByMonth = np.array(histQsByMonth)
histQsByMonth = np.nanmean(histQsByMonth, axis=1)

qsMonthlyMeanFutGMTSorted = np.sort(np.nanmean(qsMonthlyMeanFutGMT, axis=2), axis=1)

plt.figure(figsize=(4,1))
plt.xlim([0, 13])
plt.ylim([-1, 1.3])
plt.grid(True, alpha=.5, color=[.9, .9, .9])

plt.plot([0,13], [0,0], '--k', lw=1)
plt.plot(list(range(1,13)), histQsByMonth, '-', lw=2, color='black')

plt.plot(list(range(1,13)), np.nanmean(np.nanmean(qsMonthlyMeanFutGMT[1,:,:,:], axis=1), axis=0), '-', lw=2, color='#ffb835')
plt.plot(list(range(1,13)), qsMonthlyMeanFutGMTSorted[1,0,:], '--', lw=1, color='#ffb835')
plt.plot(list(range(1,13)), np.nanmean(np.nanmean(qsMonthlyMeanFutGMT[3,:,:,:], axis=1), axis=0), '-', lw=2, color=snsColors[1])
plt.plot(list(range(1,13)), qsMonthlyMeanFutGMTSorted[3,0,:], '--', lw=1, color=snsColors[1])


#plt.plot(list(range(1,13)), np.nanmean(qsAnomMonthlyMeanFut[ind10[0],:,:], axis=0), '--', lw=1, color='#8c4e23')
#plt.plot(list(range(1,13)), np.nanmean(np.nanmean(qsAnomMonthlyMeanFut, axis=1), axis=0), '-', lw=3, color='#8c4e23')
#plt.plot(list(range(1,13)), np.nanmean(qsAnomMonthlyMeanFut[ind90[0],:,:], axis=0), '--', lw=1, color='#8c4e23')

plt.xticks(list(range(1,13)))
plt.yticks([-.5, 0, .7])
         
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

if plotFigs:
    plt.savefig('qs-by-month-wide.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)


sys.exit()


lats = np.array([float(x) for x in nukePlants['plantLats']])
temps = np.nanmean(nukePlants['txSummer'], axis=1)
plantCaps = 100-nukePlants['capacitySummer']

X = sm.add_constant(temps)
mdl = sm.OLS(np.nanmean(plantCaps,axis=1),X).fit()

z = np.polyfit(temps, np.nanmean(plantCaps,axis=1), 1)
p = np.poly1d(z)

xd = np.arange(24, 37)

plt.figure(figsize=(4,4))
plt.xlim([21, 40])
plt.ylim([-.2, 20])
plt.grid(True, alpha=.5)

plt.scatter(temps,np.nanmean(plantCaps,axis=1), s=50, c='gray', edgecolors='black')
plt.plot(xd, p(xd), '--', color=snsColors[1], linewidth=3)

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

plt.xlabel('Mean summer Tx ($\degree$C)', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Mean summer outage (%)', fontname = 'Helvetica', fontsize=16)

plt.gca().set_yticks(range(0,21,4))

x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

if plotFigs:
    plt.savefig('outages-by-mean-temp.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)



plantYears = nukePlants['plantYears']
plantMonths = nukePlants['plantMonths']

meanOutageYear = []

for y in np.unique(plantYears[0]):
    indYr = np.where((plantYears[0] == y) & ((plantMonths[0] == 7) | (plantMonths[0] == 8)))[0]
    meanOutageYear.append(100-np.array(np.nanmean(cap[:,indYr], axis=1)))
meanOutageYear = np.array(meanOutageYear)



plt.figure(figsize=(4,4))
plt.xlim([0, 13])
plt.ylim([0, 12.25])
plt.grid(True, alpha=.5)

plt.plot(range(1,12+1), np.nanmean(meanOutageYear, axis=1), '-', color='gray', linewidth=5)
plt.errorbar(range(1,12+1), np.nanmean(meanOutageYear, axis=1), yerr=np.nanstd(meanOutageYear, axis=1)/2, lw=0, elinewidth=1.5, capsize=3, capthick=1.5, ecolor=[.25, .25, .25])
for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

plt.xlabel('Year', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Mean summer outage (%)', fontname = 'Helvetica', fontsize=16)

plt.gca().set_xticks(range(1,13))
xl = ['2007', '', '', '', \
      '2011', '', '', '2014', \
      '', '', '', '2018']
plt.gca().set_xticklabels(xl)

x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

if plotFigs:
    plt.savefig('outages-by-year.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)



X = sm.add_constant(normalCap)
mdl = sm.OLS(np.nanmean(plantCaps,axis=1),X).fit()

z = np.polyfit(normalCap, np.nanmean(plantCaps,axis=1), 1)
p = np.poly1d(z)

xd = np.arange(500, 3900)

plt.figure(figsize=(4,4))
plt.xlim([0, 4500])
plt.ylim([-.2, 20])
plt.grid(True, alpha=.5)

plt.scatter(normalCap, np.nanmean(plantCaps,axis=1), s=50, c='gray', edgecolors='black')
plt.plot(xd, p(xd), '--', color=snsColors[1], linewidth=3)

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

plt.xlabel('Plant design capacity (MW)', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Mean summer outage (%)', fontname = 'Helvetica', fontsize=16)

plt.gca().set_yticks(range(0,21,4))

x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

if plotFigs:
    plt.savefig('outages-by-plant-design-capacity.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)



plt.show()