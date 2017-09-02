% generate daily bowen / temperature data for regression analysis

% generate changes at a temperature percentile, annual-max, or daily-max
% across models and decades.

season = 'all';
dataset = 'era-interim';
tempVar = 'mx2t';
bowenVar = 'bowen';

if strcmp(dataset, 'cmip5')
    if strcmp(tempVar, 'wb')
        models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
                      'cnrm-cm5', 'csiro-mk3-6-0', ...
                      'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                      'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
                      'mpi-esm-mr', 'mri-cgcm3'};
    else
        models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
                          'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                          'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                          'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc-esm', ...
                          'mpi-esm-mr', 'mri-cgcm3'};
    end

    rcp = 'rcp85';
    ensemble = 'r1i1p1';
elseif strcmp(dataset, 'ncep-reanalysis') || strcmp(dataset, 'era-interim')
    models = {''};
    rcp = '';
    ensemble = '';
end

tempRegrid = true;

region = 'world';
timePeriod = 1985:2004;

baseDir = 'g:/data';
yearStep = 1;

if strcmp(season, 'summer')
    months = [6 7 8];
elseif strcmp(season, 'winter')
    months = [12 1 2];
elseif strcmp(season, 'all')
    months = 1:12;
end

tempRegridStr = '';
if tempRegrid
    tempRegridStr = 'regrid';
end


load lat;
load lon;

load waterGrid;
waterGrid = logical(waterGrid);

['loading base: ' dataset]
for m = 1:length(models)
    curModel = models{m};
    
    if strcmp(tempVar, 'wb')
        targetName = ['2017-concurrent-heat/monthly-bowen-wb/monthlyBowenWb-' dataset '-' rcp '-' curModel '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '.mat'];
    else
        targetName = ['2017-concurrent-heat/monthly-bowen-temp/monthlyBowenTemp-' dataset '-' rcp '-' curModel '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '.mat'];
    end
    
    if exist(targetName, 'file')
        continue;
    end
    
    % current model temperature / bowen data - stores all daily temp/bowen
    % combinations
    % dimensions: x, y, month, point
    tempData = {};
    bowenData = {};

    ['loading model ' curModel '...']

    for y = timePeriod(1):yearStep:timePeriod(end)
        ['year ' num2str(y) '...']

        baseDailyTemp = loadDailyData([baseDir '/' dataset '/output/' curModel '/' ensemble '/' rcp '/' tempVar '/' tempRegridStr '/' region], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        baseDailyBowen = loadDailyData([baseDir '/' dataset '/output/' curModel '/' ensemble '/' rcp '/' bowenVar '/regrid/' region], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        
        % remove lat/lon data (we loaded this earlier)
        baseDailyTemp = baseDailyTemp{3};
        baseDailyBowen = baseDailyBowen{3};
        
        % if any kelvin values, convert to C
        if baseDailyTemp(1,1,1,1,1) > 100
            baseDailyTemp = baseDailyTemp - 273.15;
        end

        % eliminate bad bowen values
        baseDailyBowen(baseDailyBowen > 100) = NaN;
        
        % set water grid cells to NaN
        % include loops for month and day (5D) in case we are using
        % seasonal change metric
        for i = 1:size(baseDailyTemp, 3)
            for j = 1:size(baseDailyTemp, 4)
                for k = 1:size(baseDailyTemp, 5)
                    curGrid = baseDailyTemp(:, :, i, j, k);
                    curGrid(waterGrid) = NaN;
                    baseDailyTemp(:, :, i, j, k) = curGrid;
                    
                    curGrid = baseDailyBowen(:, :, i, j, k);
                    curGrid(waterGrid) = NaN;
                    baseDailyBowen(:, :, i, j, k) = curGrid;
                end
            end
        end
        
        % loop over full dataset for current year
        for year = 1:size(baseDailyTemp, 3)
            for month = 1:size(baseDailyTemp, 4)
                for xlat = 1:size(baseDailyTemp, 1)
                    for ylon = 1:size(baseDailyTemp, 2)
                
                        % skip water tiles
                        %if waterGrid(xlat, ylon)
                        %    continue;
                        %end

                        % add empty list for this month if it doesn't exist
                        % already
                        if length(tempData) < month
                            tempData{month} = {};
                            bowenData{month} = {};
                        end
                        
                        % create cell array for current x row for the month
                        if length(tempData{month}) < xlat
                            tempData{month}{xlat} = {};
                            bowenData{month}{xlat} = {};
                        end
                        
                        % and for the y column
                        if length(tempData{month}{xlat}) < ylon
                            tempData{month}{xlat}{ylon} = [];
                            bowenData{month}{xlat}{ylon} = [];
                        end
                
                        % if cell is water, just leave it as an empty list
                        if ~waterGrid(xlat, ylon)
                            
                            % get monthly mean temp & bowen
                            mmTemp = nanmean(baseDailyTemp(xlat, ylon, year, month, :), 5);
                            mmBowen = nanmean(baseDailyBowen(xlat, ylon, year, month, :), 5);
                            
                            % if both are non-nans
                            if ~isnan(mmTemp) && ~isnan(mmBowen)
                                tempData{month}{xlat}{ylon}(end+1) = mmTemp;
                                bowenData{month}{xlat}{ylon}(end+1) = mmBowen;
                            else
                                % otherwise, set to NaN
                                tempData{month}{xlat}{ylon}(end+1) = NaN;
                                bowenData{month}{xlat}{ylon}(end+1) = NaN;
                            end
                        end
                    end
                end
            end
        end
        
        clear baseDaily baseDaily3d;
    end
    
    % save current model's data
    if strcmp(tempVar, 'wb')
        monthlyBowenWb = {tempData, bowenData};
        save(['2017-concurrent-heat/bowen/monthly-bowen-wb/monthlyBowenWb-' dataset '-' rcp '-' curModel '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '.mat'], 'monthlyBowenTemp');
    else
        monthlyBowenTemp = {tempData, bowenData};
        if strcmp(dataset, 'ncep-reanalysis') || strcmp(dataset, 'era-interim')
            save(['2017-concurrent-heat/bowen/monthly-bowen-temp/monthlyBowenTemp-' dataset '-historical-' curModel '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '.mat'], 'monthlyBowenTemp');
        else
            save(['2017-concurrent-heat/bowen/monthly-bowen-temp/monthlyBowenTemp-' dataset '-' rcp '-' curModel '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '.mat'], 'monthlyBowenTemp');
        end
    end

end

