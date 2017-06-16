% look at monthly mean temp/bowen fit or monthly mean max temperature &
% mean bowen
monthlyMean = true;

% use CMIP5 or ncep
useNcep = false;

% bowen lags to test months behind temperature as predictor
lags = 0;%:2;

% upsample world grid to new grid with squares of this size
gridSize = 3;

% average predictions over models first and then take correlation
averagePredictions = true;

% type of model to fit to data
fitType = 'poly2';

dataset = 'cmip5';

rcpHistorical = 'historical';
rcpFuture = 'rcp85';

timePeriodHistorical = '1985-2004';
timePeriodFuture = '2060-2080';

monthlyMeanStr = 'monthlyMean';
if ~monthlyMean
    monthlyMeanStr = 'monthlyMax';
end

lagStr = 'varied';
if length(lags) == 1
    lagStr = num2str(lags);
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

% correlation between predicted temp change using bowen model and using
% CMIP5. dims: (x, y, model)
bowenModelCorr = zeros(size(lat, 1)/gridSize, size(lon, 2)/gridSize, length(models));
bowenModelCorr(bowenModelCorr == 0) = NaN;

% predicted monthly temp change using bowen model (minus annual mean
% warming)
% dims: (x, y, month, model)
bowenModelTempChgPredicted = zeros(size(lat, 1)/gridSize, size(lon, 2)/gridSize, 12, length(models));
bowenModelTempChgPredicted(bowenModelTempChgPredicted == 0) = NaN;

% same as above but using CMIP5 (minus annual mean warming)
cmip5TempChgPredicted = zeros(size(lat, 1)/gridSize, size(lon, 2)/gridSize, 12, length(models));
cmip5TempChgPredicted(cmip5TempChgPredicted == 0) = NaN;

% amplification for bowen & cmip5 - change in historically hottest month minus mean
% change
bowenAmp = zeros(size(lat, 1)/gridSize, size(lon, 2)/gridSize, length(models));
bowenAmp(bowenAmp == 0) = NaN;

cmip5Amp = zeros(size(lat, 1)/gridSize, size(lon, 2)/gridSize, length(models));
cmip5Amp(cmip5Amp == 0) = NaN;

% the historical period hottest month in each grid cell, used to compute
% change in annual maximum - mean change
% this is the value of the hottest month, used to keep track of the hottest
% month seen so far
hottestMonthValue = zeros(size(lat, 1)/gridSize, size(lon, 2)/gridSize, length(models));
hottestMonthValue(hottestMonthValue == 0) = NaN;

% the month number of the hottest month at each grid cell & model
hottestMonth = zeros(size(lat, 1)/gridSize, size(lon, 2)/gridSize, length(models));
hottestMonth(hottestMonth == 0) = NaN;

