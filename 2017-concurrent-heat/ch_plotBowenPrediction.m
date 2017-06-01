% look at monthly mean temp/bowen fit or monthly mean max temperature &
% mean bowen
monthlyMean = true;

% plot curves for each model separately
plotEachModel = false;

% plot scatter plots for each month of bowen, temp
plotScatter = false;

% whether to predict the difference between the monthly warming and the the annual mean warming
%predictDifference = true;

% whether to predict temps based on historical CMIP5 bowen to test whether
% future response changes
predictOnHistoricalCmip5 = false;

% whether to show the change in the bowen model when run over historical
% bowen vs future (true), or the difference between predicted temps when
% run over future bowens vs. historical simulated CMIP5 temps
showBowenModelChange = true;

% should we build the bowen/temp relationship using NCEP and then predict
% using CMIP5 (doesn't really work)
trainOnNcep = false;

lags = 1:3;

lagStr = 'lag';
for l = lags
    lagStr = [lagStr '-' num2str(l)];
end

% type of model to fit to data
fitType = 'poly222';

rcpHistorical = 'historical';
rcpFuture = 'rcp85';

timePeriodHistorical = '1985-2004';
timePeriodFuture = '2060-2080';

monthlyMeanStr = 'monthlyMean';
if ~monthlyMean
    monthlyMeanStr = 'monthlyMax';
end

dataset = 'cmip5';

load lat;
load lon;

regionInd = 4;
months = 1:12;

baseDir = 'f:/data/bowen';

regionNames = {'World', ...
                'Central U.S.', ...
                'Southeast U.S.', ...
                'Central Europe', ...
                'Mediterranean', ...
                'Northern SA', ...
                'Amazon', ...
                'India', ...
                'China', ...
                'Central Africa', ...
                'Tropics'};
regionAb = {'world', ...
            'us-cent', ...
            'us-se', ...
            'europe', ...
            'med', ...
            'sa-n', ...
            'amazon', ...
            'india', ...
            'china', ...
            'africa', ...
            'tropics'};
            
regions = [[[-90 90], [0 360]]; ...             % world
           [[35 46], [-105 -90] + 360]; ...     % central us
           [[25 35], [-90 -75] + 360]; ...      % southeast us
           [[45, 55], [10, 35]]; ...            % Europe
           [[36 45], [-15+360, 35]]; ...        % Med
           [[0 15], [-90 -45]+360]; ...         % Northern SA
           [[-15, 0], [-60, -35]+360]; ...      % Amazon
           [[8, 26], [67, 90]]; ...             % India
           [[20, 40], [100, 125]]; ...          % China
           [[-10 10], [15, 30]]; ...            % central Africa
           [[-20 20], [0 360]]];                % Tropics

switch regionAb{regionInd}
    
    case 'us-cent'
        models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
                  'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                  'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                  'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm'};
    case 'us-se'
        models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
                  'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                  'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                  'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
                  'mpi-esm-mr', 'mri-cgcm3'};
    case 'europe'
        models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
                  'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', ...
                  'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                  'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm'};
    case 'med'
        models = {'access1-3', 'bnu-esm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                  'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                  'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm'};
    case 'sa-n'
        models = {'access1-0', 'access1-3', 'bnu-esm', ...
                  'cnrm-cm5', 'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                  'hadgem2-es', 'miroc-esm', ...
                  'mpi-esm-mr', 'mri-cgcm3'};
    case 'amazon'
        models = {'access1-3', 'bnu-esm', ...
                  'cnrm-cm5', 'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                  'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', 'mri-cgcm3'};
    case 'india'
        models = {'bnu-esm', 'cnrm-cm5', ...
                  'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', ...
                  'ipsl-cm5a-mr', 'miroc-esm'};
    case 'china'
        models = {'access1-3', 'canesm2', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                  'gfdl-cm3', 'gfdl-esm2g', 'ipsl-cm5a-mr', 'miroc-esm'};
    case 'africa'
        models = {'access1-0', 'access1-3', 'bnu-esm', ...
                  'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                  'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                  'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
                  'mpi-esm-mr'};
end



       
regionLatLonInd = {};

% loop over all regions to find lat/lon indicies
for i = 1:size(regions, 1)
    [latIndexRange, lonIndexRange] = latLonIndexRange({lat, lon, []}, regions(i, 1:2), regions(i, 3:4));
    regionLatLonInd{i} = {latIndexRange, lonIndexRange};
end

curLat = regionLatLonInd{regionInd}{1};
curLon = regionLatLonInd{regionInd}{2};

% historical model temp/bowen
meanTempHistorical = [];
meanBowenHistorical = [];
% future model temp/bowen
meanTempFuture = [];
meanBowenFuture = [];
% future predicted temp from modeled bowen (historical)
meanTempPredictedHistorical = [];
% and future bowen
meanTempPredictedFuture = [];
modelR2 = [];
modelSig = [];

% NCEP-based model for each month
ncepModels = {};

for model = 1:length(models)

    % if we are loading NCEP and haven't done so already
    if trainOnNcep && length(meanTempHistorical) == 0
        ['loading NCEP...']
        load([baseDir '/monthly-bowen-temp/monthlyBowenTemp-historical-ncep-reanalysis-' timePeriodHistorical '.mat']);
        bowenTemp = monthlyBowenTemp;
        clear monthlyBowenTemp;    
    elseif ~trainOnNcep
        ['loading historical ' models{model} '...']
        load([baseDir '/monthly-bowen-temp/monthlyBowenTemp-' dataset '-' rcpHistorical '-' models{model} '-' timePeriodHistorical '.mat']);
        bowenTemp = monthlyBowenTemp;
        clear monthlyBowenTemp;    
    end
    
    ['loading future ' models{model} '...']

    % load historical bowen data for comparison
    load([baseDir '/monthly-bowen-temp/monthlyBowenTemp-' dataset '-' rcpFuture '-' models{model} '-' timePeriodFuture '.mat']);
    bowenTempFuture = monthlyBowenTemp;
    clear monthlyBowenTemp;

    for month = months
        ['month = ' num2str(month) '...']
        temp = [];
        bowen = {};
        tempFuture = [];
        bowenFuture = {};
        
        for l = 1:length(lags)
            lag = lags(l);
           
            bowen{l} = [];
            bowenFuture{l} = [];
            
            % look at temps in current month
            tempMonth = month;
            % look at bowens in lagged month
            bowenMonth = month - lag;
            % limit bowen month and roll over (0 -> dec, -1 -> nov, etc)
            if bowenMonth <= 0
                bowenMonth = 12 + bowenMonth;
            end

            for xlat = 1:length(curLat)
                for ylon = 1:length(curLon)

                    % get all temp/bowen daily points for current region
                    % into one list (combines gridboxes & years for current model)
                    if monthlyMean

                        % --------- historical -------------

                        % if we have historical data - if we are using NCEP and
                        % have alreay processed it, will skip this
                        if exist('bowenTemp')
                            % lists of temps for current month for all years
                            curMonthTemps = bowenTemp{1}{tempMonth}{curLat(xlat)}{curLon(ylon)};
                            curMonthBowens = abs(bowenTemp{2}{bowenMonth}{curLat(xlat)}{curLon(ylon)});

                            % start at year 2 to allow for lags
                            for year = 2:length(curMonthTemps)

                                tempYear = year;
                                bowenYear = year;
                                % if bowen month is *after* temp month, go to
                                % previous year
                                if tempMonth - bowenMonth < 0
                                    bowenYear = bowenYear - 1;
                                end

                                % this condition will slightly change the mean
                                % temperature and bowen for lagged plots
                                if bowenYear > 0
                                    nextTemp = curMonthTemps(tempYear);
                                    nextBowen = curMonthBowens(bowenYear);

                                    if ~isnan(nextTemp) && ~isnan(nextBowen)
                                        
                                        % only take one temp - the current,
                                        % lag 0
                                        if l == 1
                                            temp = [temp; nextTemp];
                                        end
                                        
                                        bowen{l} = [bowen{l}; nextBowen];
                                    end
                                end
                            end
                        end

                        % --------- future -------------

                        % lists of temps for current month for all years
                        curMonthTemps = bowenTempFuture{1}{tempMonth}{curLat(xlat)}{curLon(ylon)};
                        curMonthBowens = abs(bowenTempFuture{2}{bowenMonth}{curLat(xlat)}{curLon(ylon)});

                        % start at year 2 to allow for lags
                        for year = 2:length(curMonthTemps)

                            tempYear = year;
                            bowenYear = year;
                            % if bowen month is *after* temp month, go to
                            % previous year
                            if tempMonth - bowenMonth < 0
                                bowenYear = bowenYear - 1;
                            end

                            % this condition will slightly change the mean
                            % temperature and bowen for lagged plots
                            if bowenYear > 0
                                nextTempFuture = curMonthTemps(tempYear);
                                nextBowenFuture = curMonthBowens(bowenYear);

                                if ~isnan(nextTempFuture) && ~isnan(nextBowenFuture)
                                    % only take lag 0 temp
                                    if l == 1
                                        tempFuture = [tempFuture; nextTempFuture];
                                    end
                                    bowenFuture{l} = [bowenFuture{l}; nextBowenFuture];
                                end
                            end
                        end

                    end
                end
            end
            
        end

        % if we have prediction data (either NCEP for first time or current
        % CMIP5 model)
        if length(bowen) > 0
            
            % create cell array of all bowen lags and the temp variable as
            % the last column
            tbl = table();
            for v = 1:length(bowen)
                eval(['tbl.' 'lag' num2str(lags(v)) ' = bowen{' num2str(v) '};']);
            end
            tbl.temp = temp;
            
            % convert cell into table
            modelBT = fitlm(tbl, fitType);

            % if using NCEP, need to save this month's model to use on
            % future CMIP5 data
            if trainOnNcep
                ncepModels{tempMonth} = modelBT;
            end

            % get the model pValue out of the anova structure
            a = anova(modelBT, 'summary');
            modelSig(model, tempMonth) = a(2, 5).pValue < 0.05;

            % save r2 value of model
            modelR2(model, tempMonth) = modelBT.Rsquared.Ordinary;

            % mean of historical temp
            meanTempHistorical(model, month) = nanmean(temp);
            
            % mean historical model bowen for all lags
            for l = 1:length(lags)
                meanBowenHistorical(model, month, l) = nanmean(bowen{l});
            end
        end

        % mean of future temp
        meanTempFuture(model, month) = nanmean(tempFuture);
        
        % mean future model bowen for each lag
        for l = 1:length(lags)
            meanBowenFuture(model, month, l) = nanmean(bowenFuture{l});
        end

        % predict future temps based on model trained on historical data,
        % using future model bowen values as input
        if trainOnNcep
            % train using saved NCEP model for this month
            meanTempPredictedHistorical(model, tempMonth) = predict(ncepModels{tempMonth}, squeeze(meanBowenFuture(model, tempMonth, :))');
        else
            % train using current CMIP5-based model
            % historical CMIP5 bowens
            meanTempPredictedHistorical(model, tempMonth) = predict(modelBT, squeeze(meanBowenHistorical(model, tempMonth, :))');
            % and future CMIP5 bowen
            meanTempPredictedFuture(model, tempMonth) = predict(modelBT, squeeze(meanBowenFuture(model, tempMonth, :))');
        end

        % test for significance of bowen change at 95%
        %[h, p, ci, stats] = ttest(meanTempFuture(model, month), meanTempPredicted(model, month), 0.05);

        clear temp tempFuture bowen bowenFuture;
    end
    
    
    
    clear bowenTemp bowenTempFuture;
end

if trainOnNcep
    meanTempHistorical = repmat(meanTempHistorical, [size(meanTempFuture, 1), 1]);
end

warming = squeeze(meanTempFuture - meanTempHistorical);
annMeanWarming = squeeze(nanmean(meanTempFuture - meanTempHistorical, 2));

% make prediction based on historical CMIP5 bowens
if predictOnHistoricalCmip5
    warmingPredicted = meanTempPredictedHistorical - meanTempHistorical;
    annMeanWarmingPredicted = nanmean(meanTempPredictedHistorical - meanTempHistorical, 2);
else
    if showBowenModelChange
        % use historical bowens & future bowens and show the difference
        % between the two
        warmingPredicted = meanTempPredictedFuture - meanTempPredictedHistorical;
        annMeanWarmingPredicted = nanmean(meanTempPredictedFuture - meanTempPredictedHistorical, 2);
    else
        % normal - use future bowens and CMIP5 historical temps
        warmingPredicted = meanTempPredictedFuture - meanTempHistorical;
        annMeanWarmingPredicted = nanmean(meanTempPredictedFuture - meanTempHistorical, 2);
    end
end

diff = warming;
predictedDiff = warmingPredicted;

for m = 1:12
    diff(:,m) = diff(:, m) - annMeanWarming;
    predictedDiff(:,m) = predictedDiff(:,m) - annMeanWarmingPredicted;
end

% error in seasonal anomalies
diffErr = nanstd(diff, [], 1);
predictedDiffErr = nanstd(predictedDiff, [], 1);

f = figure('Color', [1,1,1]);
hold on;
axis square;
box on;
grid on;

p1 = shadedErrorBar(1:12, nanmean(diff, 1)', diffErr', 'k', 1);
set(p1.mainLine, 'Color', [239/255.0, 71/255.0, 85/255.0], 'LineWidth', 4);
set(p1.patch, 'FaceColor', [239/255.0, 71/255.0, 85/255.0]);
set(p1.edge, 'Color', 'w');

p2 = shadedErrorBar(1:12, nanmean(predictedDiff, 1), predictedDiffErr, 'k', 1);
set(p2.mainLine, 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 4);
set(p2.patch, 'FaceColor', [25/255.0, 158/255.0, 56/255.0]);
set(p2.edge, 'Color', 'w');
    
%plot(nanmean(diff,1),'b');
%plot(nanmean(predictedDiff,1),'r')
plot(1:12, zeros(12,1), '--', 'LineWidth', 3, 'Color', [0.4 0.4 0.4]);
xlim([1 12]);
set(gca, 'XTick', 1:12);
ylim([-3 3]);
xlabel('Month', 'FontSize', 24);
ylabel(['Warming anomaly ' char(176) 'C'], 'FontSize', 24);
set(gca, 'FontSize', 24);
set(gcf, 'Position', get(0,'Screensize'));
legend([p1.mainLine, p2.mainLine], 'CMIP5', 'Bowen model');%, 'location', 'best');
if predictOnHistoricalCmip5
    export_fig(['seasonalDifference-' regionAb{regionInd} '-historical-test' '-' lagStr '.png']);
else
    if showBowenModelChange
        export_fig(['seasonalDifference-' regionAb{regionInd} '-bowen-model-change' '-' lagStr '.png']);
    else
        export_fig(['seasonalDifference-' regionAb{regionInd} '-' lagStr '.png']);
    end
end
close all;

if ~predictOnHistoricalCmip5
    fig = figure('Color',[1,1,1]);
    subplot(1,2,1);
    hold on;
    box on;
    grid on;
    axis square;

    % historical temps
    p1 = plot(1:12, nanmean(meanTempHistorical, 1), 'LineWidth', 3, 'Color', [25/255.0, 158/255.0, 56/255.0]);

    % future temps (modeled)
    p2 = plot(1:12, nanmean(meanTempFuture, 1), 'LineWidth', 3, 'Color', [239/255.0, 71/255.0, 85/255.0]);

    % future temps (predicted)
    p3 = plot(1:12, nanmean(meanTempPredictedHistorical, 1), 'LineWidth', 3, 'Color', 'k');

    leg = legend([p1, p2, p3], 'CMIP5 historical', 'CMIP5 future', 'Predicted');
    set(leg, 'FontSize', 20, 'location', 'south');
    xlabel('Month', 'FontSize', 24);
    ylabel(['Temperature ' char(176) 'C'], 'FontSize', 24);
    ylim([-10 40]);
    xlim([0.5 12.5]);

    % right hand plot -------------------
    subplot(1,2,2);     
    hold on;
    axis square;
    grid on;
    box on;

    plot(1:12, modelR2, 'Color', [0.6 0.6 0.6], 'LineWidth', 1);
    plot(1:12, nanmean(modelR2, 1), 'Color', [0.3 0.3 0.3], 'LineWidth', 4);
    ylim([0 1]);

    for month = 1:size(modelR2, 2)
        p5 = plot(month, nanmean(modelR2(:, month), 1), 'o', 'MarkerSize', 15, 'Color', [0.5 0.5 0.5], 'MarkerEdgeColor', 'k');
        if length(find(modelSig(:, month))) > 0.66*length(models)
            set(p5, 'LineWidth', 3, 'MarkerFaceColor', [0.5 0.5 0.5]);
        else
            set(p5, 'LineWidth', 3);
        end
    end

    xlim([0.5 12.5]);
    set(gca, 'FontSize', 24);
    xlabel('Month', 'FontSize', 24);
    ylabel('R2', 'FontSize', 24);

    set(gcf, 'Position', get(0,'Screensize'));
    export_fig(['r2Prediction-' regionAb{regionInd} '-' dataset '-BT-' monthlyMeanStr '-' lagStr '.png']);
    close all;
end



