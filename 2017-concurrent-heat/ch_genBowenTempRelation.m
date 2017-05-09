% For each grid cell, find the mean Bowen ratio at each 1-deg daily maximum temperature
% increment

season = 'all';
basePeriod = 'past';

dataset = 'cmip5';
bowenVar = 'bowen';
tempVar = 'tasmax';

models = {'access1-0'};%, 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              %'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              %'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              %'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc-esm', ...
              %'mpi-esm-mr', 'mri-cgcm3'};

baseRcps = {'historical'};
baseEnsemble = 'r1i1p1';

futureRcps = {'rcp85'};
futureEnsemble = 'r1i1p1';

baseRegrid = true;
futureRegrid = true;

region = 'world';
basePeriodYears = 1981:2004;
futurePeriods = 2020:2080;

baseDir = 'e:/data';
yearStep = 1;

load lat;
load lon;

latBounds = [-60 60];
lonBounds = [0 360];
[latInd, lonInd] = latLonIndexRange({lat, lon, []}, latBounds, lonBounds);

numDays = 372;

load waterGrid;
waterGrid = logical(waterGrid);

tempBins = 0:5:60;

% bowen ratios for 1-deg C temperature increments
% dimensions: (model, x, y, bin) = sum(bowen ratios at this temp bin)
bowenRelationship = zeros(length(models), size(lat, 1), size(lat, 2), length(tempBins));
bowenRelationship(bowenRelationship == 0) = NaN;

% same dimensions as above, but value = numel(bowen ratios at this temp
% bin) - allows for averaging
bowenRelationshipCnt = ones(length(models), size(lat, 1), size(lat, 2), length(tempBins)); 

['loading base: ' dataset]
for m = 1:length(models)
    curModel = models{m};

    ['loading base model ' curModel '...']

    for y = basePeriodYears(1):yearStep:basePeriodYears(end)
        ['year ' num2str(y) '...']

        baseDailyTemp = loadDailyData([baseDir '/' dataset '/output/' curModel '/' baseEnsemble '/' baseRcps{1} '/' tempVar '/regrid/' region], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        baseDailyBowen = loadDailyData([baseDir '/' dataset '/output/' curModel '/' baseEnsemble '/' baseRcps{1} '/' bowenVar '/regrid/' region], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        
        % remove lat/lon data (we loaded this earlier)
        baseDailyTemp = baseDailyTemp{3};
        baseDailyBowen = baseDailyBowen{3};
        
        % if any kelvin values, convert to C
        if baseDailyTemp(1,1,1,1,1) > 100
            baseDailyTemp = baseDailyTemp - 273.15;
        end
        
        % set overly large ratios to NaN
        baseDailyBowen(baseDailyBowen > 100) = NaN;
        baseDailyBowen(baseDailyBowen < 0.01) = NaN;
        
        % map temps onto bowen ratios
        % loop over lat
        for xlat = 1:size(baseDailyTemp, 1)
            
            ['xlat = ' num2str(xlat)]
            
            % loop over lon
            for ylon = 1:size(baseDailyTemp, 2)
                
                % skip water tiles
                if waterGrid(xlat, ylon)
                    continue;
                end
                
                % reshape data for current grid cell (and current year) into 1-D time series
                curTemp = reshape(baseDailyTemp(xlat, ylon, :, :, :), [size(baseDailyTemp, 3)*size(baseDailyTemp, 4)*size(baseDailyTemp, 5), 1]);
                curBowen = reshape(baseDailyBowen(xlat, ylon, :, :, :), [size(baseDailyBowen, 3)*size(baseDailyBowen, 4)*size(baseDailyBowen, 5), 1]);
                
                % loop over all temps
                for t = 1:length(curTemp)
                    if isnan(curBowen(t))
                        continue;
                    end
                    roundedTemp = round(curTemp(t));
                    
                    % find the index for the correct temperature bin
                    binInd = find(roundedTemp < tempBins, 1, 'first');
                    
                    % if temperature above largest bin, no indicies found -
                    % set to index of largest bin
                    if length(binInd) == 0
                        binInd = length(tempBins);
                    end
                    
                    % if this gridcell is nan, then set it to the current
                    % bowen ratio
                    if isnan(bowenRelationship(m, xlat, ylon, binInd))
                        bowenRelationship(m, xlat, ylon, binInd) = curBowen(t);
                    else
                        % add current bowen ratio to sum
                        bowenRelationship(m, xlat, ylon, binInd) = bowenRelationship(m, xlat, ylon, binInd) + curBowen(t);
                    end
                    
                    % increment count for this grid cell/bin
                    bowenRelationshipCnt(m, xlat, ylon, binInd) = bowenRelationshipCnt(m, xlat, ylon, binInd) + 1;
                end
            end
        end        
        clear baseDailyTemp baseDailyBowen;
    end
end



