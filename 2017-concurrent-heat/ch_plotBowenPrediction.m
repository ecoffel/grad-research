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
% using CMIP5-based percentage change in bowen to modify NCEP bowen
trainOnNcep = true;

lags = 0;

lagStr = 'lag';
for l = lags
    lagStr = [lagStr '-' num2str(l)];
end

trainOnNcepStr = '';
if trainOnNcep
    trainOnNcepStr = 'train-ncep';
end


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

dataset = 'cmip5';

load lat;
load lon;

regionInd = 10;
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
                  'ipsl-cm5a-mr', 'miroc-esm'};
    case 'us-se'
        models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
                  'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                  'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                  'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
                  'mpi-esm-mr', 'mri-cgcm3'};
    case 'europe'
        models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
                  'cmcc-cms', 'cnrm-cm5', ...
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
meanTempHistoricalNCEP = [];
meanBowenHistoricalNCEP = [];

meanTempHistoricalCmip5 = [];
meanBowenHistoricalCmip5 = [];

% future model temp/bowen
meanTempFuture = [];
meanBowenFuture = [];
% future predicted temp from modeled bowen (historical)
meanTempPredictedHistorical = [];
% and future bowen
meanTempPredictedFuture = [];
modelR2 = [];

% coefficient on the squared term to measure sensitivity
modelCoeff = [];
% is the squared coefficient significant
modelCoeffSig = [];

modelSig = [];

% NCEP-based model for each month
ncepModels = {};
% CMIP5 models for each month/model
cmip5Models = {};

