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
import sys, os

curYear = int(sys.argv[1])

months = range(8,10)
inputDir = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/projects/rain-crops/'
outputDir = inputDir + 'output/counts_redrizzle/' + str(curYear) + '/'

bins = np.array([0,0.1,0.2,0.4,0.6,0.8,1.0,1.2,1.4,1.6,1.8,2.0,2.2,2.4,2.5])

for m in months:
    print('binning ' + str(m) + '/' + str(curYear) + '...')    
    skippedfiles = 0
    counts = np.nan*np.zeros((881, 1121, len(bins)))

    curDir = '%s/%d/%d0%d/'%(inputDir, curYear, curYear, m)
    if curYear > 2013 or (curYear == 2013 and m >= 8):
        fnames = glob.glob('%s/ST4.*.01'%(curDir))
    else:
        fnames = glob.glob('%s/ST4.*.01[h]'%(curDir))
    fnames.sort()
    
    for find, f in enumerate(fnames):
        if find%100 == 0:
            print('file # %d'%find)
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
                        if np.isnan(counts[x,y,0]):
                            counts[x,y,0] = 1
                        else:
                            counts[x,y,0] += 1
                    else:
                        ind = np.digitize(pr[x,y], bins)-1
                        if np.isnan(counts[x,y,ind]):
                            counts[x,y,ind] = 1
                        else:
                            counts[x,y,ind] += 1
    #make folder for this year if not existing                
    if not os.path.isdir(outputDir):
        os.mkdir(outputDir)
    
    #save count file for year/month        
    f = gzip.open(outputDir + 'counts' + str(curYear) + '0' + str(m) + '.dat', 'wb')
    pickle.dump(counts, f)
    f.close()
    
    #save missing file report    
    text_file = open(outputDir + 'skippedfiles' + str(curYear) + '0' + str(m) + '.txt',"w")
    skipstr = 'Skipped files report: Skipped ' + str(skippedfiles) + ' hourly files for this yearmonth.'
    text_file.write(skipstr)
    text_file.close()
    
    
