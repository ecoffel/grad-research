if ~exist('airportDb', 'var')
    airportDb = loadAirportDb('e:\data\flight\airports.dat');
end

selectedAirports = {'LAX', 'IAH', 'MIA', 'ORD', 'ATL', 'LHR'};
airports =          {'PHX', 'LGA', 'DCA', 'DEN', 'MDW', 'DXB', 'JFK', 'LAX', 'IAH', 'MIA', 'ORD', 'ATL', 'LHR'};
airportRunway =     {11500, 7000,   7170,  16000, 6500, 13147,  14500, 11100, 12000, 13000, 13000, 12400, 12800};
airportElevation =  {1135,  23,     14,    5433,  650,  62,     12,    120,   95,    7,     680,   1018,  83};

airportLats = [];
airportLons = [];

aircraft = 'a320';

wxBaseDir = '2015-weight-restriction-v2\airport-wx\';

for a = 1:length(airports)
    [code, airportLat, airportLon] = searchAirportDb(airportDb, airports{a});
    airportLats(a) = airportLat;
    airportLons(a) = airportLon;
end

dataset = 'cmip5';
baseDir = ['e:/data/' dataset '/output'];
models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'ec-earth', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'ipsl-cm5b-lr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
% models = {'access1-0', 'gfdl-cm3'};

basePeriodYears = 1985:2004;
futurePeriodYears = 2020:2080;

ensemble = 'r1i1p1';

rcp = 'rcp45';

tempMaxVar = 'tasmax';
tempMinVar = 'tasmin';

% hourly temperature data, interpolated between observed daily max and min
wxData = {};

months = 1:12;

if strcmp(dataset, 'obs')
    timePeriods = {1981:2011, 1981:2011, 1981:2011, 1996:2011};

    needToLoad = false;
    
    if ~exist(['airport-wx-obs.mat'], 'file');
        needToLoad = true;
    end
    
    if needToLoad
        obsTasmaxDir = 'e:/data/flight/wx/output/daily/tasmax';
        obsTasminDir = 'e:/data/flight/wx/output/daily/tasmin';

        wxData{1} = {};

        for a = 1:length(airports)
            wxData{1}{a} = {airports{a}, []};
        end
        
        % now load the obs at the end
        for a = 1:length(airports)
            
            obsStart(a) = timePeriods{a}(1);
            obsEnd(a) = timePeriods{a}(end);

            % load daily maximum temps
            curObsMax = loadDailyData(obsTasmaxDir, 'yearStart', obsStart(a), 'yearEnd', obsEnd(a), 'obs', 'daily', 'obsAirport', airports{a});
            curObsMax = curObsMax(:, months, :);
            curObsMax = reshape(curObsMax, [size(curObsMax, 1), size(curObsMax, 2)*size(curObsMax, 3)]);

            % and daily minimums
            curObsMin = loadDailyData(obsTasminDir, 'yearStart', obsStart(a), 'yearEnd', obsEnd(a), 'obs', 'daily', 'obsAirport', airports{a});
            curObsMin = curObsMin(:, :, :);
            curObsMin = reshape(curObsMin, [size(curObsMin, 1), size(curObsMin, 2)*size(curObsMin, 3)]);

            % now interpolate between max and min to generate hourly temps
            for y = 1:size(curObsMax, 1)
                for d = 1:size(curObsMax, 2)
                    % rising temps
                    up = linspace(curObsMin(y,d), curObsMax(y,d), 13);
                    % falling temps
                    down = linspace(curObsMax(y,d), curObsMin(y,d), 13);
                    % chop out the duplicate daily max and min temperatures
                    wxData{1}{a}{2}(y, d, :) = [up(2:end) down(2:end)];
                end
            end
        end
        save(['airport-wx-obs.mat'], 'wxData');
        
        % split the large wx file into one per airport
        av2_splitWx(['airport-wx-obs'], wxData);
    end
