% generate daily sensible/latent flux / temperature data for regression analysis

% generate changes at a temperature percentile, annual-max, or daily-max
% across models and decades.

season = 'all';
dataset = 'cmip5';
tempVar = 'tasmax';
sflux = 'hfss';
lflux = 'hfls';


if strcmp(dataset, 'cmip5')
    models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
                      'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                      'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                      'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc-esm', ...
                      'mpi-esm-mr', 'mri-cgcm3'};

    rcp = 'rcp85';
    ensemble = 'r1i1p1';
elseif strcmp(dataset, 'ncep-reanalysis')
    models = {''};
    rcp = '';
    ensemble = '';
end

region = 'world';
timePeriod = 2060:2080;%1985:2004;

baseDir = 'e:/data';
outputBaseDir = '2017-concurrent-heat';
yearStep = 1;

if strcmp(season, 'summer')
    months = [6 7 8];
elseif strcmp(season, 'winter')
    months = [12 1 2];
elseif strcmp(season, 'all')
    months = 1:12;
end

load lat;
load lon;

load waterGrid;
waterGrid = logical(waterGrid);

['loading base: ' dataset]
for m = 1:length(models)
    curModel = models{m};
    
    if exist(['2017-concurrent-heat/monthly-flux-temp/monthlyFluxTemp-' dataset '-' rcp '-' curModel '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '.mat'], 'file')
        continue;
    end
    
    % current model temperature / bowen data - stores all daily temp/bowen
    % combinations
    % dimensions: x, y, month, point
    tempData = {};
    sfluxData = {};
    sfluxData = {};

    ['loading model ' curModel '...']

    for y = timePeriod(1):yearStep:timePeriod(end)
        ['year ' num2str(y) '...']

        baseDailyTemp = loadDailyData([baseDir '/' dataset '/output/' curModel '/' ensemble '/' rcp '/' tempVar '/regrid/' region], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        baseDailySFlux = loadDailyData([baseDir '/' dataset '/output/' curModel '/' ensemble '/' rcp '/' sflux '/regrid/' region], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        baseDailyLFlux = loadDailyData([baseDir '/' dataset '/output/' curModel '/' ensemble '/' rcp '/' lflux '/regrid/' region], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        
        % remove lat/lon data (we loaded this earlier)
        baseDailyTemp = baseDailyTemp{3};
        baseDailySFlux = baseDailySFlux{3};
        baseDailyLFlux = baseDailyLFlux{3};
        
        % if any kelvin values, convert to C
        if baseDailyTemp(1,1,1,1,1) > 100
            baseDailyTemp = baseDailyTemp - 273.15;
        end

        % set water grid cells to NaN
        % include loops for month and day (5D) in case we are using
        % seasonal change metric
        for i = 1:size(baseDailyTemp, 3)
            for j = 1:size(baseDailyTemp, 4)
                for k = 1:size(baseDailyTemp, 5)
                    curGrid = baseDailyTemp(:, :, i, j, k);
                    curGrid(waterGrid) = NaN;
                    baseDailyTemp(:, :, i, j, k) = curGrid;
                    
                    curGrid = baseDailySFlux(:, :, i, j, k);
                    curGrid(waterGrid) = NaN;
                    baseDailySFlux(:, :, i, j, k) = curGrid;
                    
                    curGrid = baseDailyLFlux(:, :, i, j, k);
                    curGrid(waterGrid) = NaN;
                    baseDailyLFlux(:, :, i, j, k) = curGrid;
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
                            sfluxData{month} = {};
                            lfluxData{month} = {};
                        end
                        
                        % create cell array for current x row for the month
                        if length(tempData{month}) < xlat
                            tempData{month}{xlat} = {};
                            sfluxData{month}{xlat} = {};
                            lfluxData{month}{xlat} = {};
                        end
                        
                        % and for the y column
                        if length(tempData{month}{xlat}) < ylon
                            tempData{month}{xlat}{ylon} = [];
                            sfluxData{month}{xlat}{ylon} = [];
                            lfluxData{month}{xlat}{ylon} = [];
                        end
                
                        % if cell is water, just leave it as an empty list
                        if ~waterGrid(xlat, ylon)
                            
                            % get monthly mean temp & bowen
                            mmTemp = nanmean(baseDailyTemp(xlat, ylon, year, month, :), 5);
                            mmSFlux = nanmean(baseDailySFlux(xlat, ylon, year, month, :), 5);
                            mmLFlux = nanmean(baseDailyLFlux(xlat, ylon, year, month, :), 5);
                            
                            % if both are non-nans
                            if ~isnan(mmTemp) && ~isnan(mmSFlux) && ~isnan(mmLFlux)
                                tempData{month}{xlat}{ylon}(end+1) = mmTemp;
                                sfluxData{month}{xlat}{ylon}(end+1) = mmSFlux;
                                lfluxData{month}{xlat}{ylon}(end+1) = mmLFlux;
                            else
                                % otherwise, set to NaN
                                tempData{month}{xlat}{ylon}(end+1) = NaN;
                                sfluxData{month}{xlat}{ylon}(end+1) = NaN;
                                lfluxData{month}{xlat}{ylon}(end+1) = NaN;
                            end
                        end
                    end
                end
            end
        end
        
        clear baseDaily baseDaily3d;
    end
    
    % save current model's data
    monthlyFluxTemp = {tempData, sfluxData, lfluxData};
    save([outputBaseDir '/monthly-flux-temp/monthlyFluxTemp-' dataset '-' rcp '-' curModel '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '.mat'], 'monthlyFluxTemp');

end