for model = 1:length(models)

    % if we are loading NCEP and haven't done so already
    if trainOnNcep && model == 1
        ['loading NCEP...']
        load([baseDir '/monthly-bowen-temp/monthlyBowenTemp-historical-ncep-reanalysis-' timePeriodHistorical '.mat']);
        bowenTempNcep = monthlyBowenTemp;
        clear monthlyBowenTemp;    
    end
    
    % load historical CMIP5
    ['loading historical ' models{model} '...']
    load([baseDir '/monthly-bowen-temp/monthlyBowenTemp-' dataset '-' rcpHistorical '-' models{model} '-' timePeriodHistorical '.mat']);
    bowenTempCmip5 = monthlyBowenTemp;
    clear monthlyBowenTemp;    
    
    ['loading future ' models{model} '...']

    % load historical bowen data for comparison
    load([baseDir '/monthly-bowen-temp/monthlyBowenTemp-' dataset '-' rcpFuture '-' models{model} '-' timePeriodFuture '.mat']);
    bowenTempFuture = monthlyBowenTemp;
    clear monthlyBowenTemp;

    cmip5Models{model} = {};
    
    for month = months
        ['month = ' num2str(month) '...']
        tempCmip5 = [];
        bowenCmip5 = {};
        tempNcep = [];
        bowenNcep = {};
        
        tempFuture = [];
        bowenFuture = {};
        
        for l = 1:length(lags)
            lag = lags(l);
           
            bowenNcep{l} = [];
            bowenCmip5{l} = [];
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

                            % lists of temps for current month for all
                            % years (cmip5)
                            curMonthTempsCmip5 = bowenTempCmip5{1}{tempMonth}{curLat(xlat)}{curLon(ylon)};
                            curMonthBowensCmip5 = abs(bowenTempCmip5{2}{bowenMonth}{curLat(xlat)}{curLon(ylon)});
                            
                            % only process NCEP once, on first model
                            if model == 1
                                curMonthTempsNcep = bowenTempNcep{1}{tempMonth}{curLat(xlat)}{curLon(ylon)};
                                curMonthBowensNcep = abs(bowenTempNcep{2}{bowenMonth}{curLat(xlat)}{curLon(ylon)});
                            end

                            % start at year 2 to allow for lags
                            for year = 2:length(curMonthTempsCmip5)

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
                                    nextTempCmip5 = curMonthTempsCmip5(tempYear);
                                    nextBowenCmip5 = curMonthBowensCmip5(bowenYear);
                                    
                                    if model == 1
                                        nextTempNcep = curMonthTempsNcep(tempYear);
                                        nextBowenNcep = curMonthBowensNcep(bowenYear);
                                    end

                                    if ~isnan(nextTempCmip5) && ~isnan(nextBowenCmip5)
                                        
                                        % only take one temp - the current,
                                        % lag 0
                                        if l == 1
                                            tempCmip5 = [tempCmip5; nextTempCmip5];
                                        end
                                        
                                        bowenCmip5{l} = [bowenCmip5{l}; nextBowenCmip5];
                                    end
                                    
                                    % if we are on the first model and have
                                    % non-nan NCEP values, process them
                                    if model == 1 && ~isnan(nextTempNcep) && ~isnan(nextBowenNcep)
                                        % only take one temp - the current,
                                        % lag 0
                                        if l == 1
                                            tempNcep = [tempNcep; nextTempNcep];
                                        end
                                        
                                        bowenNcep{l} = [bowenNcep{l}; nextBowenNcep];
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

        % if using NCEP, only build models once (on first iteration)
        if trainOnNcep && model == 1
            curHistoricalTemp = tempNcep;
            curHistoricalBowen = bowenNcep;
        elseif trainOnNcep && model > 1
            curHistoricalTemp = [];
            curHistoricalBowen = [];
        else
            curHistoricalTemp = tempCmip5;
            curHistoricalBowen = bowenCmip5;
        end
        
        % if we have prediction data (either NCEP for first time or current
        % CMIP5 model)
        if length(curHistoricalBowen) > 0
            
            % create cell array of all bowen lags and the temp variable as
            % the last column
            tbl = table();
            for v = 1:length(curHistoricalBowen)
                if v > 1 && length(curHistoricalBowen{v}) < size(tbl, 1)
                    fill = zeros(size(tbl, 1) - length(curHistoricalBowen{v}), 1);
                    fill(fill == 0) = NaN;
                    if length(fill) > 0
                        curHistoricalBowen{v} = [curHistoricalBowen{v}; fill];
                    end
                elseif v > 1 && length(curHistoricalBowen{v}) > size(tbl, 1)
                    curHistoricalBowen{v} = curHistoricalBowen{v}(1:size(tbl, 1));
                end
                eval(['tbl.' 'lag' num2str(lags(v)) ' = curHistoricalBowen{' num2str(v) '};']);
            end
            tbl.temp = curHistoricalTemp;
            
            % convert cell into table
            modelBT = fitlm(tbl, fitType);

            % if using NCEP, need to save this month's model to use on
            % future CMIP5 data
            if trainOnNcep
                ncepModels{tempMonth} = modelBT;
            else
                cmip5Models{model}{tempMonth} = modelBT;
            end

            % get the model pValue out of the anova structure
            a = anova(modelBT, 'summary');
            modelSig(model, tempMonth) = a(2, 5).pValue < 0.05;

            % save r2 value of model
            modelR2(model, tempMonth) = modelBT.Rsquared.Ordinary;
            
            % save coefficient on squared term
            if length(lags) == 1
                modelCoeff(model, tempMonth) = modelBT.Coefficients.Estimate(end);
                modelCoeffSig(model, tempMonth) = modelBT.Coefficients.pValue(end) <= 0.05 && ...
                                                  modelBT.Coefficients.pValue(end) > 0;
            end
        end
        
        % mean of historical temp
        if model == 1
            meanTempHistoricalNCEP(model, month) = nanmean(tempNcep);
        end
        meanTempHistoricalCmip5(model, month) = nanmean(tempCmip5);

        % mean historical model bowen for all lags
        for l = 1:length(lags)
            if model == 1
                meanBowenHistoricalNCEP(month, l) = nanmean(bowenNcep{l});
            end
            meanBowenHistoricalCmip5(model, month, l) = nanmean(bowenCmip5{l});
        end

        % mean of future temp (CMIP5)
        meanTempFuture(model, month) = nanmean(tempFuture);
        
        % mean future model bowen for each lag
        for l = 1:length(lags)
            meanBowenFuture(model, month, l) = nanmean(bowenFuture{l});
        end

        clear tempNcep tempCmip5 tempFuture bowenNcep bowenCmip5 bowenFuture;
    end
    
    clear bowenTempNcep bowenTempCmip5 bowenTempFuture;
