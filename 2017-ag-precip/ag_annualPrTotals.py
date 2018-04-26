# -*- coding: utf-8 -*-
"""
Created on Thu Mar 29 13:43:14 2018

@author: Ethan
"""



import os
import sys
import glob
from subprocess import call
from netCDF4 import Dataset
import numpy as np
import scipy
from scipy import ndimage
import pickle
import gzip
import matplotlib.pyplot as plt

bins = np.array([0, 0.1, 1, 2.5, 5,10,15,20,25,30,35,40,45,50,55, 60,65, 70,75,80,85,90,95,100, 125,150,175,200,225,250])

baseDir = 'data\\stage4-hourly-pr\\counts'
inputDrive = 'E:\\'
outputDrive = 'E:\\'

lats = np.genfromtxt('C:/git-ecoffel/grad-research/2017-ag-precip/lats.csv', delimiter=',')
lons = np.genfromtxt('C:/git-ecoffel/grad-research/2017-ag-precip/lons.csv', delimiter=',')

filenames = glob.glob(inputDrive + baseDir + '\\*counts.dat')

monthlyTotals = []

for filename in filenames:
    
    f = gzip.open(filename, 'rb')
    data = pickle.load(f)
    
    shp = np.shape(data)
    
    monthlyTotals.append(0)
    
    gridcnt = 0
    
    for x in range(shp[0]):
        for y in range(shp[1]):
            
            if lats[x,y] < 32 or lats[x,y] > 40: continue
            if lons[x,y] > -83 or lons[x,y] < -105: continue

            gridcnt += 1

            for b in range(shp[2]):
                monthlyTotals[-1] += bins[b] * data[x,y,b]
            
    monthlyTotals[-1] /= gridcnt
    print('processed', filename, monthlyTotals[-1])
    

with open('monthly-totals.txt', 'w') as fp:
    for i in monthlyTotals:
        fp.write(str(i)+'\n')
