
#!/usr/bin/env python
import calendar
from ecmwfapi import ECMWFDataServer
import os.path
server = ECMWFDataServer()
 
#files =     ["201.128", "202.128", "228.128", "146.128", "147.128"]
#fileNames = ["mx2t",    "mn2t",    "tp",      "sshf",    "slhf"]
#
#files =     ["39.128", "40.128", "41.128", "42.128"]
#fileNames = ["swvl1",  "swvl2",  "swvl3",  "swvl4"]
#
#files =     ["33.128", "141.128"]
#fileNames = ["rsn",    "sd"]

#files =      ["168.128"]
#fileNames = ["d2m"]

files =      ["201.128"]
fileNames = ["mx2t"]

#files =      ["134.128"]
#fileNames = ["sp"]

baseDir = 'e:/data/era-interim/raw/'

useInterimLand = False;

#def interim_request(file, fileName, dates, target):
#    server.retrieve({
#        "class": "ei",
#        "dataset": "interim",
#        "date": dates,
#        "expver": "1",
#        "grid": "2.00/2.00",
#        "levtype": "sfc",
#        "param": file,
#        "step": "6",
#        "stream": "oper",
#        "time": "00:00:00/06:00:00/12:00:00/18:00:00",
#        "type": "fc",
#        "format": "netcdf",
#        "target": target})

def interim_request(file, fileName, dates, target):
    server.retrieve({
        "class": "ei",
        "dataset": "interim",
        "date": dates,
        "expver": "1",
        "grid": "0.75/0.75",
        "levtype": "sfc",
        "param": file,
        "step": "3/6/9/12",
        "stream": "oper",
        "time": "00:00:00/12:00:00",
        "type": "fc",
        "format": "netcdf",
        "target": target})

def interim_land_request(file, fileName, dates, target):
    server.retrieve({
        "class": "ei",
        "dataset": "interim_land",
        "date": dates,
        "expver": "2",
        "grid": "2.00/2.00",
        "levtype": "sfc",
        "param": file,
        "stream": "oper",
        "time": "00:00:00/06:00:00/12:00:00/18:00:00",
        "type": "an",
        "format": "netcdf",
        "target": target})
    

yearStart = 2018
yearEnd = 2018
for f in range(len(files)):
    for year in list(range(yearStart, yearEnd + 1)):
        startDate = '%04d-01-01' % (year)
        lastDate = '%04d-12-31' % (year)
        requestDates = (startDate + "/to/" + lastDate)
        if os.path.isfile(baseDir + fileNames[f] + "_" + str(year) + "_075x075.nc"):
            print('skipping', fileNames[f] + "_" + str(year) + "_075x075.nc")
        else:
            print('requesting', fileNames[f] + "_" + str(year) + "_075x075.nc")
            if useInterimLand:
                interim_land_request(files[f], fileNames[f], requestDates, baseDir + fileNames[f] + '_' + str(year) + '_075x075.nc')
            else:
                interim_request(files[f], fileNames[f], requestDates, baseDir + fileNames[f] + '_' + str(year) + '_075x075.nc')
