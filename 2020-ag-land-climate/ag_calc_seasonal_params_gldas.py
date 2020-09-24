import rasterio as rio
import matplotlib.pyplot as plt 
import numpy as np
from scipy import interpolate
import statsmodels.api as sm
import scipy.stats as st
import os, sys, pickle, gzip
import datetime
from dateutil.relativedelta import relativedelta
from calendar import monthrange
import geopy.distance
import xarray as xr
import cartopy.crs as ccrs

import warnings
warnings.filterwarnings('ignore')

dataDirDiscovery = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/projects/ag-land-climate'

yearRange = [1981, 2019]

sacksMaizeNc = xr.open_dataset('%s/sacks/Maize.crop.calendar.fill.nc'%dataDirDiscovery)
sacksStart = sacksMaizeNc['plant'].values + 1
sacksStart = np.roll(sacksStart, -int(sacksStart.shape[1]/2), axis=1)
sacksStart[sacksStart < 0] = np.nan
sacksEnd = sacksMaizeNc['harvest'].values + 1
sacksEnd = np.roll(sacksEnd, -int(sacksEnd.shape[1]/2), axis=1)
sacksEnd[sacksEnd < 0] = np.nan

sacksLat = np.linspace(90, -90, 360)
sacksLon = np.linspace(0, 360, 720)

with gzip.open('%s/gdd-kdd-lat-cpc.dat'%dataDirDiscovery, 'rb') as f:
    tempLat = pickle.load(f)

with gzip.open('%s/gdd-kdd-lon-cpc.dat'%dataDirDiscovery, 'rb') as f:
    tempLon = pickle.load(f)
    
print('opening datasets...')
gldasNoah = xr.open_mfdataset('/dartfs-hpc/rc/lab/C/CMIG/GLDAS-V2-NOAH/GLDAS_NOAH10_M.*.nc4', concat_dim='time')
gldasVic = xr.open_mfdataset('/dartfs-hpc/rc/lab/C/CMIG/GLDAS-V2-VIC/GLDAS_VIC10_M.*.nc4', concat_dim='time')

dims = gldasNoah.dims
startingDate = datetime.datetime(1948, 1, 1, 0, 0, 0)
tDt = []
for curTTime in gldasNoah.time:
    delta = datetime.timedelta(days=int(curTTime.values))
    tDt.append(startingDate + delta)
gldasNoah['time'] = tDt
gldasVic['time'] = tDt

sys.exit()

print('loading gldas noah...')
gldasNoah.load()
print('loading gldas vic...')
gldasVic.load()

seasonalSshf_Noah = np.zeros([len(tempLat), len(tempLon), len(range(yearRange[0], yearRange[1]+1))])
seasonalSshf_Vic = np.zeros([len(tempLat), len(tempLon), len(range(yearRange[0], yearRange[1]+1))])

seasonalSlhf_Noah = np.zeros([len(tempLat), len(tempLon), len(range(yearRange[0], yearRange[1]+1))])
seasonalSlhf_Vic = np.zeros([len(tempLat), len(tempLon), len(range(yearRange[0], yearRange[1]+1))])

seasonalPr_Noah = np.zeros([len(tempLat), len(tempLon), len(range(yearRange[0], yearRange[1]+1))])
seasonalPr_Vic = np.zeros([len(tempLat), len(tempLon), len(range(yearRange[0], yearRange[1]+1))])

seasonalStr_Noah = np.zeros([len(tempLat), len(tempLon), len(range(yearRange[0], yearRange[1]+1))])
seasonalStr_Vic = np.zeros([len(tempLat), len(tempLon), len(range(yearRange[0], yearRange[1]+1))])

seasonalSsr_Noah = np.zeros([len(tempLat), len(tempLon), len(range(yearRange[0], yearRange[1]+1))])
seasonalSsr_Vic = np.zeros([len(tempLat), len(tempLon), len(range(yearRange[0], yearRange[1]+1))])

seasonalWind_Noah = np.zeros([len(tempLat), len(tempLon), len(range(yearRange[0], yearRange[1]+1))])
seasonalWind_Vic = np.zeros([len(tempLat), len(tempLon), len(range(yearRange[0], yearRange[1]+1))])

