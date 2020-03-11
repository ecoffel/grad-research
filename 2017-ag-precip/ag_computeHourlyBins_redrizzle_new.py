# -*- coding: utf-8 -*-
"""
Created on Mon Jan 27 13:30:27 2020

@author: HAL 9000
"""


import xarray as xr
import os
import glob
import gzip
import numpy as np
import pickle

yr = 2002  #2002-2017

months = range(3,10)

curYear = int(sys.argv[1])

inputDir = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/projects/rain-crops/'
outputDir = inputDir + 'output/counts_redrizzle/' + str(curYear) + '/'

bins = np.array([0,0.1,0.2,0.4,0.6,0.8,1.0,1.2,1.4,1.6,1.8,2.0,2.2,2.4,2.5])

for m in months:
    print('binning ' + str(m) + str(yr) + '...')    
    skippedfiles = 0
    counts = np.zeros((881, 1121, len(bins)))

    
    inputDir = 'data\\st4\\raw\\' + str(yr) + '\\' + str(yr) + '0' + str(m) + '\\'
    fnames = glob.glob(inputDrive + inputDir + '\\ST4.' + str(yr) + '0' + str(m) + '*.01h')
    
    for f in fnames:
        ds = xr.open_dataset(f, engine='cfgrib')
        print(f)
        try:
            pr = ds['tp'].values
        except KeyError:
            skippedfiles += 1
            continue
        #loop space
        for x in range(pr.shape[0]):
            for y in range(pr.shape[1]):
                if ~np.isnan(pr[x,y]): 
                   
                    if pr[x,y] == 0:
                        counts[x,y,0] += 1
                    else:
                        ind = np.digitize(pr[x,y], bins)-1
                        counts[x,y,ind] += 1
    
    #make folder for this year if not existing                
    if not os.path.isdir(outputDir):
        os.mkdir(outputDir)
    
    #save count file for year/month        
    f = gzip.open(outputDir + 'counts' + str(yr) + '0' + str(m) + '.dat', 'wb')
    pickle.dump(counts, f)
    f.close()
    
    #save missing file report    
    text_file = open(outputDir + 'skippedfiles' + str(yr) + '0' + str(m) + '.txt',"w")
    skipstr = 'Skipped files report: Skipped ' + str(skippedfiles) + ' hourly files for this yearmonth.'
    text_file.write(skipstr)
    text_file.close()
    
    