% if obsWx is false, load model data    
else
    
    needToLoad = false;
    
    % check if we have all th needed wx files for each selected airport
    for a = 1:length(selectedAirports)
        if ~exist([wxBaseDir 'airport-wx-' dataset '-' rcp '-' selectedAirports{a} '.mat'], 'file');
            needToLoad = true;
            ['weather at ' selectedAirports{a} ' missing']
        end
    end
    
    if needToLoad
        for m = 1:length(models)
            if strcmp(models{m}, '')
                curModel = models{m};
            else
                curModel = [models{m} '/'];
            end

            wxData{m} = {};
            
            ['loading ' curModel ' base']
            
            timePeriod = basePeriodYears;
            if strcmp(rcp, 'rcp45') || strcmp(rcp, 'rcp85')
                timePeriod = futurePeriodYears;
            end
            
            for a = 1:length(airports)
                wxData{m}{a} = {airports{a}, []};
            end
            
            for y = timePeriod(1):timePeriod(end)
                ['year ' num2str(y) '...']

                dailyDataMax = loadDailyData([baseDir '/' curModel '/' ensemble '/' rcp '/' tempMaxVar '/regrid/world-bc'], 'yearStart', y, 'yearEnd', (y+1)-1);
                dailyDataMin = loadDailyData([baseDir '/' curModel '/' ensemble '/' rcp '/' tempMinVar '/regrid/world-bc'], 'yearStart', y, 'yearEnd', (y+1)-1);

                if nanmean(nanmean(nanmean(nanmean(nanmean(dailyDataMax{3}, 5), 4), 3), 2), 1) > 100
                    dailyDataMax{3} = dailyDataMax{3} - 273.15;
                end

                if nanmean(nanmean(nanmean(nanmean(nanmean(dailyDataMin{3}, 5), 4), 3), 2), 1) > 100
                    dailyDataMin{3} = dailyDataMin{3} - 273.15;
                end

                dailyDataMax{3} = reshape(dailyDataMax{3}, [size(dailyDataMax{3}, 1), size(dailyDataMax{3}, 2), ...
                                                            size(dailyDataMax{3}, 3)*size(dailyDataMax{3}, 4)*size(dailyDataMax{3}, 5)]);
                dailyDataMin{3} = reshape(dailyDataMin{3}, [size(dailyDataMin{3}, 1), size(dailyDataMin{3}, 2), ...
                                                            size(dailyDataMin{3}, 3)*size(dailyDataMin{3}, 4)*size(dailyDataMin{3}, 5)]);

                for a = 1:length(airports)    

                    [latIndexRange, lonIndexRange] = latLonIndexRange(dailyDataMax, [airportLats(a) airportLats(a)], [airportLons(a) airportLons(a)]);

                    for d = 1:size(dailyDataMax{3}, 3)
                        % rising temps
                        up = linspace(dailyDataMin{3}(latIndexRange, lonIndexRange, d), dailyDataMax{3}(latIndexRange, lonIndexRange, d), 13);
                        % falling temps
                        down = linspace(dailyDataMax{3}(latIndexRange, lonIndexRange, d), dailyDataMin{3}(latIndexRange, lonIndexRange, d), 13);
                        % chop out the duplicate daily max and min temperatures
                        wxData{m}{a}{2}(y-timePeriod(1)+1, d, :) = [up(2:end) down(2:end)];
                    end
                end

                clear dailyDataMax dailyDataMin;
            end
            
        end
        save(['airport-wx-' dataset '-' rcp '.mat'], 'wxData');
        
        % split the large wx file into one per airport
        av2_splitWx(['airport-wx-cmip5-' rcp], wxData);
    end
    
end

['loaded wx data...']

weightRestriction = {};
totalRestriction = {};
acSurfaces = av2_loadSurfaces();

hours = 10:14;

['processing weight restriction...']
for a = 1:length(selectedAirports)
    
    % load weather for current airport - loaded as wxData
    load([wxBaseDir 'airport-wx-cmip5-' rcp '-' selectedAirports{a}]);
    
    aInd = -1;
    for i = 1:length(airports)
        if strcmp(selectedAirports{a}, airports{i})
            aInd = i;
        end
    end
    
    ['processing ' airports{aInd} '...']
    
    weightRestriction{a} = {};
    totalRestriction{a} = {};
    for m = 1:length(models)
        
        ['processing ' models{m} '...']
        
        weightRestriction{a}{m} = {selectedAirports{a}, models{m}, []};
        totalRestriction{a}{m} = {selectedAirports{a}, models{m}, []};
        
        for h = hours
            count = 1;
            for y = 1:size(wxData{m}{2}, 1)
                for d = 1:size(wxData{m}{2}, 2)
                    if wxData{m}{2}(y,d,h) < 15
                        weightRestriction{a}{m}{3}(h-hours(1)+1, count) = NaN;
                        totalRestriction{a}{m}{3}(h-hours(1)+1, count) = NaN;
                    else
                        [weightRestriction{a}{m}{3}(h-hours(1)+1, count), totalRestriction{a}{m}{3}(h-hours(1)+1, count)] = av2_calcWeightRestriction(wxData{m}{2}(y,d,h), airportRunway{aInd}, airportElevation{aInd}, aircraft, acSurfaces);
                    end
                    count = count+1;
                end
            end
        end
    end
    
    clear wxData;
end

save(['wr-' aircraft '-' dataset '-' rcp '-new.mat'], 'weightRestriction');
save(['tr-' aircraft '-' dataset '-' rcp '-new.mat'], 'totalRestriction');





