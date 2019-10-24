# -*- coding: utf-8 -*-
"""
Created on Thu May  2 16:32:08 2019

@author: Ethan
"""


import numpy as np
import pandas as pd
from sklearn import linear_model
import statsmodels.api as sm
import statsmodels.formula.api as smf
import pickle, gzip
import os

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDir = 'e:/data/'


def buildNonlinearTempQsPPModel(tempVar, qsVar, nBootstrap):
    
    eData = {}
    with open('script-data/eData.dat', 'rb') as f:
        eData = pickle.load(f)

    entsoeAgDataAll = eData['entsoeAgDataAll']
    nukeAgDataAll = eData['nukeAgDataAll']
    
    txtotal = []
    txtotal.extend(nukeAgDataAll[tempVar])
    txtotal.extend(entsoeAgDataAll[tempVar])
    txtotal = np.array(txtotal)
    
    qstotal = []
    qstotal.extend(nukeAgDataAll[qsVar])
    qstotal.extend(entsoeAgDataAll[qsVar])
    qstotal = np.array(qstotal)
    
    plantIds = []
    plantIds.extend(nukeAgDataAll['plantIds'])
    plantIds.extend(entsoeAgDataAll['plantIds'])
    plantIds = np.array(plantIds)
    
    plantYears = []
    plantYears.extend(nukeAgDataAll['plantYearsSummer'])
    plantYears.extend(entsoeAgDataAll['plantYears'])
    plantYears = np.array(plantYears)
    
    pctotal = []
    pctotal.extend(nukeAgDataAll['capacitySummer'])
    pctotal.extend(100*entsoeAgDataAll['capacitySummer'])
    pctotal = np.array(pctotal)
      
    ind = np.where((pctotal <= 100.1) & (txtotal > 20) & \
                   (~np.isnan(txtotal)) & (~np.isnan(qstotal)) & \
                   (~np.isnan(pctotal)))[0]
            
    txtotal = txtotal[ind]
    qstotal = qstotal[ind]
    plantIds = plantIds[ind]
    plantYears = plantYears[ind]
    pctotal = pctotal[ind]
    
    np.random.seed(1024)
    
    models = []
    
    for i in range(nBootstrap):
        if i%50 == 0: print('%.0f%% complete'%(i/nBootstrap*100.0))
        ind = np.random.choice(len(txtotal), int(len(txtotal)))
    
        data = {'T1':txtotal[ind], 'T2':txtotal[ind]**2, 'T3':txtotal[ind]**3, \
                'QS1':qstotal[ind], 'QS2':qstotal[ind]**2, 'QS3':qstotal[ind]**3, 'QS4':qstotal[ind]**4, 'QS5':qstotal[ind]**5, \
                'QST':txtotal[ind]*qstotal[ind], 'QS2T2':(txtotal[ind]**2)*(qstotal[ind]**2), \
                'PlantIds':plantIds[ind], 'PlantYears':plantYears[ind], 'PC':pctotal[ind]}
        
        df = pd.DataFrame(data, \
                          columns=['T1', 'T2', 'T3', \
                                   'QS1', 'QS2', 'QS3', 'QS4', 'QS5', \
                                   'QST', 'QS2T2', 'PlantIds', 'PlantYears', 'PC'])
        
        df = df.dropna()
        
#        X = sm.add_constant(df[['T1', 'T2', 'T3', \
#                                'QS1', 'QS2', 'QS3', 'QS4', 'QS5', 'QST', 'PlantIds']])
        
        mdl=smf.ols(formula='PC ~ T1 + T2 + QS1 + QS2 + QST + QS2T2 + C(PlantIds) + C(PlantYears)', data=df).fit()
#        X = sm.add_constant(df[['T1', 'T2', \
#                                'QS1', 'QS2', 'QST', 'QS2T2', 'PlantIds']])
#        mdl = sm.OLS(df['PC'], X).fit()
        models.append(mdl)
    
    models = np.array(models)

    return models, plantIds, plantYears

def exportNukeEntsoePlantLocations():
    
    eData = {}
    with open('eData.dat', 'rb') as f:
        eData = pickle.load(f) 
    
    entsoeData = eData['entsoePlantDataAll']
    nukeData = eData['nukePlantDataAll']
    
    entsoeLat = entsoeData['lats']
    entsoeLon = entsoeData['lons']
    entsoeIds = entsoeData['plantIds']
    
#    uniqueLat, uniqueLatInds = np.unique(entsoeData['lats'], return_index=True)
#    entsoeLat = np.array(entsoeData['lats'][uniqueLatInds])
#    entsoeLon = np.array(entsoeData['lons'][uniqueLatInds])
        
    nukeLat = []
    nukeLon = []
    nukeIds = []
    
    for i in range(len(nukeData['plantLats'])):
        nukeLat.append(nukeData['plantLats'][i])
        nukeLon.append(nukeData['plantLons'][i])
        nukeIds.append(nukeData['plantIds'][i])
    
    nukeLat = np.array(nukeLat)
    nukeLon = np.array(nukeLon)
    nukeIds = np.array(nukeIds)

    import csv
    n = 0
    with open('entsoe-nuke-lat-lon.csv', 'w') as f:
        csvWriter = csv.writer(f)    
        for i in range(len(entsoeLat)):
            csvWriter.writerow([entsoeIds[i], entsoeLat[i], entsoeLon[i]])
            n += 1
        for i in range(len(nukeLat)):
            csvWriter.writerow([nukeIds[i], nukeLat[i], nukeLon[i]])
            n += 1












    
    