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
#dataDir = 'e:/data/'
dataDirDiscovery = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/projects/electricity'


def buildNonlinearTempQsPPModel(tempVar, qsVar, nBootstrap):
    
    entsoeQsVar = qsVar
    if qsVar == 'qsNldasAnomSummer':
        entsoeQsVar = 'qsAnomSummer'
    elif qsVar == 'qsNldasPercentileSummer':
        entsoeQsVar = 'qsPercentileSummer'
    
    eData = {}
    with open('%s/script-data/eData.dat'%dataDirDiscovery, 'rb') as f:
        eData = pickle.load(f)

    entsoeAgDataAll = eData['entsoeAgDataAll']
    nukeAgDataAll = eData['nukeAgDataAll']
    
    txtotal = []
    txtotal.extend(nukeAgDataAll[tempVar])
    txtotal.extend(entsoeAgDataAll[tempVar])
    txtotal = np.array(txtotal)
    
    qstotal = []
    qstotal.extend(nukeAgDataAll[qsVar])
    qstotal.extend(entsoeAgDataAll[entsoeQsVar])
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
    
    # we find indices for one of each plant id
    uniquePlantIds = []
    for p in np.unique(plantIds):
        uniquePlantIds.append(np.where(plantIds==p)[0][0])
    
    for i in range(nBootstrap):
        if i%50 == 0: print('%.0f%% complete'%(i/nBootstrap*100.0))
        
        # we generate random indices for bootstrapping, leaving spaces for 1 instance of every plant id
        curInd = np.random.choice(len(txtotal), int(len(txtotal))-len(list(np.unique(plantIds))))
		
        # insert each instance of plant id found before - this is to ensure that all plant ids are present in every model at least once,
        # as otherwise model predictions may fail
        curInd = np.concatenate((curInd, uniquePlantIds))
        
        data = {'T1':txtotal[curInd], 'T2':txtotal[curInd]**2, \
                'QS1':qstotal[curInd], 'QS2':qstotal[curInd]**2, \
                'QST':txtotal[curInd]*qstotal[curInd], 'QS2T2':(txtotal[curInd]**2)*(qstotal[curInd]**2), \
                'PlantIds':plantIds[curInd], 'PlantYears':plantYears[curInd], 'PC':pctotal[curInd]}
        
        df = pd.DataFrame(data, \
                          columns=['T1', 'T2', \
                                   'QS1', 'QS2', \
                                   'QST', 'QS2T2', \
                                   'PlantIds', 'PlantYears', \
                                   'PC'])
        df = df.dropna()
        
		# build the FE model - the 'C' operator marks those variables as fixed effects (from R-style syntax)
        mdl=smf.ols(formula='PC ~ T1 + T2 + QS1 + QS2 + QST + QS2T2 + C(PlantIds) + C(PlantYears)', data=df).fit()
#         mdl=smf.ols(formula='PC ~ T1 + T2 + QS1 + QS2 + QST + C(PlantIds) + C(PlantYears)', data=df).fit()
        models.append(mdl)
    
    models = np.array(models)

    return models, plantIds, plantYears, txtotal, qstotal

def exportNukeEntsoePlantLocations(dataDir):
    
    eData = {}
    with open('%s/script-data/eData.dat'%dataDir, 'rb') as f:
        eData = pickle.load(f) 
    
    entsoeData = eData['entsoePlantDataAll']
    nukeData = eData['nukePlantDataAll']
    
    entsoeLat = entsoeData['lats']
    entsoeLon = entsoeData['lons']
    entsoeIds = entsoeData['plantIds']
    entsoeCap = entsoeData['capacity']
    
#    uniqueLat, uniqueLatInds = np.unique(entsoeData['lats'], return_index=True)
#    entsoeLat = np.array(entsoeData['lats'][uniqueLatInds])
#    entsoeLon = np.array(entsoeData['lons'][uniqueLatInds])
        
    nukeLat = []
    nukeLon = []
    nukeIds = []
    nukeCap = []
    
    for i in range(len(nukeData['plantLats'])):
        nukeLat.append(nukeData['plantLats'][i])
        nukeLon.append(nukeData['plantLons'][i])
        nukeIds.append(nukeData['plantIds'][i])
        nukeCap.append(nukeData['capacity'][i])
    
    nukeLat = np.array(nukeLat)
    nukeLon = np.array(nukeLon)
    nukeIds = np.array(nukeIds)
    sys.exit()
    import csv
    n = 0
    with open('%s/script-data/entsoe-nuke-lat-lon.csv'%dataDir, 'w') as f:
        csvWriter = csv.writer(f)    
        for i in range(len(entsoeLat)):
            csvWriter.writerow([entsoeIds[i], entsoeLat[i], entsoeLon[i]])
            n += 1
        for i in range(len(nukeLat)):
            csvWriter.writerow([nukeIds[i], nukeLat[i], nukeLon[i]])
            n += 1


