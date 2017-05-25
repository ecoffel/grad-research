
% should we look at change between rcp & historical (only for cmip5)
change = false;

% look at monthly mean temp/bowen fit or monthly mean max temperature &
% mean bowen
monthlyMean = true;

% use CMIP5 or ncep
useNcep = true;

% bowen lags to test months behind temperature as predictor
lags = 0:2;

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

baseDir = 'f:/data';

rcpStr = 'historical';
if change
    rcpStr = 'chg';
end

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

% temp/bowen pairs for this region, by months
meanTemp = [];
meanTempStd = [];
meanBowen = [];
meanBowenStd = [];
r2BT = [];

modelSig = [];

if change
    meanTempFuture = [];
    meanBowenFuture = [];
    r2FutureBT = [];

    % are the monthly/model changes in bowen statistically significant
    changePower = [];
    changeSig = [];
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

    load([baseDir '/daily-bowen-temp/dailyBowenTemp-' rcpHistorical '-' models{model} '-' timePeriodHistorical '.mat']);
    bowenTemp=dailyBowenTemp;
    clear dailyBowenTemp;

    if change
        ['loading future ' models{model} '...']

        % load historical bowen data for comparison
        load([baseDir '/daily-bowen-temp/dailyBowenTemp-' rcpFuture '-' models{model} '-' timePeriodFuture '.mat']);
        bowenTempFuture=dailyBowenTemp;
        clear dailyBowenTemp;
    end

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
                    tempStd = [];
                    bowen = [];
                    bowenStd = [];

                    if change
                        tempFuture = [];
                        bowenFuture = [];
                    end
                    
                    % collect data for current up-sampled grid cell
                    for subXlat = curLat1:curLat2
                        for subYlon = curLon1:curLon2

                            % get all temp/bowen daily points for current region
                            % into one list (combines gridboxes & years for current model)
                            if monthlyMean
                                nextTemp = nanmean(bowenTemp{1}{tempMonth}{subXlat}{subYlon}');
                                nextTempStd = nanstd(bowenTemp{1}{tempMonth}{subXlat}{subYlon}');
                                nextBowen = nanmean(abs(bowenTemp{2}{bowenMonth}{subXlat}{subYlon}'));
                                nextBowenStd = nanstd(abs(bowenTemp{2}{bowenMonth}{subXlat}{subYlon}'));

                                % only add full pairs
                                if length(nextTemp) > 0 && ~isnan(nextTemp) && ~isnan(nextBowen)
                                    temp = [temp; nextTemp];
                                    bowen = [bowen; nextBowen];
                                    tempStd = [tempStd; nextTempStd];
                                    bowenStd = [bowenStd; nextBowenStd];
                                end
                            else
                                nextTemp = nanmax(bowenTemp{1}{tempMonth}{subXlat}{subYlon}');
                                nextBowen = nanmean(abs(bowenTemp{2}{bowenMonth}{subXlat}{subYlon}'));

                                % only add full pairs
                                if length(nextTemp) > 0 && ~isnan(nextTemp) && ~isnan(nextBowen)
                                    temp = [temp; nextTemp];
                                    bowen = [bowen; nextBowen];
                                end
                            end

                            if change
                                % and do the same for future data if we're looking
                                % at a change
                                if monthlyMean
                                    nextTemp = nanmean(bowenTempFuture{1}{tempMonth}{subXlat}{subYlon}');
                                    nextBowen = nanmean(abs(bowenTempFuture{2}{bowenMonth}{subXlat}{subYlon}'));

                                    % only add full pairs
                                    if length(nextTemp) > 0 && ~isnan(nextTemp) && ~isnan(nextBowen)
                                        tempFuture = [tempFuture; nextTemp];
                                        bowenFuture = [bowenFuture; nextBowen];
                                    end
                                else
                                    nextTemp = nanmax(bowenTempFuture{1}{tempMonth}{subXlat}{subYlon}');
                                    nextBowen = nanmean(abs(bowenTempFuture{2}{bowenMonth}{subXlat}{subYlon}'));

                                    % only add full pairs
                                    if length(nextTemp) > 0 && ~isnan(nextTemp) && ~isnan(nextBowen)
                                        tempFuture = [tempFuture; nextTemp];
                                        bowenFuture = [bowenFuture; nextBowen];
                                    end
                                end
                            end
                            
                        end
                    end
                    
                    if length(bowen) > 10 && length(temp) > 10
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

                        % fit model for future data if looking at change
                        if change
                            modelFutureBT = fitlm(bowenFuture, tempFuture, fitType);
                            r2FutureBT(model, month, lag) = modelFutureBT.Rsquared.Ordinary;

                            % test for significance of bowen change at 95%
                            [h, p, ci, stats] = ttest(bowen, bowenFuture, 0.05);
                            changePower(model, month) = p;
                            changeSig(model, month) = h;
                        end
                    end

                    clear temp bowen;
                    clear tempFuture bowenFuture;
                    
                end
            end
        end
        
        result = {lat(1:gridSize:end, 1:gridSize:end),lon(1:gridSize:end, 1:gridSize:end),nanmean(maxR2(:,:,month,:),4)};
        saveData = struct('data', {result}, ...
                          'plotRegion', 'world', ...
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



