import os, sys

dataDir = 'ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis2.dailyavgs/gaussian_grid'
dataDest = '/dartfs-hpc/rc/lab/C/CMIG/NCEP-DOE-R2/daily/tmax'

for year in range(1981, 2018+1):
    fileDir = '%s/tmax.2m.gauss.%d.nc'%(dataDir, year)
    fileDest = '%s/tmax.2m.gauss.%d.nc'%(dataDest, year)
    cmd = 'wget %s -O %s'%(fileDir, fileDest)
    print(cmd)
    os.system(cmd)