for model = 1:length(models)
    ['processing ' models{model} '...']

    % load historical model data
    load([baseDir '/monthly-bowen-temp/monthlyBowenTemp-' dataset '-' rcpHistorical '-' models{model} '-' timePeriodHistorical '.mat']);
    bowenTemp = monthlyBowenTemp;
    clear monthlyBowenTemp;
    
    % load future model data
    load([baseDir '/monthly-bowen-temp/monthlyBowenTemp-' dataset '-' rcpFuture '-' models{model} '-' timePeriodFuture '.mat']);
    bowenTempFuture = monthlyBowenTemp;
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
                    tempFuture = [];
                    bowen = [];
                    bowenFuture = [];
                    
                    % collect data for current up-sampled grid cell
                    for subXlat = curLat1:curLat2
                        for subYlon = curLon1:curLon2

                            % get all temp/bowen daily points for current region
                            % into one list (combines gridboxes & years for current model)
                            if monthlyMean

                                % -------- HISTORICAL ----------
                                % lists of temps for current month for all years
                                curMonthTemps = bowenTemp{1}{tempMonth}{subXlat}{subYlon};
                                curMonthBowens = abs(bowenTemp{2}{bowenMonth}{subXlat}{subYlon});

                                ind = find(curMonthBowens < 10);
                                curMonthTemps = curMonthTemps(ind);
                                curMonthBowens = curMonthBowens(ind);
                                
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
                                
                                % if this historical month hotter than seen
                                % so far, record it
                                if isnan(hottestMonthValue(curUpLat, curUpLon, model)) || nanmean(temp) > hottestMonthValue(curUpLat, curUpLon, model)
                                    % only if we have temp readings
                                    if ~isnan(nanmean(temp))
                                        hottestMonthValue(curUpLat, curUpLon, model) = nanmean(temp);
                                        hottestMonth(curUpLat, curUpLon, model) = month;
                                    end
                                end
                                
                                % -------- FUTURE ----------
                                % lists of temps for current month for all years
                                curMonthTemps = bowenTempFuture{1}{tempMonth}{subXlat}{subYlon};
                                curMonthBowens = abs(bowenTempFuture{2}{bowenMonth}{subXlat}{subYlon});

                                ind = find(curMonthBowens < 10);
                                curMonthTemps = curMonthTemps(ind);
                                curMonthBowens = curMonthBowens(ind);
                                
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
                                            tempFuture = [tempFuture; nextTemp];
                                            bowenFuture = [bowenFuture; nextBowen];
                                        end
                                    end
                                end
                            end                            
                        end
                    end
                    
                    if length(bowen) > 10 && length(temp) > 10 && length(bowenFuture) > 10 && length(tempFuture) > 10
                        modelBT = fitlm(bowen, temp, fitType);
                        r2BT = modelBT.Rsquared.Ordinary;
                        
                        % save the R2 for this grid cell
                        maxR2(curUpLat, curUpLon, month, model) = r2BT;
                        
                        % get the model pValue out of the anova structure
                        a = anova(modelBT, 'summary');
                        modelSig(curUpLat, curUpLon, month, model) = a(2, 5).pValue < 0.05;
                        
                        % predict on historical bowen data
                        bowenTempPredictedHistorical = predict(modelBT, bowen);
                        
                        % predict on future bowen
                        bowenTempPredictedFuture = predict(modelBT, bowenFuture);
                        
                        % record projected change by bowen model for this
                        % month
                        bowenModelTempChgPredicted(curUpLat, curUpLon, month, model) = nanmean(bowenTempPredictedFuture) - nanmean(bowenTempPredictedHistorical);
                        
                        bowenModelTempChgPredicted(bowenModelTempChgPredicted < -5) = NaN;
                        bowenModelTempChgPredicted(bowenModelTempChgPredicted > 5) = NaN;
                        
                        % and record projected temp change using cmip5
                        cmip5TempChgPredicted(curUpLat, curUpLon, month, model) = nanmean(tempFuture) - nanmean(temp);
                    end

                    clear temp bowen;
                    clear tempFuture bowenFuture;
                    
                end
            end
        end 
    end
    
    % compute correlation between bowen model predicted temp change and
    % CMIP5
    for xlat = 1:size(bowenModelTempChgPredicted, 1)
        for ylon = 1:size(bowenModelTempChgPredicted, 2)
            
            % get predicted change
            bowenModelCurChg = squeeze(bowenModelTempChgPredicted(xlat, ylon, :, model));
            % predicted annual mean change
            bowenModelAnnMeanChg = nanmean(bowenModelTempChgPredicted(xlat, ylon, :, model), 3);
            
            % get cmip5 change
            cmip5CurChg = squeeze(cmip5TempChgPredicted(xlat, ylon, :, model));
            % cmip5 annual mean change
            cmip5AnnMeanChg = nanmean(cmip5TempChgPredicted(xlat, ylon, :, model), 3);
            
            % subtract off annual mean changes
            bowenModelTempChgPredicted(xlat, ylon, :, model) = bowenModelTempChgPredicted(xlat, ylon, :, model) - bowenModelAnnMeanChg;
            cmip5TempChgPredicted(xlat, ylon, :, model) = cmip5TempChgPredicted(xlat, ylon, :, model) - cmip5AnnMeanChg;
            
            % calculate amplification for hottest month if we have a
            % hottest month at this gridbox
            if ~isnan(hottestMonth(xlat, ylon, model))
                bowenAmp(xlat, ylon, model) = bowenModelTempChgPredicted(xlat, ylon, hottestMonth(xlat, ylon, model), model) - bowenModelAnnMeanChg;
                cmip5Amp(xlat, ylon, model) = cmip5TempChgPredicted(xlat, ylon, hottestMonth(xlat, ylon, model), model) - cmip5AnnMeanChg;
            end
            
            if ~averagePredictions
                % calculate correlation
                cor = corrcoef(bowenModelCurChg, cmip5CurChg);
                bowenModelCorr(xlat, ylon, model) = abs(cor(1,2));
            end

        end
    end
    
    clear bowenTemp bowenTempFuture;
end



