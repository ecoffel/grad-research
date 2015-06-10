
airportDb = loadAirportDb('airports.dat');

obsAirports = {'PHX', 'LGA', 'DCA', 'DEN'};

airportLats = [];
airportLons = [];

for a = 1:length(obsAirports)
    [code, airportLat, airportLon] = searchAirportDb(airportDb, 'DCA');
    airportLats(a) = airportLat;
    airportLons(a) = airportLon;
end

pslHist = loadMonthlyData('e:/data/cmip5/output/ccsm4/r1i1p1/historical/psl', 'psl', 'yearStart', 1990, 'yearEnd', 2005);
tasmaxHist = loadMonthlyData('e:/data/cmip5/output/ccsm4/r1i1p1/historical/tasmax', 'tasmax', 'yearStart', 1990, 'yearEnd', 2005);
psl85 = loadMonthlyData('e:/data/cmip5/output/ccsm4/r1i1p1/rcp85/psl', 'psl', 'yearStart', 2055, 'yearEnd', 2070);
tasmax85 = loadMonthlyData('e:/data/cmip5/output/ccsm4/r1i1p1/rcp85/tasmax', 'tasmax', 'yearStart', 2055, 'yearEnd', 2070);

pslHistData = [];
psl85Data = [];

tasmaxHistData = [];
tasmax85Data = [];

for a = 1:length(obsAirports)
    
    [latIndexRange, lonIndexRange] = latLonIndexRange(pslHist{1}{1}, [airportLats(a) airportLats(a)], [airportLons(a) airportLons(a)]);
    
    for m = 5:9
        hist = pslHist{m};
        fut = psl85{m};
        
        tempHist = tasmaxHist{m};
        tempFut = tasmax85{m};

        for y = 1:length(hist)
            pslHistData(y, m) = hist{y}{3}(latIndexRange, lonIndexRange);
            psl85Data(y, m) = fut{y}{3}(latIndexRange, lonIndexRange);
            
            tasmaxHistData(y, m) = tempHist{y}{3}(latIndexRange, lonIndexRange);
            tasmax85Data(y, m) = tempFut{y}{3}(latIndexRange, lonIndexRange);
        end
    end
end

pslHistData = nanmean(nanmean(pslHistData, 2), 1)
psl85Data = nanmean(nanmean(psl85Data, 2), 1)

tasmaxHistData = nanmean(nanmean(tasmaxHistData, 2), 1)
tasmax85Data = nanmean(nanmean(tasmax85Data, 2), 1)

psl85Data - pslHistData
tasmax85Data - tasmaxHistData