import rasterio as rio
import matplotlib.pyplot as plt 
import numpy as np
from scipy import interpolate
import statsmodels.api as sm
import scipy.stats as st
import os, sys, pickle, gzip
import geopy.distance
import datetime
import xarray as xr

cropAreaDataDir = 'HarvAreaYield_4Crops_95-00-05_Geotiff/HarvAreaYield_4Crops_95-00-05_Geotiff'
dataDirDiscovery = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/projects/ag-land-climate'


maizeArea1995Raw = rio.open('%s/%s/Maize/Maize_1995_Area.tif'%(dataDirDiscovery, cropAreaDataDir))
maizeArea1995 = maizeArea1995Raw.read(1)
maizeArea1995[maizeArea1995 < 0] = np.nan

maizeArea2000 = rio.open('%s/%s/Maize/Maize_2000_Area.tif'%(dataDirDiscovery, cropAreaDataDir))
maizeArea2000 = maizeArea2000.read(1)
maizeArea2000[maizeArea2000 < 0] = np.nan

maizeArea2005 = rio.open('%s/%s/Maize/Maize_2005_Area.tif'%(dataDirDiscovery, cropAreaDataDir))
maizeArea2005 = maizeArea2005.read(1)
maizeArea2005[maizeArea2005 < 0] = np.nan

latOld = np.linspace(maizeArea1995Raw.bounds.bottom, maizeArea1995Raw.bounds.top, maizeArea1995Raw.shape[0])
lonOld = np.linspace(maizeArea1995Raw.bounds.left, maizeArea1995Raw.bounds.right, maizeArea1995Raw.shape[1])

maizeArea1995Interp = interpolate.interp2d(lonOld, latOld, maizeArea1995, kind='linear')
maizeArea2000Interp = interpolate.interp2d(lonOld, latOld, maizeArea2000, kind='linear')
maizeArea2005Interp = interpolate.interp2d(lonOld, latOld, maizeArea2005, kind='linear')

latNew = np.linspace(90, -90, 360)
lonNew = np.linspace(-180, 180, 720)

maizeArea1995 = maizeArea1995Interp(lonNew, latNew)
maizeArea2000 = maizeArea2000Interp(lonNew, latNew)
maizeArea2005 = maizeArea2005Interp(lonNew, latNew)

# load growing seasons
sacksMaizeStart = np.genfromtxt('%s/sacks/sacks-planting-end-Maize.txt'%dataDirDiscovery, delimiter=',')
sacksMaizeEnd = np.genfromtxt('%s/sacks/sacks-harvest-start-Maize.txt'%dataDirDiscovery, delimiter=',')

with open('%s/script-data/elevation-map.dat'%dataDirDiscovery, 'rb') as f:
    elevationMap = pickle.load(f)

print('loading data')
dsMax = xr.open_mfdataset('/dartfs-hpc/rc/lab/C/CMIG/CPC/tmax/tmax.*.nc', decode_times=True, decode_cf=False, combine='by_coords')
dsMax.load()
dsMax = dsMax.tmax.where(dsMax['tmax'] > -100)

dims = dsMax.dims
startingDate = datetime.datetime(1900, 1, 1, 0, 0, 0)
tDt = []
print('computing new times')
for curTTime in dsMax.time:
    delta = datetime.timedelta(hours=int(curTTime.values))
    tDt.append(startingDate + delta)
dsMax['time'] = tDt

growingSeasonData = {}

for x, xlat in enumerate(latNew):
    print('processing %.1f'%xlat)
    for y, ylon in enumerate(lonNew):
        if sacksMaizeStart[x, y] > 0 and sacksMaizeEnd[x, y] > 0:
            curLat = latNew[x]
            curLon = lonNew[y]
            if curLon < 0: curLon += 360
            
            for year in range(1979, 2018+1):
                curTmax = dsMax.sel(lat=curLat, lon=curLon, time=dsMax.time.dt.year.isin([year]), method='nearest')
                if not x in growingSeasonData.keys():
                    growingSeasonData[x] = {}
                else:
                    if not y in growingSeasonData[x].keys():
                        growingSeasonData[x][y] = curTmax[int(sacksMaizeStart[x, y]):int(sacksMaizeEnd[x, y])]
                    else:
                        growingSeasonData[x][y] = xr.concat([growingSeasonData[x][y], curTmax[int(sacksMaizeStart[x, y]):int(sacksMaizeEnd[x, y])]], dim='time')
                    