print('processing growing season...')
for xlat in range(len(tempLat)-1):

    if xlat % 25 == 0: 
        print('%.0f %%'%(xlat/len(tempLat)*100))

    for ylon in range(len(tempLon)):

        if ~np.isnan(sacksStart[xlat,ylon]) and ~np.isnan(sacksEnd[xlat,ylon]):
            startMonth = datetime.datetime.strptime('%d'%(sacksStart[xlat,ylon]), '%j').date().month
            endMonth = datetime.datetime.strptime('%d'%(sacksEnd[xlat,ylon]), '%j').date().month

            lat1 = tempLat[xlat]
            lat2 = tempLat[xlat]+(tempLat[1]-tempLat[0])
            lon1 = tempLon[ylon]
            lon2 = tempLon[ylon]+(tempLon[1]-tempLon[0])
            if lon2 > 360:
                lon2 -= 360
            if lon1 > 360:
                lon1 -= 360

            curSshf_Noah = gldasNoah.Qh_tavg.sel(lat=(lat1+lat2)/2, lon=(lon1+lon2)/2, method='nearest')
            curSshf_Vic = gldasVic.Qh_tavg.sel(lat=(lat1+lat2)/2, lon=(lon1+lon2)/2, method='nearest')

            curSlhf_Noah = gldasNoah.Qle_tavg.sel(lat=(lat1+lat2)/2, lon=(lon1+lon2)/2, method='nearest')
            curSlhf_Vic = gldasVic.Qle_tavg.sel(lat=(lat1+lat2)/2, lon=(lon1+lon2)/2, method='nearest')

            curPr_Noah = gldasNoah.Rainf_f_tavg.sel(lat=(lat1+lat2)/2, lon=(lon1+lon2)/2, method='nearest')
            curPr_Vic = gldasVic.Rainf_f_tavg.sel(lat=(lat1+lat2)/2, lon=(lon1+lon2)/2, method='nearest')

            curStr_Noah = gldasNoah.Lwnet_tavg.sel(lat=(lat1+lat2)/2, lon=(lon1+lon2)/2, method='nearest')
            curStr_Vic = gldasVic.Lwnet_tavg.sel(lat=(lat1+lat2)/2, lon=(lon1+lon2)/2, method='nearest')

            curSsr_Noah = gldasNoah.Swnet_tavg.sel(lat=(lat1+lat2)/2, lon=(lon1+lon2)/2, method='nearest')
            curSsr_Vic = gldasVic.Swnet_tavg.sel(lat=(lat1+lat2)/2, lon=(lon1+lon2)/2, method='nearest')
            
            curWind_Noah = gldasNoah.Wind_f_inst.sel(lat=(lat1+lat2)/2, lon=(lon1+lon2)/2, method='nearest')
            curWind_Vic = gldasVic.Wind_f_inst.sel(lat=(lat1+lat2)/2, lon=(lon1+lon2)/2, method='nearest')

            if len(np.where(~np.isnan(curSshf_Noah.values))[0]) > 0:
                for y, year in enumerate(range(yearRange[0], yearRange[1]+1)):

                    # in southern hemisphere when planting happens in fall and harvest happens in spring
                    if  startMonth > endMonth:
                        curYearSshf_Noah = curSshf_Noah.sel(time=slice('%d-%d'%(year-1, startMonth), '%d-%d'%(year, endMonth)))
                        curYearSlhf_Noah = curSlhf_Noah.sel(time=slice('%d-%d'%(year-1, startMonth), '%d-%d'%(year, endMonth)))
                        curYearPr_Noah = curPr_Noah.sel(time=slice('%d-%d'%(year-1, startMonth), '%d-%d'%(year, endMonth)))
                        curYearStr_Noah = curStr_Noah.sel(time=slice('%d-%d'%(year-1, startMonth), '%d-%d'%(year, endMonth)))
                        curYearSsr_Noah = curSsr_Noah.sel(time=slice('%d-%d'%(year-1, startMonth), '%d-%d'%(year, endMonth)))
                        curYearWind_Noah = curWind_Noah.sel(time=slice('%d-%d'%(year-1, startMonth), '%d-%d'%(year, endMonth)))
                    else:
                        curYearSshf_Noah = curSshf_Noah.sel(time=slice('%d-%d'%(year, startMonth), '%d-%d'%(year, endMonth)))
                        curYearSlhf_Noah = curSlhf_Noah.sel(time=slice('%d-%d'%(year, startMonth), '%d-%d'%(year, endMonth)))
                        curYearPr_Noah = curPr_Noah.sel(time=slice('%d-%d'%(year, startMonth), '%d-%d'%(year, endMonth)))
                        curYearStr_Noah = curStr_Noah.sel(time=slice('%d-%d'%(year, startMonth), '%d-%d'%(year, endMonth)))
                        curYearSsr_Noah = curSsr_Noah.sel(time=slice('%d-%d'%(year, startMonth), '%d-%d'%(year, endMonth)))
                        curYearWind_Noah = curWind_Noah.sel(time=slice('%d-%d'%(year, startMonth), '%d-%d'%(year, endMonth)))

                    seasonalSshf_Noah[xlat, ylon, y] = np.nanmean(curYearSshf_Noah.values)
                    seasonalSlhf_Noah[xlat, ylon, y] = np.nanmean(curYearSlhf_Noah.values)
                    seasonalPr_Noah[xlat, ylon, y] = np.nanmean(curYearPr_Noah.values)
                    seasonalStr_Noah[xlat, ylon, y] = np.nanmean(curYearStr_Noah.values)
                    seasonalSsr_Noah[xlat, ylon, y] = np.nanmean(curYearSsr_Noah.values)
                    seasonalWind_Noah[xlat, ylon, y] = np.nanmean(curYearWind_Noah.values)

            if len(np.where(~np.isnan(curSshf_Vic.values))[0]) > 0:
                for y, year in enumerate(range(yearRange[0], yearRange[1]+1)):

                    # in southern hemisphere when planting happens in fall and harvest happens in spring
                    if  startMonth > endMonth:
                        curYearSshf_Vic = curSshf_Vic.sel(time=slice('%d-%d'%(year-1, startMonth), '%d-%d'%(year, endMonth)))
                        curYearSlhf_Vic = curSlhf_Vic.sel(time=slice('%d-%d'%(year-1, startMonth), '%d-%d'%(year, endMonth)))
                        curYearPr_Vic = curPr_Vic.sel(time=slice('%d-%d'%(year-1, startMonth), '%d-%d'%(year, endMonth)))
                        curYearStr_Vic = curStr_Vic.sel(time=slice('%d-%d'%(year-1, startMonth), '%d-%d'%(year, endMonth)))
                        curYearSsr_Vic = curSsr_Vic.sel(time=slice('%d-%d'%(year-1, startMonth), '%d-%d'%(year, endMonth)))
                        curYearWind_Vic = curWind_Vic.sel(time=slice('%d-%d'%(year-1, startMonth), '%d-%d'%(year, endMonth)))
                    else:
                        curYearSshf_Vic = curSshf_Vic.sel(time=slice('%d-%d'%(year, startMonth), '%d-%d'%(year, endMonth)))
                        curYearSlhf_Vic = curSlhf_Vic.sel(time=slice('%d-%d'%(year, startMonth), '%d-%d'%(year, endMonth)))
                        curYearPr_Vic = curPr_Vic.sel(time=slice('%d-%d'%(year, startMonth), '%d-%d'%(year, endMonth)))
                        curYearStr_Vic = curStr_Vic.sel(time=slice('%d-%d'%(year, startMonth), '%d-%d'%(year, endMonth)))
                        curYearSsr_Vic = curSsr_Vic.sel(time=slice('%d-%d'%(year, startMonth), '%d-%d'%(year, endMonth)))
                        curYearWind_Vic = curWind_Vic.sel(time=slice('%d-%d'%(year, startMonth), '%d-%d'%(year, endMonth)))

                    seasonalSshf_Vic[xlat, ylon, y] = np.nanmean(curYearSshf_Vic.values)
                    seasonalSlhf_Vic[xlat, ylon, y] = np.nanmean(curYearSlhf_Vic.values)
                    seasonalPr_Vic[xlat, ylon, y] = np.nanmean(curYearPr_Vic.values)
                    seasonalStr_Vic[xlat, ylon, y] = np.nanmean(curYearStr_Vic.values)
                    seasonalSsr_Vic[xlat, ylon, y] = np.nanmean(curYearSsr_Vic.values)
                    seasonalWind_Vic[xlat, ylon, y] = np.nanmean(curYearWind_Vic.values)

