# -*- coding: utf-8 -*-
"""
Created on Thu May  2 16:32:08 2019

@author: Ethan
"""


import numpy as np
import pandas as pd
from sklearn import linear_model
import statsmodels.api as sm
import el_entsoe_utils
import el_nuke_utils

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDir = 'e:/data/'

def buildLinearTempPPModel(useEra):
    entsoeData = el_entsoe_utils.loadEntsoeWithLatLon(dataDir)
    entsoePlantData = el_entsoe_utils.matchEntsoeWxPlantSpecific(entsoeData, useEra=useEra)
    entsoeAgData = el_entsoe_utils.aggregateEntsoeData(entsoePlantData)
    
    nukeData = el_nuke_utils.loadNukeData(dataDir)
    nukeTx, nukeTxIds = el_nuke_utils.loadWxData(nukeData, useEra=useEra)
    nukeAgData = el_nuke_utils.accumulateNukeWxData(nukeData, nukeTx, nukeTxIds)
    
    
    xtotal = []
    xtotal.extend(nukeAgData['txSummer'])
    xtotal.extend(entsoeAgData['txSummer'])
    xtotal = np.array(xtotal)
    
    ytotal = []
    ytotal.extend(nukeAgData['capacitySummer'])
    ytotal.extend(100*entsoeAgData['capacitySummer'])
    ytotal = np.array(ytotal)
    
    plantid = []
    plantid.extend(nukeAgData['plantIds'])
    plantid.extend(entsoeAgData['plantIds'])
    plantid = np.array(plantid)
    
    plantMonths = []
    plantMonths.extend(nukeAgData['plantMonths'])
    plantMonths.extend(entsoeAgData['plantMonths'])
    plantMonths = np.array(plantMonths)
    
    plantDays = []
    plantDays.extend(nukeAgData['plantDays'])
    plantDays.extend(entsoeAgData['plantDays'])
    plantDays = np.array(plantDays)
    
    plantMeanTemps = []
    plantMeanTemps.extend(nukeAgData['plantMeanTemps'])
    plantMeanTemps.extend(entsoeAgData['plantMeanTemps'])
    plantMeanTemps = np.array(plantMeanTemps)
    
    np.random.seed(1493)
    
    resampleInd = np.array(list(range(len(xtotal)))) #np.random.choice(len(xtotal), int(.1 * len(xtotal)))
    
    
    data = {'Temp':xtotal[resampleInd], 'Temp2':xtotal[resampleInd]**2, \
            'PlantID':plantid[resampleInd], \
            'PlantMonths':plantMonths[resampleInd], 'PlantDays':plantDays[resampleInd], \
            'PlantMeanTemps':plantMeanTemps[resampleInd], \
            'PC':ytotal[resampleInd]}
    df = pd.DataFrame(data, \
                      columns=['Temp', 'Temp2', 'PlantID', 'PlantMeanTemps', 'PlantMonths', 'PlantDays', 'PC'])
    
    X = df[['Temp']]#, 'PlantMeanTemps', 'PlantMonths']]#, 'PlantMeanTemps', 'PlantMonths']]#, 'PlantID', 'PlantMonths', 'PlantDays']]
    Y = df['PC']
    
    regr = linear_model.LinearRegression()
    regr.fit(X, Y)
    
    
    X = sm.add_constant(X) 
    model = sm.OLS(Y, X).fit()
    
    return (regr, model)


def buildPoly3TempPPModel(useEra):
    entsoeData = el_entsoe_utils.loadEntsoeWithLatLon(dataDir)
    entsoePlantData = el_entsoe_utils.matchEntsoeWxPlantSpecific(entsoeData, useEra=useEra)
    entsoeAgData = el_entsoe_utils.aggregateEntsoeData(entsoePlantData)
    
    nukeData = el_nuke_utils.loadNukeData(dataDir)
    nukeTx, nukeTxIds = el_nuke_utils.loadWxData(nukeData, useEra=useEra)
    nukeAgData = el_nuke_utils.accumulateNukeWxData(nukeData, nukeTx, nukeTxIds)
    
    
    xtotal = []
    xtotal.extend(nukeAgData['txSummer'])
    xtotal.extend(entsoeAgData['txSummer'])
    xtotal = np.array(xtotal)
    
    ytotal = []
    ytotal.extend(nukeAgData['capacitySummer'])
    ytotal.extend(100*entsoeAgData['capacitySummer'])
    ytotal = np.array(ytotal)
    
       
    data = {'Temp':xtotal, 'PC':ytotal}
    df = pd.DataFrame(data, columns=['Temp', 'PC'])
    
    z = np.polyfit(df['Temp'], df['PC'], 3)
    p = np.poly1d(z)
    
    return (z,p)



def exportNukeEntsoePlantLocations():
    entsoeData = el_entsoe_utils.loadEntsoeWithLatLon(dataDir)
    
    uniqueLat, uniqueLatInds = np.unique(entsoeData['lats'], return_index=True)
    entsoeLat = np.array(entsoeData['lats'][uniqueLatInds])
    entsoeLon = np.array(entsoeData['lons'][uniqueLatInds])
    
    nukeData = el_nuke_utils.loadNukeData(dataDir)
    nukeTx, nukeTxIds = el_nuke_utils.loadWxData(nukeData, useEra=True)
    
    nukeLat = []
    nukeLon = []
    
    for i in range(nukeTxIds.shape[0]):
        nukeLat.append(nukeData[nukeTxIds[i,0]]['lat'])
        nukeLon.append(nukeData[nukeTxIds[i,0]]['lon'])
    
    nukeLat = np.array(nukeLat)
    nukeLon = np.array(nukeLon)

    import csv
    n = 0
    with open('entsoe-nuke-lat-lon.csv', 'w') as f:
        csvWriter = csv.writer(f)    
        for i in range(len(entsoeLat)):
            csvWriter.writerow([n, entsoeLat[i], entsoeLon[i]])
            n += 1
        for i in range(len(nukeLat)):
            csvWriter.writerow([n, nukeLat[i], nukeLon[i]])
            n += 1









    
    