# divide the main file into subfiles, one for each station

import os

asosBase = 'e:/data/projects/heat/asos/'
states = ['in']

# how many lines to read at a time
N = 1000000

def writeOutput(stationData, outputDir):
    print('writing output files...')
    # loop over all stations
    for code in stationData.keys():
        print('writing', code, '...')
        if code == 'PRN' or code == 'CON':
            fout = open(outputDir + code + '-valid' + '.txt', 'a')    
        else:
            fout = open(outputDir + code + '.txt', 'a')

        for lineParts in stationData[code]:
            # if rel hum exists, delete it
            if len(lineParts) == 9:
                del lineParts[7]
            fout.write(','.join(lineParts) + '\n')
        
        fout.close();

for state in states:
    outputDir = asosBase + 'wx-data/' + state + '/'
    if not os.path.exists(outputDir):
        os.makedirs(outputDir)
    else:
        continue
    
    fin = open(asosBase + 'asos-' + state + '.txt', 'r')

    # skip first lines of headers
    startLine = 1

    # current line number
    lineCnt = 1
    
    # last time we wrote to output files
    lastLineReset = 0

    # dictionary with station codes (keys) and data (values)
    stationData = {}

    print('reading ' + state + ' input files...')
    for line in fin:

        # remove whitespace (and trailing \n)
        line = line.strip()
        
        # if we're past the headers
        if lineCnt > startLine:
            lineParts = line.split(',')

            # if we haven't seen the current station yet, set it to empty list
            if lineParts[0] not in stationData.keys():
                stationData[lineParts[0]] = []

            # columns:
            # 0 - station
            # 1 - date/time
            # 2 - lon
            # 3 - lat
            # 4 - temp (C)
            # 5 - rel humidity (%)
            # 6 - surface pressure (in)
            # 7 - mslp (mb)

            # split time into separate cols for year, month, day, hour
            datetimeParts = lineParts[1].split(' ')

            dateParts = datetimeParts[0].split('-')
            timeParts = datetimeParts[1].split(':')
            
            year = int(dateParts[0])
            month = int(dateParts[1])
            day = int(dateParts[2])
            hour = int(timeParts[0])

            datetime = [str(year), str(month), str(day), str(hour)]

            # replace 'M' with '-999' in cols 2, 3, 4, 5, 6
            for i in range(2, len(lineParts)):
                lineParts[i] = lineParts[i].replace('M', '-999')

            # add data to station
            stationData[lineParts[0]].append(datetime + lineParts[2:])
        
        lineCnt += 1
        if lineCnt % 100000 == 0:
            print('line', lineCnt)

        # write to output file if we have enough data
        if lineCnt - lastLineReset > N:
            writeOutput(stationData, outputDir)
            lastLineReset = lineCnt
            stationData = {}

    # write remaining data to output at the end
    writeOutput(stationData, outputDir)

    