print('writing output files...')
with open('%s/seasonal-sshf-maize-gldas-noah.dat'%(dataDirDiscovery), 'wb') as f:
    pickle.dump(seasonalSshf_Noah, f)
with open('%s/seasonal-slhf-maize-gldas-noah.dat'%(dataDirDiscovery), 'wb') as f:
    pickle.dump(seasonalSlhf_Noah, f)
with open('%s/seasonal-pr-maize-gldas-noah.dat'%(dataDirDiscovery), 'wb') as f:
    pickle.dump(seasonalPr_Noah, f)
with open('%s/seasonal-str-maize-gldas-noah.dat'%(dataDirDiscovery), 'wb') as f:
    pickle.dump(seasonalStr_Noah, f)
with open('%s/seasonal-ssr-maize-gldas-noah.dat'%(dataDirDiscovery), 'wb') as f:
    pickle.dump(seasonalSsr_Noah, f)
with open('%s/seasonal-wind-maize-gldas-noah.dat'%(dataDirDiscovery), 'wb') as f:
    pickle.dump(seasonalWind_Noah, f)

with open('%s/seasonal-sshf-maize-gldas-vic.dat'%(dataDirDiscovery), 'wb') as f:
    pickle.dump(seasonalSshf_Vic, f)
with open('%s/seasonal-slhf-maize-gldas-vic.dat'%(dataDirDiscovery), 'wb') as f:
    pickle.dump(seasonalSlhf_Vic, f)
with open('%s/seasonal-pr-maize-gldas-vic.dat'%(dataDirDiscovery), 'wb') as f:
    pickle.dump(seasonalPr_Vic, f)
with open('%s/seasonal-str-maize-gldas-vic.dat'%(dataDirDiscovery), 'wb') as f:
    pickle.dump(seasonalStr_Vic, f)
with open('%s/seasonal-ssr-maize-gldas-vic.dat'%(dataDirDiscovery), 'wb') as f:
    pickle.dump(seasonalSsr_Vic, f)
with open('%s/seasonal-wind-maize-gldas-vic.dat'%(dataDirDiscovery), 'wb') as f:
    pickle.dump(seasonalWind_Vic, f)
