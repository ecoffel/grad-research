if ~exist('airportDb', 'var')
    airportDb = loadAirportDb('e:\data\flight\airports.dat');
end

[airports, airportRunway, airportElevation] = av2_loadAirportInfo();
selectedAirports = airports;

airportLats = [];
airportLons = [];

aircraft = '737-800';

wxBaseDir = '2015-weight-restriction-v2/airport-wx/';

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

rcp = 'rcp85';

if strcmp(dataset, 'obs')
    rcp = 'na';
end

tempMaxVar = 'tasmax';
tempMinVar = 'tasmin';

% hourly temperature data, interpolated between observed daily max and min
wxData = {};

months = 1:12;

% temperature must be in this range to compute WR
tempRange = [25 55];

% if obsWx is false, load model data    
if ~strcmp(dataset, 'obs')
    needToLoad = false;
    
    % check if we have all th needed wx files for each selected airport
    for a = 1:length(selectedAirports)
        if strcmp(selectedAirports{a}, 'MDW')
            continue;
        end
        
        if ~exist([wxBaseDir 'airport-wx-' dataset '-' rcp '-bc-' selectedAirports{a} '.mat'], 'file');
            needToLoad = true;
            ['weather at ' selectedAirports{a} ' missing']
        end
    end
    
    % if the required data isn't there, load it and save it
    if needToLoad
        for m = 1:length(models)
            if strcmp(models{m}, '')
                curModel = models{m};
            else
                curModel = [models{m} '/'];
            end

            wxData{m} = {models{m}, {}};
            
            ['loading ' curModel ' base']
            
            timePeriod = basePeriodYears;
            if strcmp(rcp, 'rcp45') || strcmp(rcp, 'rcp85')
                timePeriod = futurePeriodYears;
            end
            
            for a = 1:length(airports)
                wxData{m}{2}{a} = {airports{a}, []};
            end
            
            for y = timePeriod(1):timePeriod(end)
                ['year ' num2str(y) '...']

                dailyDataMax = loadDailyData([baseDir '/' curModel '/' ensemble '/' rcp '/' tempMaxVar '/regrid/world'], 'yearStart', y, 'yearEnd', (y+1)-1);
                dailyDataMin = loadDailyData([baseDir '/' curModel '/' ensemble '/' rcp '/' tempMinVar '/regrid/world'], 'yearStart', y, 'yearEnd', (y+1)-1);

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
                        wxData{m}{2}{a}{2}(y-timePeriod(1)+1, d, :) = [up(2:end) down(2:end)];
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

% load lookup table
wrLookup = load('wrLookup.mat');
wrLookup = wrLookup.wrLookup;

% find index for current a/c
acInd = -1;
for ac = 1:length(wrLookup)
    if strcmp(aircraft, wrLookup{ac}{1})
        acInd = ac;
        break;
    end
end

hours = 1:24;

