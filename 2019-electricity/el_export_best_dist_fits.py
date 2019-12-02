import numpy as np
import pandas as pd
from sklearn import linear_model
import statsmodels.api as sm
import statsmodels.formula.api as smf
import pickle, gzip
import os, sys
import glob, csv

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
#dataDir = 'e:/data/'
dataDirDiscovery = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/projects/electricity'

# find all plants with dist fits
nukeDists = glob.glob('%s/dist-fits/best-fit-nuke-*-grdc.dat'%dataDirDiscovery)
entsoeDists = glob.glob('%s/dist-fits/best-fit-entsoe-*-grdc.dat'%dataDirDiscovery)

# select only the plant numbers
nukeDistFitPlantIds = []
for fit in nukeDists:
    parts = fit.split('/')
    parts = parts[-1].split('-')
    parts = int(parts[3])
    nukeDistFitPlantIds.append(parts)
nukeDistFitPlantIds.sort()

entsoeDistFitPlantIds = []
for fit in entsoeDists:
    parts = fit.split('/')
    parts = parts[-1].split('-')
    parts = int(parts[3])
    entsoeDistFitPlantIds.append(parts)
entsoeDistFitPlantIds.sort()

with open('%s/script-data/entsoe-nuke-pp-best-dist-fits.csv'%dataDirDiscovery, 'w') as f:
    csvWriter = csv.writer(f)    
    for pid in nukeDistFitPlantIds:
        with open('%s/dist-fits/best-fit-nuke-%d-grdc.dat'%(dataDirDiscovery, pid), 'rb') as f:
            distParams = pickle.load(f)
            std = distParams['std']
            if not np.isnan(std):
                std = round(std)
            csvWriter.writerow(['nuke-%d'%pid, distParams['name'], std])
    
    for pid in entsoeDistFitPlantIds:
        with open('%s/dist-fits/best-fit-entsoe-%d-grdc.dat'%(dataDirDiscovery, pid), 'rb') as f:
            distParams = pickle.load(f)
            std = distParams['std']
            if not np.isnan(std):
                std = round(std)
            csvWriter.writerow(['entsoe-%d'%pid, distParams['name'], std])