% look at monthly mean temp/bowen fit or monthly mean max temperature &
% mean bowen
monthlyMean = true;

% use CMIP5 or ncep
useNcep = true;

% bowen lags to test months behind temperature as predictor
lags = 0;%:2;

% show monthly temp and bowen variability
showVar = true;

% upsample world grid to new grid with squares of this size
gridSize = 6;

% type of model to fit to data
fitType = 'poly2';

rcpHistorical = 'historical';
rcpFuture = 'rcp85';

timePeriodHistorical = '1985-2004';
timePeriodFuture = '2060-2080';

monthlyMeanStr = 'monthlyMean';
if ~monthlyMean
    monthlyMeanStr = 'monthlyMax';
end

load lat;
load lon;

regionInd = 1;
months = 1:12;

baseDir = 'f:/data/bowen';

rcpStr = 'historical';

% leave out 'bcc-csm1-1-m' and 'inmcm4' due to bad bowen performance
models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
              'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3'};

if useNcep
    models = {'ncep-reanalysis'};
end

dataset = 'cmip5';
if length(models) == 1 && strcmp(models{1}, 'ncep-reanalysis')
    dataset = 'ncep';
end

% max r2 value at each up-gridcell
% dimensions: (latInd, lonInd, month, model)
maxR2 = zeros(size(lat, 1)/gridSize, size(lon, 2)/gridSize, 12, length(models));
maxR2(maxR2 == 0) = NaN;

% the lag associated with the max R2 at each up-gridcell
% dimensions: (latInd, lonInd, month, model)
maxR2Lag = zeros(size(lat, 1)/gridSize, size(lon, 2)/gridSize, 12, length(models));
maxR2Lag(maxR2Lag == 0) = NaN;

% whether the model is significant at 95% at each grid cell
% dimensions: (latInd, lonInd, month, model)
modelSig = zeros(size(lat, 1)/gridSize, size(lon, 2)/gridSize, 12, length(models));

for model = 1:length(models)
    ['processing ' models{model} '...']

    load([baseDir '/monthly-bowen-temp/monthlyBowenTemp-' rcpHistorical '-' models{model} '-' timePeriodHistorical '.mat']);
    bowenTemp = monthlyBowenTemp;
    clear monthlyBowenTemp;

    for month = months

        for lag = 1:length(lags)
            % look at temps in current month
            tempMonth = month;
            % look at bowens in lagged month
            bowenMonth = month - lags(lag);
            % limit bowen month and roll over (0 -> dec, -1 -> nov, etc)
            if bowenMonth <= 0
                bowenMonth = 12 + bowenMonth;
            end

            ['temp month = ' num2str(tempMonth) ', bowen month = ' num2str(bowenMonth) '...']

            % loop over world, up-sampling to grid with sides of gridSize
            % cells
            for xlat = 1:gridSize:size(lat, 1)
                for ylon = 1:gridSize:size(lon, 2)
                    
                    % bounds of current up-sampled grid cell
                    curLat1 = xlat;
                    curLat2 = xlat + gridSize-1;
                    curLon1 = ylon;
                    curLon2 = ylon + gridSize-1;
                    
                    % current coordinates in upscaled grid
                    curUpLat = 1 + ((xlat-1) / gridSize);
                    curUpLon = 1 + ((ylon-1) / gridSize);
                    
                    temp = [];
                    bowen = [];
                    
                    % collect data for current up-sampled grid cell
                    for subXlat = curLat1:curLat2
                        for subYlon = curLon1:curLon2

                            % get all temp/bowen daily points for current region
                            % into one list (combines gridboxes & years for current model)
                            if monthlyMean

                                % lists of temps for current month for all years
                                curMonthTemps = bowenTemp{1}{tempMonth}{subXlat}{subYlon};
                                curMonthBowens = abs(bowenTemp{2}{bowenMonth}{subXlat}{subYlon});

                                for year = 1:length(curMonthTemps)

                                    tempYear = year;
                                    bowenYear = year;
                                    % if bowen month is *after* temp month, go to
                                    % previous year
                                    if tempMonth - bowenMonth < 0
                                        bowenYear = bowenYear - 1;
                                    end

                                    if bowenYear > 0
                                        nextTemp = curMonthTemps(tempYear);
                                        nextBowen = curMonthBowens(bowenYear);

                                        if ~isnan(nextTemp) && ~isnan(nextBowen)
                                            temp = [temp; nextTemp];
                                            bowen = [bowen; nextBowen];
                                        end
                                    end
                                end
                            end                            
                        end
                    end
                    
                    if length(bowen) > 100 && length(temp) > 100
                        modelBT = fitlm(bowen, temp, fitType);
                        r2BT = modelBT.Rsquared.Ordinary;
                        
                        % reset largest r2 if current one is larger than
                        % previous max
                        if r2BT > maxR2(curUpLat, curUpLon, month, model) || isnan(maxR2(curUpLat, curUpLon, month, model))
                            maxR2(curUpLat, curUpLon, month, model) = r2BT;
                            % and set associated lag
                            maxR2Lag(curUpLat, curUpLon, month, model) = lags(lag);
                            
                            % get the model pValue out of the anova structure
                            a = anova(modelBT, 'summary');
                            modelSig(curUpLat, curUpLon, month, model) = a(2, 5).pValue < 0.05;
                        end
                    end

                    clear temp bowen;
                    clear tempFuture bowenFuture;
                    
                end
            end
        end
        
        result = {lat(1:gridSize:end, 1:gridSize:end),lon(1:gridSize:end, 1:gridSize:end),nanmean(maxR2(:,:,month,:),4)};
        saveData = struct('data', {result}, ...
                          'plotRegion', 'usne', ...
                          'plotRange', [0 1], ...
                          'cbXTicks', [0 .25 .5 .75 1], ...
                          'plotTitle', 'R2', ...
                          'fileTitle', ['bowenPredictionMap-r2-' num2str(month) '-' num2str(gridSize) '.png'], ...
                          'plotXUnits', 'R2', ...
                          'blockWater', true, ...
                          'magnify', '2', ...
                          'statData', modelSig(:, :, month, model), ...
                          'stippleInterval', 2);
        plotFromDataFile(saveData);  
        
        result = {lat(1:gridSize:end, 1:gridSize:end),lon(1:gridSize:end, 1:gridSize:end),nanmean(maxR2Lag(:,:,month,:),4)};
        saveData = struct('data', {result}, ...
                          'plotRegion', 'world', ...
                          'plotRange', [0 2], ...
                          'cbXTicks', [0 1 2], ...
                          'plotTitle', 'R2 Lag', ...
                          'fileTitle', ['bowenPredictionMap-lag-' num2str(month) '-' num2str(gridSize) '.png'], ...
                          'plotXUnits', 'Lag (months)', ...
                          'blockWater', true, ...
                          'magnify', '2', ...
                          'statData', modelSig(:, :, month, model), ...
                          'stippleInterval', 2);
        plotFromDataFile(saveData);  
        
        close all;
    end
    clear bowenTemp bowenTempFuture;
end



