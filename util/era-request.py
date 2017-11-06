
#!/usr/bin/env python
import calendar
from ecmwfapi import ECMWFDataServer
server = ECMWFDataServer()
 
files = ["201.128", "202.128", "228.128", "146.128", "147.128"]
fileNames = ["mx2t", "mn2t", "tp", "sshf", "slhf"]

files = ["202.128", "228.128", "146.128", "147.128"]
fileNames = ["mn2t", "tp", "sshf", "slhf"]

# 201.128 / mx2t
# 202.128 / mn2t
# 228.128 / tp
# 146.128 / sshf
# 147.128 / slhf
# 

def interim_request(file, fileName, dates, target):
    server.retrieve({
        "class": "ei",
        "dataset": "interim",
        "date": dates,
        "expver": "1",
        "grid": "2.00/2.00",
        "levtype": "sfc",
        "param": file,
        "step": "3/6/9/12",
        "stream": "oper",
        "time": "00:00:00/12:00:00",
        "type": "fc",
        "format": "netcdf",
        "target": target})
    

yearStart = 1980
yearEnd = 2016
for f in range(len(files)):
    for year in list(range(yearStart, yearEnd + 1)):
        startDate = '%04d-01-01' % (year)
        lastDate = '%04d-12-31' % (year)
        requestDates = (startDate + "/to/" + lastDate)
        print('requesting', fileNames[f] + "_" + str(year) + "_2x2.nc")
        interim_request(files[f], fileNames[f], requestDates, fileNames[f] + "_" + str(year) + "_2x2.nc")
