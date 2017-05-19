% For each grid cell, find the mean Bowen ratio at each 1-deg daily maximum temperature
% increment

season = 'all';
dataset = 'cmip5';
bowenVar = 'bowen';
tempVar = 'tasmax';

if strcmp(dataset, 'cmip5')
    models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
                  'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                  'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                  'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc-esm', ...
                  'mpi-esm-mr', 'mri-cgcm3'};

    ensemble = 'r1i1p1';
    rcp = 'rcp85';
elseif strcmp(dataset, 'ncep-reanalysis')
    models = {''};

    ensemble = '';
    rcp = '';
end

baseRegrid = true;
futureRegrid = true;

region = 'world';
basePeriodYears = 1981:2004;
futurePeriodYears = 2060:2080;

if strcmp(rcp, 'historical') || strcmp(dataset, 'ncep-reanalysis')
    timePeriod = basePeriodYears;
elseif strcmp(rcp, 'rcp45') || strcmp(rcp, 'rcp85')
    timePeriod = futurePeriodYears;
end

baseDir = 'e:/data';
yearStep = 1;

load lat;
load lon;

load waterGrid;
waterGrid = logical(waterGrid);

decileBins = 0:10:90;

['loading base: ' dataset]
for m = 1:length(models)
    curModel = models{m};

    % bowen ratios for 1-deg C temperature increments
    % dimensions: (x, y, bin) = [bowen values at each bin]
    bowenRelationship = {};

    % same dimensions as above, but value = temp cutoff for each decile bin
    % at each grid cell
    tempThresholds = ones(size(lat, 1), size(lat, 2), length(decileBins)); 
    
    ['loading base model ' curModel '...']

    for y = timePeriod(1):yearStep:timePeriod(end)
        ['year ' num2str(y) '...']

        baseDailyTemp = loadDailyData([baseDir '/' dataset '/output/' curModel '/' ensemble '/' rcp '/' tempVar '/regrid/' region], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        baseDailyBowen = loadDailyData([baseDir '/' dataset '/output/' curModel '/' ensemble '/' rcp '/' bowenVar '/regrid/' region], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        
        % remove lat/lon data (we loaded this earlier)
        baseDailyTemp = baseDailyTemp{3};
        baseDailyBowen = baseDailyBowen{3};
        
        % if any kelvin values, convert to C
        if baseDailyTemp(1,1,1,1,1) > 100
            baseDailyTemp = baseDailyTemp - 273.15;
        end
        
        % set overly large ratios to NaN
        baseDailyBowen(baseDailyBowen > 100) = NaN;
        
        % map temps onto bowen ratios
        % loop over lat
        for xlat = 1:size(baseDailyTemp, 1)
            
            % make new row for this x value
            if length(bowenRelationship) < xlat
                bowenRelationship{xlat} = {};
            end
            
            % loop over lon
            for ylon = 1:size(baseDailyTemp, 2)
                
                % make new cell for this x/y cell
                if length(bowenRelationship{xlat}) < ylon
                    bowenRelationship{xlat}{ylon} = {};
                end
                
                % skip water tiles
                if waterGrid(xlat, ylon)
                    continue;
                end
                
                % reshape data for current grid cell (and current year) into 1-D time series
                curTemp = reshape(baseDailyTemp(xlat, ylon, :, :, :), [size(baseDailyTemp, 3)*size(baseDailyTemp, 4)*size(baseDailyTemp, 5), 1]);
                curBowen = reshape(baseDailyBowen(xlat, ylon, :, :, :), [size(baseDailyBowen, 3)*size(baseDailyBowen, 4)*size(baseDailyBowen, 5), 1]);
                
                % calculate temp cutoffs for each decile bin
                for thresh = 1:length(decileBins)
                    tempThresholds(xlat, ylon, thresh) = prctile(curTemp, decileBins(thresh));
                    
                    % make new cell for this decile bin
                    if length(bowenRelationship{xlat}{ylon}) < thresh
                        bowenRelationship{xlat}{ylon}{thresh} = [];
                    end
                end
                
                % loop over all temps
                for t = 1:length(curTemp)
                    
                    % skip any nan temps/bowens
                    if isnan(curBowen(t)) || isnan(curTemp(t))
                        continue;
                    end
                    
                    % find decile bin that current temp fits into
                    binInd = find(curTemp(t) > tempThresholds(xlat, ylon, :), 1, 'last');
                    
                    % if temperature above largest bin, no indicies found -
                    % set to index of largest bin
                    if length(binInd) == 0
                        binInd = length(decileBins);
                    end
                    
                    % add current bowen ratio to appropriate decile bin for
                    % this grid cell
                    bowenRelationship{xlat}{ylon}{binInd}(end+1) = curBowen(t);
                end
            end
        end        
        clear baseDailyTemp baseDailyBowen;
    end
    
    bowenTemp = {bowenRelationship, tempThresholds};
    
    save(['2017-concurrent-heat/bowen-temp/bowenTemp-' curModel '-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '.mat'], 'bowenTemp');
    
end