['processing weight restriction...']
for a = 1:length(selectedAirports)
    
    if strcmp(selectedAirports{a}, 'MDW')
        continue;
    end
    
    % load weather for current airport - loaded as wxData
    if strcmp(dataset, 'obs')
        load([wxBaseDir 'airport-wx-obs-' selectedAirports{a} '.mat']);
        wxData = asosData;
    elseif strcmp(dataset, 'cmip5')
        load([wxBaseDir 'airport-wx-cmip5-' rcp '-bc-' selectedAirports{a}]);
    end
    
    % find position of current airport in airport database (w/ runway
    % length & elevation)
    aInd = -1;
    for i = 1:length(airports)
        if strcmp(selectedAirports{a}, airports{i})
            aInd = i;
        end
    end
    
    ['processing ' airports{aInd} '...']
    
    weightRestriction{a} = {};
    totalRestriction{a} = {};
    
    if strcmp(dataset, 'obs')
        weightRestriction{a}{1} = {selectedAirports{a}, 'obs', []};
        totalRestriction{a}{1} = {selectedAirports{a}, 'obs', []};
        
        for y = 1:size(wxData{5}, 1)

            % extract data for current year
            curMax = squeeze(wxData{5}(y, :, :));
            curMin = squeeze(wxData{6}(y, :, :));

            % reshape it to 1D
            curMax = reshape(curMax, [size(curMax, 1)*size(curMax, 2), 1]);
            curMin = reshape(curMin, [size(curMin, 1)*size(curMin, 2), 1]);

            % loop over each day in the year
            for d = 1:length(curMax)-1

                % compute evenly spaced intervals from current day minimum
                % to next day's minimum
                hourlyTemps = linspace(curMin(d), curMax(d), 13);
                hourlyTemps = [hourlyTemps(1:end-1) linspace(curMax(d), curMin(d+1), 13)];
                hourlyTemps = hourlyTemps(1:end-1);

                for h = 1:length(hourlyTemps)
                    temp = hourlyTemps(h);
                    
                    if temp < tempRange(1) || temp > tempRange(end) || isnan(temp)
                        weightRestriction{a}{1}{3}(h, y, d) = NaN;
                        totalRestriction{a}{1}{3}(h, y, d) = NaN;
                    else
                        elevation = airportElevation(aInd);
                        runway = airportRunway(aInd);

                        % find correct index for elevation, runway, temp in
                        % lookup table
                        elevInd = find(abs(round(elevation) - wrLookup{acInd}{2}{1}) == min(abs(round(elevation) - wrLookup{acInd}{2}{1})));
                        tempInd = find(abs(round(temp) - wrLookup{acInd}{2}{2}) == min(abs(round(temp) - wrLookup{acInd}{2}{2})));
                        runwayInd = find(abs(round(runway) - wrLookup{acInd}{2}{3}) == min(abs(round(runway) - wrLookup{acInd}{2}{3})));

                        if elevInd > size(wrLookup{acInd}{3}, 1) || ...
                           tempInd > size(wrLookup{acInd}{3}, 2) || ...
                           runwayInd > size(wrLookup{acInd}{3}, 3)
                            weightRestriction{a}{1}{3}(h, y, d) = NaN;
                            totalRestriction{a}{1}{3}(h, y, d) = NaN;
                        else
                            % look up restriction in the wr lookup table
                            curWr = wrLookup{acInd}{3}(elevInd, tempInd, runwayInd);
                            curTr = wrLookup{acInd}{4}(elevInd, tempInd, runwayInd);

                            weightRestriction{a}{1}{3}(h, y, d) = curWr;
                            totalRestriction{a}{1}{3}(h, y, d) = curTr;
                        end
                    end
                end
            end
        end
    elseif strcmp(dataset, 'cmip5')
        for m = 1:length(models)

            ['processing ' models{m} '...']

            weightRestriction{a}{m} = {selectedAirports{a}, models{m}, []};
            totalRestriction{a}{m} = {selectedAirports{a}, models{m}, []};

            for h = hours
                count = 1;
                for y = 1:size(wxData{m}{2}{2}, 1)
                    for d = 1:size(wxData{m}{2}{2}, 2)

                        temp = wxData{m}{2}{2}(y, d, h);

                        if temp < tempRange(1) || temp > tempRange(end) || isnan(temp)
                            weightRestriction{a}{m}{3}(h-hours(1)+1, count) = NaN;
                            totalRestriction{a}{m}{3}(h-hours(1)+1, count) = NaN;
                        else

                            elevation = airportElevation(aInd);
                            runway = airportRunway(aInd);

                            % find correct index for elevation, runway, temp in
                            % lookup table
                            elevInd = find(abs(round(elevation) - wrLookup{acInd}{2}{1}) == min(abs(round(elevation) - wrLookup{acInd}{2}{1})));
                            tempInd = find(abs(round(temp) - wrLookup{acInd}{2}{2}) == min(abs(round(temp) - wrLookup{acInd}{2}{2})));
                            runwayInd = find(abs(round(runway) - wrLookup{acInd}{2}{3}) == min(abs(round(runway) - wrLookup{acInd}{2}{3})));

                            if elevInd > size(wrLookup{acInd}{3}, 1) || ...
                               tempInd > size(wrLookup{acInd}{3}, 2) || ...
                               runwayInd > size(wrLookup{acInd}{3}, 3)
                                weightRestriction{a}{m}{3}(h-hours(1)+1, count) = NaN;
                                totalRestriction{a}{m}{3}(h-hours(1)+1, count) = NaN;
                            else
                                % look up restriction in the wr lookup table
                                curWr = wrLookup{acInd}{3}(elevInd, tempInd, runwayInd);
                                curTr = wrLookup{acInd}{4}(elevInd, tempInd, runwayInd);

                                weightRestriction{a}{m}{3}(h-hours(1)+1, count) = curWr;
                                totalRestriction{a}{m}{3}(h-hours(1)+1, count) = curTr;
                            end
                        end
                        count = count+1;
                    end
                end
            end
        end
    end
    
    clear wxData;
end

save(['wr-' aircraft '-' dataset '-' rcp '.mat'], 'weightRestriction');
save(['tr-' aircraft '-' dataset '-' rcp '.mat'], 'totalRestriction');





