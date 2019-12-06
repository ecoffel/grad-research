import matplotlib.pyplot as plt 
import matplotlib.cm as cmx
import seaborn as sns
import numpy as np
import pandas as pd
import pickle, gzip
import sys, os
import el_load_global_plants

dataDirDiscovery = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/projects/electricity'

# grdc or gldas
runoffData = 'grdc'

# world, useu, entsoe-nuke
plantData = 'world'

rcp = 'rcp85'

# these plants are in the same order as the ones loaded from the lat/lon csv
globalPlants = el_load_global_plants.loadGlobalPlants(world=True)

with open('%s/script-data/active-pp-inds-40-%s.dat'%(dataDirDiscovery, plantData), 'rb') as f:
    livingPlantsInds40 = pickle.load(f)

avgPlantSize = np.nanmean(globalPlants['caps'][livingPlantsInds40[2018]])/1e3

with open('%s/script-data/pc-at-txx-hist-%s-%s.dat'%(dataDirDiscovery, plantData, runoffData), 'rb') as f:
    pcChgHist = pickle.load(f)

    pcTxx10 = pcChgHist['pCapTxx10']
    pcTxx50 = pcChgHist['pCapTxx50']
    pcTxx90 = pcChgHist['pCapTxx90']
    
# this is mean curtailment from 1981-2005 (so 0C warming) using 2018 power plants
outagesHist10 = []
outagesHist50 = []
outagesHist90 = []
for p in livingPlantsInds40[2018]:
    plantCap = globalPlants['caps'][p]
    outagesHist10.append(plantCap*np.nanmean(pcTxx10[p])/100.0)
    outagesHist50.append(plantCap*np.nanmean(pcTxx50[p])/100.0)
    outagesHist90.append(plantCap*np.nanmean(pcTxx90[p])/100.0)
outagesHist10 = np.nansum(np.array(outagesHist10))/1e3
outagesHist50 = np.nansum(np.array(outagesHist50))/1e3
outagesHist90 = np.nansum(np.array(outagesHist90))/1e3

with open('%s/script-data/pc-change-scenarios-%s-%s-%s.dat'%(dataDirDiscovery, rcp, plantData, runoffData), 'rb') as f:
    outageScenarios = pickle.load(f)

outagesFutConst10 = np.nanmean(np.nansum(outageScenarios['const10'][:,-1,livingPlantsInds40[2018]],axis=1))
outagesFutConst50 = np.nanmean(np.nansum(outageScenarios['const50'][:,-1,livingPlantsInds40[2018]],axis=1))
outagesFutConst90 = np.nanmean(np.nansum(outageScenarios['const90'][:,-1,livingPlantsInds40[2018]],axis=1))

# global 2018 capacity in gw
totalCap = np.nansum(globalPlants['caps'][livingPlantsInds40[2018]])/1e3

capPerDeg10 = (outagesFutConst10-outagesHist10)/totalCap/4*100
capPerDeg50 = (outagesFutConst50-outagesHist50)/totalCap/4*100
capPerDeg90 = (outagesFutConst90-outagesHist90)/totalCap/4*100

plantsPerDeg10 = (outagesFutConst10-outagesHist10)/avgPlantSize/4
plantsPerDeg50 = (outagesFutConst50-outagesHist50)/avgPlantSize/4
plantsPerDeg90 = (outagesFutConst90-outagesHist90)/avgPlantSize/4