with open('%s/script-data/tmax-maize-growing-season-cpc.dat'%dataDirDiscovery, 'wb') as f:
    pickle.dump(growingSeasonData, f)

sys.exit()
for year in range(1979, 2018+1):


    dsMin = xr.open_dataset('/dartfs-hpc/rc/lab/C/CMIG/CPC/tmin/tmin.%d.nc'%year, decode_times=True, decode_cf=False)
    dsMin.load()

    for k in koppenGroupsPCells.keys():

        print('processing t & p for k = %s...'%k)

        pCells = koppenGroupsPCells[k]
        cCells = koppenGroupsCCells[k]
        noPCells = koppenGroupsNoPCells[k]
        noCCells = koppenGroupsNoCCells[k]

        # the range of lat values with crops in current koppen zone
        pLatRange = []
        cLatRange = []

        for p in range(len(tMeans[k]['pLat'])):
            ttmp = dsMax.tmax.sel(lat=tMeans[k]['pLat'][p], lon=tMeans[k]['pLon'][p], method='nearest').dropna(dim='time')
            ttmp = ttmp.max(dim='time', skipna=True)
            tMeans[k]['PMax'][p, year-1979] = float(ttmp.values)

            ttmp = dsMin.tmin.sel(lat=tMeans[k]['pLat'][p], lon=tMeans[k]['pLon'][p], method='nearest').dropna(dim='time')
            ttmp = ttmp.min(dim='time', skipna=True)
            tMeans[k]['PMin'][p, year-1979] = float(ttmp.values)

            if year == 1979:
                tMeans[k]['pCover'][p] = pastureRegrid[pCells[p][0], pCells[p][1]]

        for p in range(len(tMeans[k]['cLat'])):
            ttmp = dsMax.tmax.sel(lat=tMeans[k]['cLat'][p], lon=tMeans[k]['cLon'][p], method='nearest').dropna(dim='time')
            ttmp = ttmp.max(dim='time', skipna=True)
            tMeans[k]['CMax'][p, year-1979] = float(ttmp.values)

            ttmp = dsMin.tmin.sel(lat=tMeans[k]['cLat'][p], lon=tMeans[k]['cLon'][p], method='nearest').dropna(dim='time')
            ttmp = ttmp.min(dim='time', skipna=True)
            tMeans[k]['CMin'][p, year-1979] = float(ttmp.values)

            if year == 1979:
                tMeans[k]['cCover'][p] = cropRegrid[cCells[p][0], cCells[p][1]]

        for p in range(len(tMeans[k]['noCLat'])):
            ttmp = dsMax.tmax.sel(lat=tMeans[k]['noCLat'][p], lon=tMeans[k]['noCLon'][p], method='nearest').dropna(dim='time')
            ttmp = ttmp.max(dim='time', skipna=True)
            tMeans[k]['noCMax'][p, year-1979] = float(ttmp.values)

            ttmp = dsMin.tmin.sel(lat=tMeans[k]['noCLat'][p], lon=tMeans[k]['noCLon'][p], method='nearest').dropna(dim='time')
            ttmp = ttmp.min(dim='time', skipna=True)
            tMeans[k]['noCMin'][p, year-1979] = float(ttmp.values)

        for p in range(len(tMeans[k]['noPLat'])):
            ttmp = dsMax.tmax.sel(lat=tMeans[k]['noPLat'][p], lon=tMeans[k]['noPLon'][p], method='nearest').dropna(dim='time')
            ttmp = ttmp.max(dim='time', skipna=True)
            tMeans[k]['noPMax'][p, year-1979] = float(ttmp.values)

            ttmp = dsMin.tmin.sel(lat=tMeans[k]['noPLat'][p], lon=tMeans[k]['noPLon'][p], method='nearest').dropna(dim='time')
            ttmp = ttmp.min(dim='time', skipna=True)
            tMeans[k]['noPMin'][p, year-1979] = float(ttmp.values)