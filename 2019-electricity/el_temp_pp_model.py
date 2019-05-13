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

def buildLinearTempPPModel():
    
    entsoeData = el_entsoe_utils.loadEntsoeWithLatLon(dataDir)
    entsoePlantDataEra = el_entsoe_utils.matchEntsoeWxPlantSpecific(entsoeData, wxdata='era')
    entsoePlantDataCpc = el_entsoe_utils.matchEntsoeWxPlantSpecific(entsoeData, wxdata='cpc')
    entsoePlantDataNcep = el_entsoe_utils.matchEntsoeWxPlantSpecific(entsoeData, wxdata='ncep')
#    entsoePlantData = el_entsoe_utils.matchEntsoeWxCountry(entsoeData, useEra=useEra)
    entsoeAgDataEra = el_entsoe_utils.aggregateEntsoeData(entsoePlantDataEra)
    entsoeAgDataCpc = el_entsoe_utils.aggregateEntsoeData(entsoePlantDataCpc)
    entsoeAgDataNcep = el_entsoe_utils.aggregateEntsoeData(entsoePlantDataNcep)
    
    nukeData = el_nuke_utils.loadNukeData(dataDir)
    
    nukeTxEra, nukeTxIdsEra = el_nuke_utils.loadWxData(nukeData, wxdata='era')
    nukeTxCpc, nukeTxIdsCpc = el_nuke_utils.loadWxData(nukeData, wxdata='cpc')
    nukeTxNcep, nukeTxIdsNcep = el_nuke_utils.loadWxData(nukeData, wxdata='ncep')
    
    nukeAgDataEra = el_nuke_utils.accumulateNukeWxData(nukeData, nukeTxEra, nukeTxIdsEra)
    nukeAgDataCpc = el_nuke_utils.accumulateNukeWxData(nukeData, nukeTxCpc, nukeTxIdsCpc)
    nukeAgDataNcep = el_nuke_utils.accumulateNukeWxData(nukeData, nukeTxNcep, nukeTxIdsNcep)

    
    xtotal = []
    xtotal.extend(nukeAgDataEra['txSummer'])
    xtotal.extend(nukeAgDataCpc['txSummer'])
    xtotal.extend(nukeAgDataNcep['txSummer'])
    
    xtotal.extend(entsoeAgDataEra['txSummer'])
    xtotal.extend(entsoeAgDataCpc['txSummer'])
    xtotal.extend(entsoeAgDataNcep['txSummer'])
    xtotal = np.array(xtotal)
    
    ytotal = []
    ytotal.extend(nukeAgDataEra['capacitySummer'])
    ytotal.extend(nukeAgDataCpc['capacitySummer'])
    ytotal.extend(nukeAgDataNcep['capacitySummer'])
    
    ytotal.extend(100*entsoeAgDataEra['capacitySummer'])
    ytotal.extend(100*entsoeAgDataCpc['capacitySummer'])
    ytotal.extend(100*entsoeAgDataNcep['capacitySummer'])
    ytotal = np.array(ytotal)
    
    
#    data = {'Temp':xtotal[resampleInd], 'Temp2':xtotal[resampleInd]**2, \
#            'PlantID':plantid[resampleInd], \
#            'PlantMonths':plantMonths[resampleInd], 'PlantDays':plantDays[resampleInd], \
#            'PlantMeanTemps':plantMeanTemps[resampleInd], \
#            'PC':ytotal[resampleInd]}
#    df = pd.DataFrame(data, \
#                      columns=['Temp', 'Temp2', 'PlantID', 'PlantMeanTemps', 'PlantMonths', 'PlantDays', 'PC'])
#    
    data = {'Temp':xtotal, 'PC':ytotal}
    df = pd.DataFrame(data, \
                      columns=['Temp', 'PC'])
    
    df = df.dropna()
    
    X = df[['Temp']]#, 'PlantMeanTemps', 'PlantMonths']]#, 'PlantMeanTemps', 'PlantMonths']]#, 'PlantID', 'PlantMonths', 'PlantDays']]
    Y = df['PC']
    
    regr = linear_model.LinearRegression()
    regr.fit(X, Y)
        
    X = sm.add_constant(X) 
    model = sm.OLS(Y, X).fit()
    
    return (regr, model)


def buildPoly3TempPPModel():
    entsoeData = el_entsoe_utils.loadEntsoeWithLatLon(dataDir)
    entsoePlantDataEra = el_entsoe_utils.matchEntsoeWxPlantSpecific(entsoeData, wxdata='era')
    entsoePlantDataCpc = el_entsoe_utils.matchEntsoeWxPlantSpecific(entsoeData, wxdata='cpc')
    entsoePlantDataNcep = el_entsoe_utils.matchEntsoeWxPlantSpecific(entsoeData, wxdata='ncep')
#    entsoePlantData = el_entsoe_utils.matchEntsoeWxCountry(entsoeData, useEra=useEra)
    entsoeAgDataEra = el_entsoe_utils.aggregateEntsoeData(entsoePlantDataEra)
    entsoeAgDataCpc = el_entsoe_utils.aggregateEntsoeData(entsoePlantDataCpc)
    entsoeAgDataNcep = el_entsoe_utils.aggregateEntsoeData(entsoePlantDataNcep)
    
    nukeData = el_nuke_utils.loadNukeData(dataDir)
    
    nukeTxEra, nukeTxIdsEra = el_nuke_utils.loadWxData(nukeData, wxdata='era')
    nukeTxCpc, nukeTxIdsCpc = el_nuke_utils.loadWxData(nukeData, wxdata='cpc')
    nukeTxNcep, nukeTxIdsNcep = el_nuke_utils.loadWxData(nukeData, wxdata='ncep')
    
    nukeAgDataEra = el_nuke_utils.accumulateNukeWxData(nukeData, nukeTxEra, nukeTxIdsEra)
    nukeAgDataCpc = el_nuke_utils.accumulateNukeWxData(nukeData, nukeTxCpc, nukeTxIdsCpc)
    nukeAgDataNcep = el_nuke_utils.accumulateNukeWxData(nukeData, nukeTxNcep, nukeTxIdsNcep)

    
    xtotal = []
    xtotal.extend(nukeAgDataEra['txSummer'])
    xtotal.extend(nukeAgDataCpc['txSummer'])
    xtotal.extend(nukeAgDataNcep['txSummer'])
    
    xtotal.extend(entsoeAgDataEra['txSummer'])
    xtotal.extend(entsoeAgDataCpc['txSummer'])
    xtotal.extend(entsoeAgDataNcep['txSummer'])
    xtotal = np.array(xtotal)
    
    ytotal = []
    ytotal.extend(nukeAgDataEra['capacitySummer'])
    ytotal.extend(nukeAgDataCpc['capacitySummer'])
    ytotal.extend(nukeAgDataNcep['capacitySummer'])
    
    ytotal.extend(100*entsoeAgDataEra['capacitySummer'])
    ytotal.extend(100*entsoeAgDataCpc['capacitySummer'])
    ytotal.extend(100*entsoeAgDataNcep['capacitySummer'])
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









    
    