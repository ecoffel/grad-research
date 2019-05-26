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
import pickle

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDir = 'e:/data/'

def buildLinearTempPPModel():
    
    eData = {}
    with open('eData.dat', 'rb') as f:
        eData = pickle.load(f)

    
    entsoeAgDataAll = eData['entsoeAgDataAll']
    nukeAgDataAll = eData['nukeAgDataAll']
    nukePlantDataAll = eData['nukePlantDataAll']

    xtotal = []
    xtotal.extend(nukeAgDataAll['txSummer'])
#    xtotal.extend(entsoeAgDataAll['txAvgSummer'])
    xtotal = np.array(xtotal)
    
    
    qstotal = []
    qstotal.extend(nukeAgDataAll['qsAnomSummer'])
    qstotal = np.array(qstotal)
    
    plantId = []
    plantId.extend(nukeAgDataAll['plantIds'])
    plantId = np.array(plantId)
    
    ytotal = []
    ytotal.extend(nukeAgDataAll['capacitySummer'])
#    ytotal.extend(100*entsoeAgDataAll['capacitySummer'])
    ytotal = np.array(ytotal)
    
    
#    data = {'Temp':xtotal[resampleInd], 'Temp2':xtotal[resampleInd]**2, \
#            'PlantID':plantid[resampleInd], \
#            'PlantMonths':plantMonths[resampleInd], 'PlantDays':plantDays[resampleInd], \
#            'PlantMeanTemps':plantMeanTemps[resampleInd], \
#            'PC':ytotal[resampleInd]}
#    df = pd.DataFrame(data, \
#                      columns=['Temp', 'Temp2', 'PlantID', 'PlantMeanTemps', 'PlantMonths', 'PlantDays', 'PC'])
#    
    
    ind = np.where((qstotal<-5))[0]
    data = {'Temp':xtotal[ind]**3, 'QS':qstotal[ind], 'PC':ytotal[ind]}
    df = pd.DataFrame(data, \
                      columns=['Temp', 'QS', 'PC'])
    
    df = df.dropna()
    
    X = df[['Temp']]#, 'PlantMeanTemps', 'PlantMonths']]#, 'PlantMeanTemps', 'PlantMonths']]#, 'PlantID', 'PlantMonths', 'PlantDays']]
    Y = df['PC']
    
    regr = linear_model.LinearRegression()
    regr.fit(X, Y)
        
    X = sm.add_constant(X) 
    model = sm.OLS(Y, X).fit()
    
    return (regr, model)


def buildPolyTempPPModel(tempVar, nBootstrap, order):
    eData = {}
    with open('eData.dat', 'rb') as f:
        eData = pickle.load(f)

    
    entsoeAgDataAll = eData['entsoeAgDataAll']
    nukeAgDataAll = eData['nukeAgDataAll']

    xtotal = []
    xtotal.extend(nukeAgDataAll[tempVar])
    xtotal.extend(entsoeAgDataAll[tempVar])
    xtotal = np.array(xtotal)
    
    ytotal = []
    ytotal.extend(nukeAgDataAll['capacitySummer'])
    ytotal.extend(100*entsoeAgDataAll['capacitySummer'])
    ytotal = np.array(ytotal)
      
    ind = np.where((ytotal <= 100.1) & (xtotal > 20))[0]
    xtotal = xtotal[ind]
    ytotal = ytotal[ind]
    
    pBootstrap = []
    zBootstrap = []
    
    for i in range(nBootstrap):
        resampleInd = np.random.choice(len(xtotal), int(len(xtotal)))
        
        data = {'Temp':xtotal[resampleInd], 'PC':ytotal[resampleInd]}
        df = pd.DataFrame(data, \
                          columns=['Temp', 'PC'])
        
        df = df.dropna()
        
        z = np.polyfit(df['Temp'], df['PC'], order)
        p = np.poly1d(z)
        zBootstrap.append(z)
        pBootstrap.append(p)
    
    return (zBootstrap,pBootstrap)



def exportNukeEntsoePlantLocations():
    entsoeData = el_entsoe_utils.loadEntsoeWithLatLon(dataDir)
    
    uniqueLat, uniqueLatInds = np.unique(entsoeData['lats'], return_index=True)
    entsoeLat = np.array(entsoeData['lats'][uniqueLatInds])
    entsoeLon = np.array(entsoeData['lons'][uniqueLatInds])
    
    nukeData = el_nuke_utils.loadNukeData(dataDir)
    nukeTx, nukeTxIds = el_nuke_utils.loadWxData(nukeData, wxdata='era')
    
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









    
    