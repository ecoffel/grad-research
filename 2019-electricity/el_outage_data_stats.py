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
import sys,os

import el_build_temp_demand_model

import warnings
warnings.filterwarnings('ignore')

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
# dataDir = 'e:/data/'
dataDirDiscovery = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/projects/electricity'

plotFigs = False


if not 'eData' in locals():
    eData = {}
    with open('%s/script-data/eData.dat'%dataDirDiscovery, 'rb') as f:
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

#plt.tick_params(
#    axis='x',          # changes apply to the x-axis
#    which='both',      # both major and minor ticks are affected
#    bottom=False,      # ticks along the bottom edge are off
#    top=False,         # ticks along the top edge are off
#    labelbottom=False) # labels along the bottom edge are off

plt.xlabel('Month', fontname = 'Helvetica', fontsize=12)
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
    for y in np.unique(entsoePlants['years']):
        ind = np.where(entsoePlants['months'] == m)[0]
        curMonth.extend(np.nanmean(entsoePlants['tx'][:, ind], axis=1))
    
    for y in np.unique(nukeData['plantYearsAll']):
        ind = np.where((nukeData['plantMonthsAll'][0,:] == m) & \
                       (nukeData['plantYearsAll'][0,:] == y))[0]
        curMonth.extend(np.nanmax(nukePlants['tx'][:, ind], axis=1))
    
    histTempsByMonth.append(np.nanmean(curMonth))

histTempsByMonth = np.array(histTempsByMonth)
#histTempsByMonth = np.nanmean(histTempsByMonth, axis=1)

histTemps20CR = []
temps20CR = np.genfromtxt('%s/script-data/entsoe-nuke-pp-tx-20cr-1850-1900.csv'%dataDirDiscovery, delimiter=',')
temps20CRMonths = temps20CR[1,:]
temps20CR = temps20CR[2:,:]

for m in range(1, 13):
    ind = np.where(temps20CRMonths == m)[0]
    histTemps20CR.append(np.nanmean(np.nanmean(temps20CR[:,ind])))
histTemps20CR = np.array(histTemps20CR)


histTemps1981_2018 = []
temps1981_2018 = np.genfromtxt('%s/script-data/entsoe-nuke-pp-tx-1981-2018.csv'%dataDirDiscovery, delimiter=',')
temps1981_2018Years = temps1981_2018[0,:]
temps1981_2018Months = temps1981_2018[1,:]
temps1981_2018Days = temps1981_2018[2,:]
temps1981_2018 = temps1981_2018[3:,:]

for m in range(1, 13):
    curMonthMax = np.full([temps1981_2018.shape[0], len(np.unique(temps1981_2018Years))], np.nan)
    for y, year in enumerate(np.unique(temps1981_2018Years)):
        ind = np.where((temps1981_2018Years == year) & (temps1981_2018Months == m))[0]
        curMonthMax[:, y] = np.nanmax(temps1981_2018[:,ind], axis=1)
    histTemps1981_2018.append(np.nanmean(curMonthMax, axis=1))
histTemps1981_2018 = np.nanmean(np.array(histTemps1981_2018), axis=1)


