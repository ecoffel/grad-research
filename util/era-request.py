
#!/usr/bin/env python
import calendar
from ecmwfapi import ECMWFDataServer
server = ECMWFDataServer()
 
files = ["201.128", "202.128", "228.128", "146.128", "147.128"]
fileNames = ["mx2t", "mn2t", "tp", "sshf", "slhf"]
# 201.128 / mx2t
# 202.128 / mn2t
# 228.128 / tp
# 146.128 / sshf
# 147.128 / slhf
# 
for f in range(len(files)):
    server.retrieve({
        "class": "ei",
        "dataset": "interim",
        "date": "1980-01-01/to/2016-12-31",
        "expver": "1",
        "grid": "2.00/2.00",
        "levtype": "sfc",
        "param": files[f],
        "step": "12",
        "stream": "oper",
        "time": "00:00:00",
        "type": "fc",
        "format": "netcdf",
        "target": fileNames[f] + "_1980_2016_2x2.nc",
    })

#yearStart = 2016
#yearEnd = 2016
#monthStart = 1
#monthEnd = 2
#for year in list(range(yearStart, yearEnd + 1)):
#    for month in list(range(monthStart, monthEnd + 1)):
#        startDate = '%04d-%02d-%02d' % (year, month, 1)
#        numberOfDays = calendar.monthrange(year, month)[1]
#        lastDate = '%04d-%02d-%02d' % (year, month, numberOfDays)
#        target = "interim_daily_%04d%02d.nc" % (year, month)
#        requestDates = (startDate + "/to/" + lastDate)
#        interim_request(requestDates, target)
# 
#def interim_request(requestDates, target):
#  
#    server.retrieve({
#        "class": "ei",
#        "dataset": "interim",
#        "date": requestDates,
#        "expver": "1",
#        "grid": "0.75/0.75",
#        "levtype": "sfc",
#        "param": "201.128",
#        "step": "12",
#        "stream": "oper",
#        "time": "00:00:00",
#        "type": "fc",
#        "target": target,
#    })
#    