# divide the main file into subfiles, one for each station

import os

ghcnBaseDir = 'C:/git-ecoffel/grad-research/2015-weight-restriction-v2/airport-wx/'
ghcnFileName = 'ghcn-data.csv'

fin = open(ghcnBaseDir + ghcnFileName, 'r')

# current line number
lineCnt = 1

# how many header lines to skip
headerLines = 1

# last time we wrote to output files
lastLineReset = 0

# dictionary with station codes (keys) and data (values)
stationData = {'CDG':{}, 'BKK': {}, 'DXB':{}, 'HKG':{}, 'LHR':{},
                        'MAD':{}, 'PEK':{}, 'SHA':{}, 'TLV':{}}

# ghcn codes for stations in each city
cityCodes = {'CDG': ['FRM00007149', 'FR000007150'],
             'BKK': ['THM00048453', 'TH000048455', 'TH000048456'],
             'DXB': ['AEM00041194', 'AE000041196'],
             'HKG': ['CHM00045005', 'CHM00045004'],
             'LHR': ['UKM00003772'],
             'MAD': ['SP000003195', 'SPE00120296', 'SPE00120278', 'SPE00120116', 'SP000008215', 'SPE00120287'],
             'PEK': ['CHM00054511'],
             'SHA': ['CHM00058362', 'CHM00058367'],
             'TLV': ['IS000002011', 'ISM00040180']}
             

for line in fin:

    if lineCnt <= headerLines:
        lineCnt += 1
        continue

    # remove whitespace (and trailing \n)
    line = line.strip()

    lineParts = line.split(',')
    
    # if we're past the headers

    # columns:
    # 0 - station ID
    # 1 - station name
    # 2 - date
    # 3 - TMAX (*10)
    # 4 - TMIN (*10)

    stationId = lineParts[0].split(':')
    stationId = stationId[1]
    stationName = lineParts[1]
    date = lineParts[2]
    
    # split time into separate cols for year, month, day, hour
    year = int(date[0:4])
    month = int(date[4:6])
    day = int(date[6:8])

    tmax = float(lineParts[3])
    # if current value is no data, set it to -999 to conform with format
    if tmax == -9999:
        tmax = -999
    else:
        # values are in F, convert to C
        tmax = round((tmax-32)*(5.0/9.0),1)
    
    tmin = float(lineParts[4])
    if tmin == -9999:
        tmin = -999
    else:
        tmin = round((tmin-32)*(5.0/9.0),1)

    # multiple stations for each city, with different overlapping time periods
    # if only 1 station for a day, use it
    # if multiple stations for day, average them

    for key in cityCodes.keys():
        cityStations = cityCodes[key]
        
        # we've found the right airport for the current station
        if stationId in cityStations:
            # search for the right date
            dateTuple = (year, month, day)
            # if date exists, set tmax/tmin to average of current val and existing val
            if dateTuple in stationData[key].keys():
                curTmin = stationData[key][(year, month, day)]['tmin']
                curTmax = stationData[key][(year, month, day)]['tmin']

                # if current value indicate no data, just reset it
                # otherwise, take the mean of the previous value and the new one
                if curTmin < -900:
                    curTmin = tmin
                elif tmin != -999:
                    curTmin = round((tmin + curTmin)/2.0, 1)

                if curTmax < -900:
                    curTmax = tmax
                elif tmax != -999:
                    curTmax = round((tmax + curTmax)/2.0, 1)
                
                stationData[key][(year, month, day)]['tmax'] = curTmax
                stationData[key][(year, month, day)]['tmin'] = curTmin
            else:
                # if date doesn't exist, add current tmin, tmax
                stationData[key][(year, month, day)] = {'tmax':tmax, 'tmin':tmin}

    lineCnt += 1
    if lineCnt % 10000 == 0:
        print('line', lineCnt)

fin.close()
          
for station in stationData.keys():
    print('writing ' + station + '...')
    
    outputDir = ghcnBaseDir + 'processed/' + station + '/'
    if not os.path.exists(outputDir):
        os.makedirs(outputDir)
    else:
        pass

    fout = open(outputDir + station.upper() + '.txt', 'w')
    
    for date in sorted(stationData[station].keys()):        
        fout.write(','.join([str(date[0]), str(date[1]), str(date[2])]) + ',' + str(stationData[station][date]['tmax']) + ',' + str(stationData[station][date]['tmin']) + '\n')

fout.close()

# write remaining data to output at the end
#writeOutput(stationData, outputDir)


