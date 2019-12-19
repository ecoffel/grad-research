import os, sys

dataDir = 'ftp://ftp.cdc.noaa.gov/Projects/20CRv3/Dailies/2mSI'
dataDest = '/dartfs-hpc/rc/lab/C/CMIG/20CR/tmax'

for year in range(1901, 1980+1):
    fileDir = '%s/tmax.2m.%d.nc'%(dataDir, year)
    fileDest = '%s/tmax.2m.%d.nc'%(dataDest, year)
    cmd = 'wget %s -O %s'%(fileDir, fileDest)
    print(cmd)
    os.system(cmd)