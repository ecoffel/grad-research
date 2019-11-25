import numpy as np
import matplotlib.pyplot as plt
import matplotlib.cm as cmx
import pickle, gzip
import sys, os, re
import geopy.distance
import calendar 
import csv
import xarray as xr
import rasterio
import shapefile
import shapely.geometry as geometry
import datetime, calendar

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
#dataDir = 'e:/data'
dataDirDiscovery = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/projects/electricity'

nukeLatLon = np.genfromtxt('%s/script-data/nuke-lat-lon.csv'%dataDirDiscovery, delimiter=',', skip_header=0)

startYearNuke = 2007
endYearNuke = 2018

# shp = shapefile.Reader('%s/basins/c_analysb.shp'%dataDirDiscovery)
# basins = shp.shapes()
# basinRecords = shp.records()


# find # of months in time period
nDays = 0
for year in range(startYearNuke, endYearNuke+1):
    for month in range(1, 12+1):
        curMonthRange = calendar.monthrange(year,month)
        for day in range(0, curMonthRange[1]):
            nDays += 1

qTimeSeriesNuke = np.full([nukeLatLon.shape[0], nDays+1], np.nan)

# set plant ids in first col
for p in range(nukeLatLon.shape[0]):
    qTimeSeriesNuke[p,0] = nukeLatLon[p,0]
    
# index for current starting year - start at 1 to skip plant id in first col
curDayInd = 1
for year in range(startYearNuke, endYearNuke+1):
    print('loading nldas for year %d...\n'%year)

    nldasVic = xr.open_mfdataset('/dartfs-hpc/rc/lab/C/CMIG/NLDAS/hourly/NLDAS_VIC0125_H.A%d*.nc4'%year, \
                                     decode_times=True, decode_cf=False, concat_dim='time')
    dims = nldasVic.dims
    curDate = datetime.datetime(year, 1, 1, 0, 0, 0)
    tDt = []
    while len(tDt) < nldasVic.time.size:
        tDt.append(curDate)
        curDate = curDate + datetime.timedelta(hours=1)
    nldasVic['time'] = tDt
    nldasVic = nldasVic.resample(time='1D').sum()
    nldasVic = nldasVic.BGRUN.where(abs(nldasVic['BGRUN']) < 1e10)
    nldasVic.load()
    
    for p in range(nukeLatLon.shape[0]):
        print('plant %d of %d\n'%(p+1, nukeLatLon.shape[0]))
        qsTmp = nldasVic.sel(lat=nukeLatLon[p,1], lon=nukeLatLon[p,2], method='nearest')

        curPlantCurDayInd = curDayInd
        
        for month in range(1, 12+1):
            curMonthRange = calendar.monthrange(year,month)
            for day in range(1, curMonthRange[1]+1):
                tmpQs = qsTmp.where((qsTmp['time.day'] == day) & (qsTmp['time.month'] == month), drop=True)
                if tmpQs.size > 0:
                    qTimeSeriesNuke[p, curPlantCurDayInd] = tmpQs.values[0]
                curPlantCurDayInd += 1
    
    # after setting vals for all plants in current year, update the global index
    curDayInd = curPlantCurDayInd

np.savetxt('%s/script-data/nuke-qs-nldas-all.csv'%(dataDirDiscovery), qTimeSeriesNuke, delimiter = ',', fmt = '%f')