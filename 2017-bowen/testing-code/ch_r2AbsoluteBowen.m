% look at monthly mean temp/bowen fit or monthly mean max temperature &
% mean bowen
monthlyMean = true;

% use CMIP5 or ncep
useNcep = false;

% bowen lags to test months behind temperature as predictor
lags = 0;%:2;

% upsample world grid to new grid with squares of this size
gridSize = 2;

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

%models = {'access1-0', 'gfdl-cm3'};

dataset = 'cmip5';
if length(models) == 1 && strcmp(models{1}, 'ncep-reanalysis')
    dataset = 'ncep';
end

% max r2 value at each up-gridcell
% dimensions: (latInd, lonInd, month, model)
maxR2 = zeros(size(lat, 1)/gridSize, size(lon, 2)/gridSize, 12, length(models));
maxR2(maxR2 == 0) = NaN;

% the mean bowen at each gridbox, used to compute global bowen/R2
% relationship
% dimensions: (latInd, lonInd, month, model)
meanBowen = zeros(size(lat, 1)/gridSize, size(lon, 2)/gridSize, 12, length(models));
meanBowen(meanBowen == 0) = NaN;

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

% predicted monthly temp change using bowen model
% dims: (x, y, month, model)
bowenModelTempChgPredicted = zeros(size(lat, 1)/gridSize, size(lon, 2)/gridSize, 12, length(models));
bowenModelTempChgPredicted(bowenModelTempChgPredicted == 0) = NaN;

% same as above but using CMIP5 
cmip5TempChgPredicted = zeros(size(lat, 1)/gridSize, size(lon, 2)/gridSize, 12, length(models));
cmip5TempChgPredicted(cmip5TempChgPredicted == 0) = NaN;


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
                        
                        % save the mean absolute bowen for this square
                        meanBowen(curUpLat, curUpLon, month, model) = nanmean(bowen);
                        
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
            bowenModelChg = squeeze(bowenModelTempChgPredicted(xlat, ylon, :, model));
            % predicted annual mean change
            bowenModelAnnMeanChg = nanmean(bowenModelTempChgPredicted(xlat, ylon, :, model), 3);
            
            % get cmip5 change
            cmip5Chg = squeeze(cmip5TempChgPredicted(xlat, ylon, :, model));
            % cmip5 annual mean change
            cmip5AnnMeanChg = nanmean(cmip5TempChgPredicted(xlat, ylon, :, model), 3);
            
            % subtract off annual mean changes
            bowenModelChg = bowenModelChg - bowenModelAnnMeanChg;
            cmip5Chg = cmip5Chg - cmip5AnnMeanChg;
            
            % calculate correlation
            cor = corrcoef(bowenModelChg, cmip5Chg);
            bowenModelCorr(xlat, ylon, model) = cor(1,2);

        end
    end
    
    clear bowenTemp bowenTempFuture;
end

rblat=[];
rlat=[];
blat=[];
for xlat=1:size(maxR2,1)
    for month=1:12
        for model = 1:size(maxR2, 4)
            f = fitlm(squeeze(meanBowen(xlat, :, month, model)), squeeze(maxR2(xlat, :, month, model)), 'poly2');
            rblat(xlat, month, model) = f.Rsquared.Ordinary;
            rlat(xlat, month, model) = nanmean(maxR2(xlat, :, month, model), 2);
            blat(xlat, month, model) = nanmean(meanBowen(xlat, :, month, model), 2);
        end
    end
end

r2mean = nanmean(nanmean(rlat, 3), 2);
r2err = nanmean(nanstd(rlat,[],3),2);

bowenMean = nanmean(nanmean(blat, 3), 2);
bowenErr = nanmean(nanstd(blat,[],3),2)

figure('Color',[1,1,1]);
subplot(1,2,1);
hold on;
axis square;
box on;
p1 = shadedErrorBar(-88:4:88, r2mean, r2err, '-', 1);
set(p1.mainLine, 'LineWidth', 2, 'Color', 'k');
set(p1.patch, 'FaceColor', [0.2 0.2 0.2]);
set(p1.edge, 'Color', 'w');
set(gca, 'FontSize', 24);
ylim([0 1]);
xlim([-90 90]);
set(gca, 'XTick', [-90 -60 -30 0 30 60 90]);
xlabel('Latitude', 'FontSize', 24);
ylabel('R2', 'FontSize', 24);

subplot(1,2,2);
hold on;
axis square;
box on;
p2 = shadedErrorBar(-88:4:88, bowenMean, bowenErr, '-', 1);
set(p2.mainLine, 'LineWidth', 2, 'Color', [25/255.0, 158/255.0, 56/255.0]);
set(p2.patch, 'FaceColor', [25/255.0, 158/255.0, 56/255.0]);
set(p2.edge, 'Color', 'w');
set(gca, 'FontSize', 24);
ylim([0 10]);
xlim([-90 90]);
set(gca, 'XTick', [-90 -60 -30 0 30 60 90]);
xlabel('Latitude', 'FontSize', 24);
ylabel('Bowen ratio', 'FontSize', 24);