if averagePredictions
    bowenModelMeanCorr = [];
    for xlat = 1:size(cmip5TempChgPredicted, 1)
        for ylon = 1:size(cmip5TempChgPredicted, 2)
            % calculate correlation
            cor = corrcoef(squeeze(nanmean(bowenModelTempChgPredicted(xlat, ylon, :, :), 4)), ...
                           squeeze(nanmean(cmip5TempChgPredicted(xlat, ylon, :, :), 4)));
            bowenModelMeanCorr(xlat, ylon) = abs(cor(1,2));
        end
    end
    
    result = {lat(1:gridSize:end, 1:gridSize:end),lon(1:gridSize:end, 1:gridSize:end),bowenModelMeanCorr};
    saveData = struct('data', {result}, ...
                      'plotRegion', 'world', ...
                      'plotRange', [0 1], ...
                      'cbXTicks', [0 0.25 .5 0.75 1], ...
                      'plotTitle', 'R2', ...
                      'fileTitle', ['bowenPredictionCorrMap-' num2str(gridSize) '-lag-' lagStr '-meancorr.png'], ...
                      'plotXUnits', 'Correlation', ...
                      'blockWater', true, ...
                      'magnify', '2');%, ...
                      %'statData', modelSig(:, :, month, model), ...
                      %'stippleInterval', 5);
    plotFromDataFile(saveData); 
end
        

robustCorrThresh = 0.75 * length(models);

robustCorrVal = zeros(size(bowenModelCorr, 1), size(bowenModelCorr, 2));
robustCorrVal(robustCorrVal == 0) = NaN;

% loop over map
for xlat = 1:size(bowenModelCorr, 1)
    for ylon = 1:size(bowenModelCorr, 2)
        
        % possible correlation values
        for corrVal = 0:0.1:1
            
            % count how many models agree that at least current corr value
            % reached
            cnt = 0;
            
            % loop over models
            for m = 1:size(bowenModelCorr, 3)
                % if model greater than current corr val, record it
                if bowenModelCorr(xlat, ylon, m) > corrVal
                    cnt = cnt + 1;
                end
            end
            
            % if enough models agree, record this as the max corr value
            if cnt > robustCorrThresh
                robustCorrVal(xlat, ylon) = corrVal;
            end
        end
    end
end

result = {lat(1:gridSize:end, 1:gridSize:end),lon(1:gridSize:end, 1:gridSize:end),nanmean(robustCorrVal(:,:,:),3)};
saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [0 1], ...
                  'cbXTicks', [0 0.25 .5 0.75 1], ...
                  'plotTitle', 'R2', ...
                  'fileTitle', ['bowenPredictionCorrMap-' num2str(gridSize) '-lag-' lagStr '-robust.png'], ...
                  'plotXUnits', 'Correlation', ...
                  'blockWater', true, ...
                  'magnify', '2');%, ...
                  %'statData', modelSig(:, :, month, model), ...
                  %'stippleInterval', 5);
plotFromDataFile(saveData); 

result = {lat(1:gridSize:end, 1:gridSize:end),lon(1:gridSize:end, 1:gridSize:end),nanmean(bowenModelCorr(:,:,:),3)};
saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [0 1], ...
                  'cbXTicks', [0 0.25 .5 0.75 1], ...
                  'plotTitle', 'R2', ...
                  'fileTitle', ['bowenPredictionCorrMap-' num2str(gridSize) '-lag-' lagStr '.png'], ...
                  'plotXUnits', 'Correlation', ...
                  'blockWater', true, ...
                  'magnify', '2');%, ...
                  %'statData', modelSig(:, :, month, model), ...
                  %'stippleInterval', 5);
plotFromDataFile(saveData); 

result = {lat(1:gridSize:end, 1:gridSize:end),lon(1:gridSize:end, 1:gridSize:end),nanmean(bowenAmp(:,:,:),3)};
saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [-2 2], ...
                  'cbXTicks', -2:2, ...
                  'plotTitle', 'Bowen model temperature change', ...
                  'fileTitle', ['temp-chg-bowen-model-' num2str(gridSize) '-lag-' lagStr '.png'], ...
                  'plotXUnits', [char(176) ' C'], ...
                  'blockWater', true, ...
                  'magnify', '2');%, ...
                  %'statData', modelSig(:, :, month, model), ...
                  %'stippleInterval', 5);
plotFromDataFile(saveData);  

result = {lat(1:gridSize:end, 1:gridSize:end),lon(1:gridSize:end, 1:gridSize:end),nanmean(cmip5Amp(:,:,:),3)};
saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [4 9], ...
                  'cbXTicks', 4:9, ...
                  'plotTitle', 'CMIP5 temperature change', ...
                  'fileTitle', ['temp-chg-cmip5-' num2str(gridSize) '-lag-' lagStr '.png'], ...
                  'plotXUnits', [char(176) ' C'], ...
                  'blockWater', true, ...
                  'magnify', '2');%, ...
                  %'statData', modelSig(:, :, month, model), ...
                  %'stippleInterval', 5);
plotFromDataFile(saveData);  