if not os.path.isfile('%s/script-data/outage-data-stats-tx-qs-monthly-mean-max-cmip5-gmt.dat'%dataDirDiscovery):

    # load future mean warming data and recompute PC
    txMonthlyMeanFutGMT = np.full([4, len(models), 113, 12], np.nan)
    txMonthlyMaxFutGMT = np.full([4, len(models), 113, 12], np.nan)
    qsMonthlyMeanFutGMT = np.full([4, len(models), 113, 12], np.nan)

    for w in range(1, 4+1):

        for m in range(len(models)):

            print('finding max/mean for %s/%d'%(models[m], w))

            # load data for current model and warming level
            fileNameTemp = '%s/gmt-anomaly-temps/entsoe-nuke-pp-%ddeg-tx-cmip5-%s.csv'%(dataDirDiscovery, w, models[m])
            if not os.path.isfile(fileNameTemp):
                print('skipping %s'%fileNameTemp)
                continue

            plantTxData = np.genfromtxt(fileNameTemp, delimiter=',', skip_header=0)        

            if len(plantTxData) == 0:
                continue

            plantTxYearData = plantTxData[0,:].copy()
            plantTxMonthData = plantTxData[1,:].copy()
            plantTxDayData = plantTxData[2,:].copy()
            plantTxData = plantTxData[3:,:].copy()

            fileNameRunoff = '%s/gmt-anomaly-temps/entsoe-nuke-pp-%ddeg-runoff-cmip5-%s.csv'%(dataDirDiscovery, w, models[m])

            if not os.path.isfile(fileNameRunoff):
                print('skipping %s'%fileNameRunoff)
                continue

            plantQsData = np.genfromtxt(fileNameRunoff, delimiter=',', skip_header=0)

            if len(plantQsData) == 0:
                continue

            plantQsYearData = plantTxData[0,:].copy()
            plantQsMonthData = plantTxData[1,:].copy()
            plantQsDayData = plantTxData[2,:].copy()
            plantQsData = plantQsData[3:,:].copy()

            # loop over all plants
            for p in range(plantTxData.shape[0]):

                plantTxMonthlyMeanGMT = np.full([len(range(int(min(plantTxYearData)), int(max(plantTxYearData))+1)), 12], np.nan)
                plantTxMonthlyMaxGMT = np.full([len(range(int(min(plantTxYearData)), int(max(plantTxYearData))+1)), 12], np.nan)
                plantQsMonthlyMeanGMT = np.full([len(range(int(min(plantTxYearData)), int(max(plantTxYearData))+1)), 12], np.nan)

                # tx,qs for current plant
                tx = plantTxData[p, :]
                qs = plantQsData[p, :]

                # loop over all years for current model/GMT anomaly
                for yearInd, year in enumerate(range(int(min(plantTxYearData)), int(max(plantTxYearData))+1)):

                    # and over all months
                    for month in range(1, 13):

                        # tx for current year's current month
                        ind = np.where((plantTxYearData == year) & (plantTxMonthData == month))[0]

                        curTx = tx[ind]
                        curQs = qs[ind]

                        nn = np.where((~np.isnan(curTx)) & (~np.isnan(curQs)))[0]

                        if len(nn) == 0:
                            continue

                        curTx = curTx[nn]
                        curQs = curQs[nn]

                        # ind of the txx day in this year/month
                        indTxx = np.where(curTx == np.nanmax(curTx))[0][0]

                        curTxx = curTx[indTxx]
                        curQsTxx = curQs[indTxx]

                        plantTxMonthlyMeanGMT[yearInd, month-1] = np.nanmean(curTx)
                        plantTxMonthlyMaxGMT[yearInd, month-1] = curTxx
                        plantQsMonthlyMeanGMT[yearInd, month-1] = np.nanmean(curQs)

                # average over years
                txMonthlyMeanFutGMT[w-1, m, p, :] = np.nanmean(plantTxMonthlyMeanGMT, axis=0)
                txMonthlyMaxFutGMT[w-1, m, p, :] = np.nanmean(plantTxMonthlyMaxGMT, axis=0)
                qsMonthlyMeanFutGMT[w-1, m, p, :] = np.nanmean(plantQsMonthlyMeanGMT, axis=0)

    txQsMaxMean = {'txMonthlyMeanFutGMT':txMonthlyMeanFutGMT, \
                   'txMonthlyMaxFutGMT':txMonthlyMaxFutGMT, \
                   'qsMonthlyMeanFutGMT':qsMonthlyMeanFutGMT}
    with open('%s/script-data/outage-data-stats-tx-qs-monthly-mean-max-cmip5-gmt.dat'%dataDirDiscovery, 'wb') as f:
        pickle.dump(txQsMaxMean, f)
