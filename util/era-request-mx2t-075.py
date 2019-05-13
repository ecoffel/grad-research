#!usr/bin/env python
from ecmwfapi import ECMWFDataServer
server = ECMWFDataServer()
server.retrieve({
    "class": "ei",
    "dataset": "interim",
    "date": "2018-01-01/to/2018-12-31",
    "expver": "1",
    "grid": "0.75/0.75",
    "levtype": "sfc",
    "param": "201.128",
    "step": "3",
    "stream": "oper",
    "time": "00:00:00",
    "type": "fc",
    "format": "netcdf",
    "target": "mx2t_2018.nc"
})
