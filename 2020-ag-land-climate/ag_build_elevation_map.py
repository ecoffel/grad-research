# -*- coding: utf-8 -*-
"""
Created on Thu Oct 17 18:24:29 2019

@author: Ethan
"""

import numpy as np
import rasterio
import glob
import sys
import pickle

elevationDir = 'e:/data/elevation'
files = glob.glob('%s/*.tif'%elevationDir)

lat = np.linspace(90, -90, 360)
lon = np.linspace(-180, 180, 720)
lonStep = lon[1]-lon[0]
latStep = lat[1]-lat[0]

elevationMap = np.zeros([len(lat), len(lon)])

for file in files:
    
    print('processing %s...'%file)
    
    elev = rasterio.open(file)
    elevData = elev.read(1)
    
    tl_lat = elev.bounds.top
    tl_lon = elev.bounds.left
    br_lat = elev.bounds.bottom
    br_lon = elev.bounds.right
    
    xStep = elev.transform[1]
    yStep = elev.transform[5]

    mapYLeft = np.where(abs(lon-tl_lon) == np.nanmin(abs(lon-tl_lon)))[0][0]
    mapYRight = np.where(abs(lon-br_lon) == np.nanmin(abs(lon-br_lon)))[0][0]
    
    mapXTop = np.where(abs(lat-tl_lat) == np.nanmin(abs(lat-tl_lat)))[0][0]
    mapXBottom = np.where(abs(lat-br_lat) == np.nanmin(abs(lat-br_lat)))[0][0]

    print((mapYLeft, mapYRight, mapXTop, mapXBottom))

    for x in range(min(mapXTop, mapXBottom), max(mapXTop, mapXBottom)+1):
        for y in range(min(mapYLeft, mapYRight), max(mapYLeft, mapYRight)+1):
            
            if x >= elevationMap.shape[0] or y >= elevationMap.shape[1]:
                continue
            
            mapCoordX_tl = int(round((tl_lat-lat[x])/xStep))
            mapCoordX_br = int(round((tl_lat-(lat[x]+latStep))/xStep))
            
            mapCoordY_tl = int(round((tl_lon-lon[y])/yStep))
            mapCoordY_br = int(round((tl_lon-(lon[y]+lonStep))/yStep))

            if mapCoordY_br >= elevData.shape[1]:
                mapCoordY_br = elevData.shape[1]
            
            if mapCoordX_br >= elevData.shape[0]:
                mapCoordX_br = elevData.shape[0]

            meanElev = np.nanmean(np.nanmean(elevData[mapCoordX_tl:mapCoordX_br, mapCoordY_tl:mapCoordY_br]))
            if not np.isnan(meanElev):
                elevationMap[x,y] = meanElev

with open('elevation-map.dat', 'wb') as f:
    pickle.dump(elevationMap, f)










        