else:
    with open('%s/script-data/outage-data-stats-tx-qs-monthly-mean-max-cmip5-gmt.dat'%dataDirDiscovery, 'rb') as f:
        txQsMaxMean = pickle.load(f)
        
        txMonthlyMeanFutGMT = txQsMaxMean['txMonthlyMeanFutGMT']
        txMonthlyMaxFutGMT = txQsMaxMean['txMonthlyMaxFutGMT']
        qsMonthlyMeanFutGMT = txQsMaxMean['qsMonthlyMeanFutGMT']
    
txMonthlyMaxFutGMTSorted = np.sort(np.nanmean(txMonthlyMaxFutGMT, axis=2), axis=1)

# find the models with the highest temps in the summer months
txSummerWorst = np.nanmean(np.nanmean(txMonthlyMaxFutGMT[:,:,:,[6,7]], axis=3), axis=2)
txMonthlyMaxFutGMT2Min = np.where(txSummerWorst[1,:] == np.nanmax(txSummerWorst[1,:]))[0][0]
txMonthlyMaxFutGMT4Min = np.where(txSummerWorst[3,:] == np.nanmax(txSummerWorst[3,:]))[0][0]


fig = plt.figure(figsize=(4,2))
plt.xlim([0, 13])
plt.ylim([8, 43])
plt.grid(True, alpha=.5, color=[.9, .9, .9])

# plt.plot(list(range(1,13)), histTempsByMonth, '-', lw=2, color='black')
plt.plot(list(range(1,13)), histTemps1981_2018, '-', lw=2, color='black')
plt.plot(list(range(1,13)), histTemps20CR, '-', lw=2, color=snsColors[0])

plt.plot(list(range(1,13)), np.nanmean(np.nanmean(txMonthlyMaxFutGMT[1,:,:,:],axis=1),axis=0), '-', lw=2, color='#ffb835')
plt.plot(list(range(1,13)), np.nanmean(txMonthlyMaxFutGMT[1,txMonthlyMaxFutGMT2Min,:,:], axis=0), '--', lw=1, color='#ffb835')
plt.plot(list(range(1,13)), np.nanmean(np.nanmean(txMonthlyMaxFutGMT[3,:,:,:],axis=1),axis=0), '-', lw=2, color=snsColors[1])
plt.plot(list(range(1,13)), np.nanmean(txMonthlyMaxFutGMT[3,txMonthlyMaxFutGMT4Min,:,:], axis=0), '--', lw=1, color=snsColors[1])

plt.xticks(list(range(1,13)))
plt.yticks(list(range(10,43,5)))
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
with open('%s/script-data/genData.dat'%dataDirDiscovery, 'rb') as f:
    demData = pickle.load(f)

demTempModels = el_build_temp_demand_model.buildNonlinearDemandModel(10)
sys.exit()

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



plantTxData = np.genfromtxt('%s/script-data/entsoe-nuke-pp-tx-1981-2018.csv'%dataDirDiscovery, delimiter=',')
plantTxDataYears = plantTxData[0,:]
plantTxDataMonths = plantTxData[1,:]
plantTxData = plantTxData[3:,:]

monthlyTxMaxHist1981_2018 = np.full([plantTxData.shape[0], len(np.unique(plantTxDataYears)), 12], np.nan)
for y, year in enumerate(np.unique(plantTxDataYears)):
    for m in range(1, 13):
        ind = np.where((plantTxDataYears == year) & (plantTxDataMonths == m))[0]
        maxTx = np.nanmax(plantTxData[:, ind], axis=1)
        monthlyTxMaxHist1981_2018[:, y, m-1] = maxTx
monthlyTxMaxHist1981_2018 = np.nanmean(monthlyTxMaxHist1981_2018, axis=1)

# 'plant-hist' for data from regression model
# 'entsoe-nuke-1981-2018' for era/cpc/ncep data for all trained plants
demStr = 'entsoe-nuke-1981-2018'

