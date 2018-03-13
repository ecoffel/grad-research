# -*- coding: utf-8 -*-
"""
Created on Tue Feb  6 18:03:53 2018

@author: Ethan
"""
import os
import sys
import glob
from subprocess import call
from netCDF4 import Dataset
import numpy as np
import pickle
import gzip


baseDir = 'data\\stage4-hourly-pr'
inputDrive = 'E:\\'
outputDrive = 'E:\\'

#dirs = os.listdir(inputDrive + baseDir)
#for dirname in dirs[132:]:
#    if os.path.isdir(inputDrive + baseDir + "\\" + dirname):
#        filenames = glob.glob(inputDrive + baseDir+'\\'+dirname+'\\*.gz')
#        for filename in filenames:
#            print('"C:/Program Files (x86)/GnuWin32/bin/gzip" -d ' + filename)
#            call('"C:/Program Files (x86)/GnuWin32/bin/gzip" -d ' + filename)
     

def ncdump(nc_fid, verb=True):
    '''
    ncdump outputs dimensions, variables and their attribute information.
    The information is similar to that of NCAR's ncdump utility.
    ncdump requires a valid instance of Dataset.

    Parameters
    ----------
    nc_fid : netCDF4.Dataset
        A netCDF4 dateset object
    verb : Boolean
        whether or not nc_attrs, nc_dims, and nc_vars are printed

    Returns
    -------
    nc_attrs : list
        A Python list of the NetCDF file global attributes
    nc_dims : list
        A Python list of the NetCDF file dimensions
    nc_vars : list
        A Python list of the NetCDF file variables
    '''
    def print_ncattr(key):
        """
        Prints the NetCDF file attributes for a given key

        Parameters
        ----------
        key : unicode
            a valid netCDF4.Dataset.variables key
        """
        try:
            print("\t\ttype:", repr(nc_fid.variables[key].dtype))
            for ncattr in nc_fid.variables[key].ncattrs():
                print('\t\t%s:' % ncattr,\
                      repr(nc_fid.variables[key].getncattr(ncattr)))
        except KeyError:
            print("\t\tWARNING: %s does not contain variable attributes" % key)

    # NetCDF global attributes
    nc_attrs = nc_fid.ncattrs()
    if verb:
        print("NetCDF Global Attributes:")
        for nc_attr in nc_attrs:
            print('\t%s:' % nc_attr, repr(nc_fid.getncattr(nc_attr)))
    nc_dims = [dim for dim in nc_fid.dimensions]  # list of nc dimensions
    # Dimension shape information.
    if verb:
        print("NetCDF dimension information:")
        for dim in nc_dims:
            print("\tName:", dim)
            print("\t\tsize:", len(nc_fid.dimensions[dim]))
            print_ncattr(dim)
    # Variable information.
    nc_vars = [var for var in nc_fid.variables]  # list of nc variables
    if verb:
        print("NetCDF variable information:")
        for var in nc_vars:
            if var not in nc_dims:
                print('\tName:', var)
                print("\t\tdimensions:", nc_fid.variables[var].dimensions)
                print("\t\tsize:", nc_fid.variables[var].size)
                print_ncattr(var)
    return nc_attrs, nc_dims, nc_vars

binsize = 5
bins = np.array(range(0,150,5))

dirs = os.listdir(inputDrive+baseDir)
for dirname in dirs[144:192]:
    counts = np.zeros((881, 1121, 30))
    if os.path.isdir(inputDrive + baseDir + "\\" + dirname):
        
        newdir = outputDrive + baseDir + "\\" + dirname
        if not os.path.isdir(newdir):
            print('mkdir ' + newdir)
            os.mkdir(newdir)
		
		#if os.path.isfile(inputDrive + baseDir+'\\'+dirname+'\\counts.dat'):
	#		print('skipping ' + inputDrive + baseDir+'\\'+dirname+'\\counts.dat')
		#	continue
        
        filenames = glob.glob(inputDrive + baseDir+'\\'+dirname+'\\*.01h')
        for filename in filenames:
            filename2 = filename[0:-4];
            filename2 = filename2.replace(inputDrive, outputDrive)
            filename2 = filename2.replace('.', '') + '.nc'
            
#            if os.path.isfile(filename2):
#                continue
            
            cmd = 'C:/ndfd/degrib/bin/degrib.exe ' + filename + ' -out ' + filename2 + ' -C -msg 1 -NetCDF 3'
            print(cmd)
            call('C:/ndfd/degrib/bin/degrib.exe ' + filename + ' -out ' + filename2 + ' -C -msg 1 -NetCDF 3')
            
            nc_fid = Dataset(filename2, 'r')
            nc_attrs, nc_dims, nc_vars = ncdump(nc_fid,verb=False)
            
            lats = nc_fid.variables['latitude'][:]  
            lons = nc_fid.variables['longitude'][:]
            time = nc_fid.variables['ProjectionHr'][:]
            pr = nc_fid.variables['APCP_SFC'][:]  # shape is time, lat, lon as shown above
            data = {'lats':lats, 'lons':lons, 'time':time, 'pr':pr}
            
            nc_fid.close()
            
            print('processing...')
            shp = np.shape(pr)
            for x in range(shp[1]):
                for y in range(shp[2]):
                    if pr._mask[0,x,y]: continue
                    ind = int(round(pr[0,x,y]/binsize))
                    #ind = np.where(bins == min(list(bins), key=lambda i:abs(i-pr[0,x,y])))
                    counts[x,y,ind] += 1
            print('done processing...')        
            #filename3 = filename2.replace('.nc', '.dat')
            
            #f = gzip.open(filename3, 'wb')
            #pickle.dump(data, f)
            #f.close()
            
            os.remove(filename2)
        f = gzip.open(inputDrive + baseDir+'\\'+dirname+'\\counts.dat', 'wb')
        pickle.dump(counts, f)
        f.close()