end

% predict future temps based on model trained on historical data,
% using future model bowen values as input
if trainOnNcep
    % trained using saved NCEP model for this month

    % now use CMIP5 mean percent bowen change to amplify bowens for
    % this region
    bowenChgCmip5 = [];
    for model = 1:size(meanBowenFuture, 1)
        bowenChgCmip5(model, :) = (meanBowenFuture(model, :) - meanBowenHistoricalCmip5(model, :)) ./ meanBowenHistoricalCmip5(model, :) + 1;
    end
    
    % multiply historical NCEP bowen by 
    meanBowenFutureNCEP = repmat(meanBowenHistoricalNCEP', size(bowenChgCmip5, 1), 1) .* bowenChgCmip5;
    
    for month = 1:12
        meanTempPredictedHistorical(month) = predict(ncepModels{month}, meanBowenHistoricalNCEP(month));
        % predict future based on modified NCEP bowens (for each CMIP5
        % model)
        for model = 1:size(meanBowenFutureNCEP, 1)
            meanTempPredictedFuture(model, month) = predict(ncepModels{month}, meanBowenFutureNCEP(model, month));
        end
    end
else
    % train using current CMIP5-based model
    % historical CMIP5 bowens
    meanTempPredictedHistorical(model, tempMonth) = predict(modelBT, squeeze(meanBowenHistoricalNCEP(model, tempMonth, :))');
    % and future CMIP5 bowen
    meanTempPredictedFuture(model, tempMonth) = predict(modelBT, squeeze(meanBowenFuture(model, tempMonth, :))');
end

% test for significance of bowen change at 95%
%[h, p, ci, stats] = ttest(meanTempFuture(model, month), meanTempPredicted(model, month), 0.05);

if trainOnNcep
    meanTempPredictedHistorical = repmat(meanTempPredictedHistorical, [size(meanTempFuture, 1), 1]);
    meanTempHistoricalNCEP = repmat(meanTempHistoricalNCEP, [size(meanTempFuture, 1), 1]);
end

% CMIP5 warming
warming = squeeze(meanTempFuture - meanTempHistoricalCmip5);
annMeanWarming = squeeze(nanmean(meanTempFuture - meanTempHistoricalCmip5, 2));

% make prediction based on historical CMIP5 bowens
if predictOnHistoricalCmip5
    warmingPredicted = meanTempPredictedHistorical - meanTempHistoricalNCEP;
    annMeanWarmingPredicted = nanmean(meanTempPredictedHistorical - meanTempHistoricalNCEP, 2);
else
    if showBowenModelChange
        % use historical bowens & future bowens and show the difference
        % between the two
        warmingPredicted = meanTempPredictedFuture - meanTempPredictedHistorical;
        annMeanWarmingPredicted = nanmean(meanTempPredictedFuture - meanTempPredictedHistorical, 2);
    else
        % normal - use future bowens and CMIP5 historical temps
        warmingPredicted = meanTempPredictedFuture - meanTempHistoricalNCEP;
        annMeanWarmingPredicted = nanmean(meanTempPredictedFuture - meanTempHistoricalNCEP, 2);
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
    export_fig(['seasonalDifference-' regionAb{regionInd} '-historical-test' '-' lagStr '-' trainOnNcepStr '.png']);
else
    if showBowenModelChange
        export_fig(['seasonalDifference-' regionAb{regionInd} '-bowen-model-change' '-' lagStr '-' trainOnNcepStr '.png']);
    else
        export_fig(['seasonalDifference-' regionAb{regionInd} '-' lagStr '-' trainOnNcepStr '.png']);
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

    % historical temps (NCEP)
    p1 = plot(1:12, nanmean(meanTempHistoricalNCEP, 1), 'LineWidth', 3, 'Color', [25/255.0, 158/255.0, 56/255.0]);

    % historical temps (predicted based on NCEP)
    p2 = plot(1:12, nanmean(meanTempPredictedHistorical, 1), 'LineWidth', 3, 'Color', [85/255.0, 158/255.0, 237/255.0]);
    
    % future temps (modeled)
    p3 = plot(1:12, nanmean(meanTempFuture, 1), 'LineWidth', 3, 'Color', [239/255.0, 71/255.0, 85/255.0]);

    % future temps (predicted)
    p4 = plot(1:12, nanmean(meanTempPredictedFuture, 1), 'LineWidth', 3, 'Color', 'k');

    leg = legend([p1, p2, p3, p4], 'NCEP historical', 'NCEP predicted historical', 'CMIP5 future', 'Predicted future');
    set(leg, 'FontSize', 20, 'location', 'south');
    xlabel('Month', 'FontSize', 24);
    ylabel(['Temperature ' char(176) 'C'], 'FontSize', 24);
    ylim([-10 40]);
    xlim([0.5 12.5]);
    set(gca, 'FontSize', 24);

    % right hand plot -------------------
    subplot(1,2,2);     
    grid on;

    [ax, p1, p2] = plotyy(1:12, nanmean(modelR2, 1), 1:12, ones(1, 12) .* 100);
    hold(ax(1));
    hold(ax(2));
    
    set(p1, 'Color', [0.3 0.3 0.3], 'LineWidth', 3);
    set(p2, 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 3);

    box(ax(1), 'on');
    axis(ax(1), 'square');
    axis(ax(2), 'square');

    set(ax(1), 'XTick', 1:12);
    set(ax(2), 'XTick', 1:12);
    set(ax(1), 'XLim', [.5 12.5]);
    set(ax(2), 'XLim', [.5 12.5]);
    set(ax(1), 'YLim', [0 1], 'YTick', [0 0.25 0.5 0.75 1]);
    set(ax(2), 'YLim', [-10 1], 'YTick', -10:2:0);
    set(ax(2), 'YColor', [25/255.0, 158/255.0, 56/255.0], 'FontSize', 24);
    set(ax(1), 'YColor', 'k', 'FontSize', 24);

    %plot(ax(1), 1:12, modelR2, 'Color', [0.6 0.6 0.6], 'LineWidth', 1);
    %plot(1:12, nanmean(modelR2, 1), 'Color', [0.3 0.3 0.3], 'LineWidth', 4);
    %ylim([0 1]);

    for month = 1:size(modelR2, 2)
        % plot significance markers on R2 plot
        p5 = plot(ax(1), month, nanmean(modelR2(:, month), 1), 'o', 'MarkerSize', 15, 'Color', [0.5 0.5 0.5], 'MarkerEdgeColor', 'k');
        
        % if training on ncep, then only need the ncep model to be
        % significant
        if trainOnNcep
            sigCutoff = 0;
        else
            % otherwise, want 2/3 of CMIP5 models to be sig
            sigCutoff = 0.66*length(models);
        end
        
        if length(find(modelSig(:, month))) > sigCutoff
            set(p5, 'LineWidth', 3, 'MarkerFaceColor', [0.5 0.5 0.5]);
        else
            set(p5, 'LineWidth', 3);
        end
        
        % plot significance markers on coeff plot plot
        p6 = plot(ax(2), month, modelCoeff(month), 'o', 'MarkerSize', 15, 'Color', [25/255.0, 158/255.0, 56/255.0], 'MarkerEdgeColor', 'k');
        if modelCoeffSig(month)
            set(p6, 'LineWidth', 3, 'MarkerFaceColor', [25/255.0, 158/255.0, 56/255.0]);
        else
            set(p6, 'LineWidth', 3);
        end
    end

    %xlim([0.5 12.5]);
    set(gca, 'FontSize', 24);
    xlabel('Month', 'FontSize', 24);
    ylabel(ax(1), 'R2', 'FontSize', 24);
    ylabel(ax(2), 'Coefficient', 'FontSize', 24);

    set(gcf, 'Position', get(0,'Screensize'));
    export_fig(['r2Prediction-' regionAb{regionInd} '-' dataset '-BT-' monthlyMeanStr '-' lagStr '-' trainOnNcepStr '.png']);
    close all;
end