if os.path.isfile('%s/script-data/demand-projections-%s.dat'%(dataDirDiscovery, demStr)):
    with gzip.open('%s/script-data/demand-projections-%s.dat'%(dataDirDiscovery, demStr), 'rb') as f:
        demData = pickle.load(f)
    
    demHist = demData['demHist']
    demProj = demData['demProj']
    demMult = demData['demMult']
    demByMonth = demData['demByMonthHist']
    demByMonthFut = demData['demByMonthFut']
    
else:

    if demStr == 'plant-hist':
        demHistTxData = monthlyTxMaxHist
    elif demStr == 'entsoe-nuke-1981-2018':
        demHistTxData = monthlyTxMaxHist1981_2018
    
    demHist = []
    for plant in range(demHistTxData.shape[0]):
        demHistPlant = []
        for month in range(0,12):
            demHistMonth = []
            for d in range(len(demTempModels)):
                tx = demHistTxData[plant, month]
                txProj = demTempModels[d].predict([1, tx, tx**2])[0]
                demHistMonth.append(np.nanmean(txProj))
            
            demHistPlant.append(demHistMonth)
        demHist.append(demHistPlant)
    demHist = np.array(demHist)
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
                        txProj = demTempModels[d].predict([1, tx, tx**2])
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
    
    with gzip.open('%s/script-data/demand-projections-%s.dat'%(dataDirDiscovery, demStr), 'wb') as f:
        demData = {'demHist':demHist, \
                   'demProj':demProj, \
                   'demMult':demMult, \
                   'demByMonthHist':demByMonth, \
                   'demByMonthFut':demByMonthFut}
        pickle.dump(demData, f)

demByMonth = (demByMonth-1)*100
demByMonthFut = (demByMonthFut-1)*100
# demByMonthFutSorted = np.sort(demByMonthFut, axis=1)

# find the models with the lowest runoff anoms in the summer months
demSummerWorst = np.nanmean(demByMonthFut[:,:,[6,7]], axis=2)
demMonthlyMeanFutGMT2Min = np.where(demSummerWorst[1,:] == np.nanmax(demSummerWorst[1,:]))[0][0]
demMonthlyMeanFutGMT4Min = np.where(demSummerWorst[3,:] == np.nanmax(demSummerWorst[3,:]))[0][0]


plt.figure(figsize=(4,2))
plt.xlim([0, 13])
plt.ylim([-50, 130])
plt.grid(True, alpha=.5, color=[.9, .9, .9])

plt.plot([0,13], [1,1], '--k', lw=1)
plt.plot(list(range(1,13)), np.squeeze(np.nanmean(demByMonthFut[1,:,:], axis=0)), '-', lw=2, color='#ffb835')
plt.plot(list(range(1,13)), np.squeeze(demByMonthFut[1,demMonthlyMeanFutGMT2Min,:]), '--', lw=1, color='#ffb835')
plt.plot(list(range(1,13)), np.squeeze(np.nanmean(demByMonthFut[3,:,:], axis=0)), '-', lw=2, color=snsColors[1])
plt.plot(list(range(1,13)), np.squeeze(demByMonthFut[3,demMonthlyMeanFutGMT4Min,:]), '--', lw=1, color=snsColors[1])
plt.plot(list(range(1,13)), demByMonth, '-k', lw=2)

plt.xticks(list(range(1,13)))
plt.yticks([-40, 0, 50, 100])

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

plt.show()


mon = nukeData['plantMonthsAll']
qsAnom = nukePlants['qsGrdcAnom']
qsAnom[qsAnom>5] = np.nan
qsAnom[qsAnom<-5] = np.nan
histQsByMonth = []

for m in range(1, 13):
    curMonth = []
    ind = np.where(entsoePlants['months'] == m)[0]
    curMonth.extend(np.nanmean(entsoePlants['qsGrdcAnom'][:, ind], axis=1))
    
    ind = np.where(mon[0,:] == m)[0]
    curMonth.extend(np.nanmean(qsAnom[:, ind], axis=1))
    histQsByMonth.append(curMonth)
    
