# -*- coding: utf-8 -*-
"""
Created on Tue Oct  3 12:10:47 2017

@author: Ethan

Separates out years with >99th percentile temperature/precip events for each county
"""

import ag_utils
import pickle
import gzip
import sys
import glob
import numpy

cropBaseDir = 'e:/data/projects/ag/crop/'

# percentile cutoffs
tempPrc = 99.95
precipPrc = 99.95

tempAbs = 32
precipAbs = 25

# get all state wx
fileList = glob.glob(cropBaseDir + '*.pgz')

groupedData = {}

# loop over all states
for file in fileList:
    mergedCropWx = {}
    
    # get the state ab from the file name
    parts = file.split('.')
    parts = parts[0].split('-')
    state = parts[-1]

    groupedData[state] = {}

    # load current state
    with gzip.open(file, 'r') as f:
        mergedCropWx = pickle.load(f)
    
    for county in mergedCropWx.keys():
        countyData = mergedCropWx[county]
        
        # skip unmatched counties
        if len(countyData) == 0:
            continue
        
        groupedData[state][county] = {'year':[], 'yield':[], 'isTempGroup':[], 'isPrecipGroup':[], \
                                      'meanTemp':[], 'totalPrecip':[], 'tempMissingFraction':[], \
                                      'precipMissingFraction':[], 'isAbsTempGroup':[], 'isAbsPrecipGroup':[]}
        
        print('processing', state + '/' + county + '...')
        
        # get indices of months in growing season
        monthInd = numpy.where((countyData['month'] >= 4) & (countyData['month'] <= 9))[0]
        
        # find indices of missing data
        notNanIndTemp = numpy.where(~numpy.isnan(countyData['temp']))[0]
        notNanIndPrecip = numpy.where(~numpy.isnan(countyData['precip']))[0]
        
        # get percentile thresholds
        tempThresh = numpy.nanpercentile(countyData['temp'], tempPrc)
        precipThresh = numpy.nanpercentile(countyData['precip'], precipPrc)
        
        # get the available years for yield, temp, and precip
        agYears = list(countyData['yield'].keys())
        wxYears = list(numpy.unique(countyData['year']))
        
        # get years available in both crop and wx data
        availYears = set(agYears).intersection(wxYears)
        
        for year in availYears:
            # find wx indicies for current year
            wxInd = numpy.where(countyData['year'] == year)[0]
            
            # find wx for growing season
            wxGrowingInd = set(monthInd.tolist()).intersection(wxInd.tolist())
            
            # and find intersection with non-nan data for temp and precip within growing season
            tempInd = list(set(notNanIndTemp.tolist()).intersection(wxGrowingInd))
            precipInd = list(set(notNanIndPrecip.tolist()).intersection(wxGrowingInd))
            
            # calculate seasonal mean temp and seasonal total precip
            seasonalMeanTemp = numpy.nan
            seasonalPrecip = numpy.nan
            # only calculate if we have indices
            if len(tempInd) > 0:
                seasonalMeanTemp = numpy.nanmean(countyData['temp'][tempInd])
            if len(precipInd) > 0:
                seasonalPrecip = numpy.nansum(countyData['precip'][precipInd])
            
            # add to grouping
            if len(tempInd) > 0 and len(precipInd) > 0:
                groupedData[state][county]['year'].append(year)
                groupedData[state][county]['yield'].append(countyData['yield'][year])
                groupedData[state][county]['meanTemp'].append(seasonalMeanTemp)
                groupedData[state][county]['tempMissingFraction'].append(1-(len(tempInd) / float(len(list(wxGrowingInd)))))
                groupedData[state][county]['totalPrecip'].append(seasonalPrecip)
                groupedData[state][county]['precipMissingFraction'].append(1-(len(precipInd) / float(len(list(wxGrowingInd)))))
                
                # if we have a temp that passes threshold
                if numpy.size(numpy.where(countyData['temp'][tempInd] >= tempThresh)) > 0:
                    groupedData[state][county]['isTempGroup'].append(True)
                else:
                    groupedData[state][county]['isTempGroup'].append(False)
                    
                if numpy.size(numpy.where(countyData['temp'][tempInd] >= tempAbs)) > 0:
                    groupedData[state][county]['isAbsTempGroup'].append(True)
                else:
                    groupedData[state][county]['isAbsTempGroup'].append(False)
                    
                # and same for precip
                if numpy.size(numpy.where(countyData['precip'][precipInd] >= precipAbs)) > 0:
                    groupedData[state][county]['isAbsPrecipGroup'].append(True)
                else:
                    groupedData[state][county]['isAbsPrecipGroup'].append(False)
        
f = open('grouped-data-995.dat', 'wb')
pickle.dump(groupedData, f)
f.close()
    
        