histQsByMonth = np.array(histQsByMonth)
histQsByMonth = np.nanmean(histQsByMonth, axis=1)


plantQsData = np.genfromtxt('%s/script-data/entsoe-nuke-pp-runoff-anom-gldas-1981-2018.csv'%dataDirDiscovery, delimiter=',')
plantQsDataYears = plantQsData[0,:]
plantQsDataMonths = plantQsData[1,:]
plantQsData = plantQsData[3:,:]

plantQsData[plantQsData < -5] = np.nan
plantQsData[plantQsData > 5] = np.nan

histQs1981_2018 = []
for m in range(1, 13):
    curMonthMax = np.full([plantQsData.shape[0], len(np.unique(plantQsDataYears))], np.nan)
    for y, year in enumerate(np.unique(plantQsDataYears)):
        ind = np.where((plantQsDataYears == year) & (plantQsDataMonths == m))[0]
        curMonthMax[:, y] = np.nanmax(plantQsData[:,ind], axis=1)
    histQs1981_2018.append(np.nanmean(curMonthMax, axis=1))
histQs1981_2018 = np.nanmean(np.array(histQs1981_2018), axis=1)

qsMonthlyMeanFutGMTSorted = np.sort(np.nanmean(qsMonthlyMeanFutGMT[:,:,:,[6,7]], axis=2), axis=1)

# find the models with the lowest runoff anoms in the summer months
qsSummerWorst = np.nanmean(np.nanmean(qsMonthlyMeanFutGMT[:,:,:,[6,7]], axis=3), axis=2)
qsMonthlyMeanFutGMT2Min = np.where(qsSummerWorst[1,:] == np.nanmin(qsSummerWorst[1,:]))[0][0]
qsMonthlyMeanFutGMT4Min = np.where(qsSummerWorst[3,:] == np.nanmin(qsSummerWorst[3,:]))[0][0]

plt.figure(figsize=(4,2))
plt.xlim([0, 13])
plt.ylim([-2, 1])
plt.grid(True, alpha=.5, color=[.9, .9, .9])

plt.plot([0,13], [0,0], '--k', lw=1)
plt.plot(list(range(1,13)), histQs1981_2018, '-', lw=2, color='black')
# plt.plot(list(range(1,13)), histQsByMonth, '-', lw=2, color='black')

plt.plot(list(range(1,13)), np.nanmean(np.nanmean(qsMonthlyMeanFutGMT[1,:,:,:], axis=1), axis=0), '-', lw=2, color='#ffb835')
plt.plot(list(range(1,13)), np.nanmean(qsMonthlyMeanFutGMT[1,qsMonthlyMeanFutGMT2Min,:,:], axis=0), '--', lw=1, color='#ffb835')
plt.plot(list(range(1,13)), np.nanmean(np.nanmean(qsMonthlyMeanFutGMT[3,:,:,:], axis=1), axis=0), '-', lw=2, color=snsColors[1])
plt.plot(list(range(1,13)), np.nanmean(qsMonthlyMeanFutGMT[3,qsMonthlyMeanFutGMT4Min,:,:], axis=0), '--', lw=1, color=snsColors[1])

#plt.plot(list(range(1,13)), np.nanmean(qsAnomMonthlyMeanFut[ind10[0],:,:], axis=0), '--', lw=1, color='#8c4e23')
#plt.plot(list(range(1,13)), np.nanmean(np.nanmean(qsAnomMonthlyMeanFut, axis=1), axis=0), '-', lw=3, color='#8c4e23')
#plt.plot(list(range(1,13)), np.nanmean(qsAnomMonthlyMeanFut[ind90[0],:,:], axis=0), '--', lw=1, color='#8c4e23')

plt.xticks(list(range(1,13)))
plt.yticks([-1.5, -1, -.5, 0, .5])
         
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

    

    
plt.show()
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