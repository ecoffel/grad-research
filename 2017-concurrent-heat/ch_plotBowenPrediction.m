% look at monthly mean temp/bowen fit or monthly mean max temperature &
% mean bowen
monthlyMean = true;

% plot curves for each model separately
plotEachModel = false;

% plot scatter plots for each month of bowen, temp
plotScatter = false;

% whether to predict the difference between the monthly warming and the the annual mean warming
predictDifference = true;

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

regionInd = 10;
months = 1:12;

baseDir = 'e:/data';

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

if strcmp(regionAb{regionInd}, 'amazon') || strcmp(regionAb{regionInd}, 'sa-n')
    % in amazon leave out csiro, canesm2, ipsl
    models = {'access1-0', 'access1-3', 'bnu-esm', ...
                  'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', ...
                  'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                  'hadgem2-es', 'miroc-esm', ...
                  'mpi-esm-mr', 'mri-cgcm3'};
elseif strcmp(regionAb{regionInd}, 'india')
    % in india leave out csiro and mri-cgcm3
    models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
                  'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', ...
                  'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                  'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
                  'mpi-esm-mr'};
elseif strcmp(regionAb{regionInd}, 'africa')
    % leave out 'mri-cgcm3'
    models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
                  'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                  'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                  'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
                  'mpi-esm-mr'};
elseif strcmp(regionAb{regionInd}, 'us-cent') || strcmp(regionAb{regionInd}, 'us-se') || ...
        strcmp(regionAb{regionInd}, 'europe') || strcmp(regionAb{regionInd}, 'med')
    % leave out mri-cgcm3, gfdl-esm2m, gfdl-esm2g' due to bad temp performance
    models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
                  'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                  'gfdl-cm3', 'hadgem2-cc', ...
                  'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
                  'mpi-esm-mr'};
else
    % leave out 'bcc-csm1-1-m' and 'inmcm4' due to bad bowen performance
    models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
                  'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                  'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                  'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
                  'mpi-esm-mr', 'mri-cgcm3'};
end

dataset = 'cmip5';
       
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
% future predicted temp from modeled bowen
meanTempPredicted = [];
modelR2 = [];
modelSig = [];

for model = 1:length(models)
    ['processing ' models{model} '...']

    load([baseDir '/daily-bowen-temp/dailyBowenTemp-' rcpHistorical '-' models{model} '-' timePeriodHistorical '.mat']);
    bowenTemp=dailyBowenTemp;
    clear dailyBowenTemp;

    ['loading future ' models{model} '...']

    % load historical bowen data for comparison
    load([baseDir '/daily-bowen-temp/dailyBowenTemp-' rcpFuture '-' models{model} '-' timePeriodFuture '.mat']);
    bowenTempFuture=dailyBowenTemp;
    clear dailyBowenTemp;

    for month = months
        ['month = ' num2str(month) '...']
        temp = [];
        bowen = [];
        tempFuture = [];
        bowenFuture = [];


        for xlat = 1:length(curLat)
            for ylon = 1:length(curLon)
                % get all temp/bowen daily points for current region
                % into one list (combines gridboxes & years for current model)
                if monthlyMean
                    % historical --------------------
                    nextTemp = nanmean(bowenTemp{1}{month}{curLat(xlat)}{curLon(ylon)}');
                    nextBowen = nanmean(abs(bowenTemp{2}{month}{curLat(xlat)}{curLon(ylon)}'));

                    % only add full pairs
                    if length(nextTemp) > 0 && ~isnan(nextTemp) && ~isnan(nextBowen)
                        temp = [temp; nextTemp];
                        bowen = [bowen; nextBowen];
                    end
                    
                    % future -----------------------
                    nextTemp = nanmean(bowenTempFuture{1}{month}{curLat(xlat)}{curLon(ylon)}');
                    nextBowen = nanmean(abs(bowenTempFuture{2}{month}{curLat(xlat)}{curLon(ylon)}'));

                    % only add full pairs
                    if length(nextTemp) > 0 && ~isnan(nextTemp) && ~isnan(nextBowen)
                        tempFuture = [tempFuture; nextTemp];
                        bowenFuture = [bowenFuture; nextBowen];
                    end
                else
                    % historical ------------------------
                    nextTemp = nanmax(bowenTemp{1}{month}{curLat(xlat)}{curLon(ylon)}');
                    nextBowen = nanmean(abs(bowenTemp{2}{month}{curLat(xlat)}{curLon(ylon)}'));

                    % only add full pairs
                    if length(nextTemp) > 0 && ~isnan(nextTemp) && ~isnan(nextBowen)
                        temp = [temp; nextTemp];
                        bowen = [bowen; nextBowen];
                    end
                    
                    % future -----------------------------
                    nextTemp = nanmax(bowenTempFuture{1}{month}{curLat(xlat)}{curLon(ylon)}');
                    nextBowen = nanmean(abs(bowenTempFuture{2}{month}{curLat(xlat)}{curLon(ylon)}'));

                    % only add full pairs
                    if length(nextTemp) > 0 && ~isnan(nextTemp) && ~isnan(nextBowen)
                        tempFuture = [tempFuture; nextTemp];
                        bowenFuture = [bowenFuture; nextBowen];
                    end
                end
            end
        end

        modelBT = fitlm(bowen, temp, fitType);

        % get the model pValue out of the anova structure
        a = anova(modelBT, 'summary');
        modelSig(model, month) = a(2, 5).pValue < 0.05;

        % save r2 value of model
        modelR2(model, month) = modelBT.Rsquared.Ordinary;
        
        % mean historical model temp/bowen
        meanTempHistorical(model, month) = nanmean(temp);
        meanBowenHistorical(model, month) = nanmean(bowen);
        
        % mean future model temp/bowen
        meanTempFuture(model, month) = nanmean(tempFuture);
        meanBowenFuture(model, month) = nanmean(bowenFuture);

        
        
        % predict future temps based on model trained on historical data,
        % using future model bowen values as input
        meanTempPredicted(model, month) = predict(modelBT, meanBowenFuture(model, month));
        
        
        
        % test for significance of bowen change at 95%
        %[h, p, ci, stats] = ttest(meanTempFuture(model, month), meanTempPredicted(model, month), 0.05);

        clear temp tempFuture bowen bowenFuture;
    end
    
    
    
    clear bowenTemp bowenTempFuture;
end

warming = meanTempFuture - meanTempHistorical;
warmingPredicted = meanTempPredicted - meanTempHistorical;
annMeanWarming = nanmean(meanTempFuture - meanTempHistorical, 2);
annMeanWarmingPredicted = nanmean(meanTempPredicted - meanTempHistorical, 2);

diff = warming;
predictedDiff = warmingPredicted;

for m = 1:12
    diff(:,m) = diff(:, m) - annMeanWarming;
    predictedDiff(:,m) = predictedDiff(:,m) - annMeanWarmingPredicted;
end

% error in seasonal anomalies
diffErr = nanstd(diff, [], 1);
predictedDiffErr = nanstd(predictedDiff, [], 1);

figure('Color', [1,1,1]);
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
legend([p1.mainLine, p2.mainLine], 'CMIP5', 'Bowen model', 'location', 'best');
export_fig(['seasonalDifference-' regionAb{regionInd} '.png'], '-m2');
close all;

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
p3 = plot(1:12, nanmean(meanTempPredicted, 1), 'LineWidth', 3, 'Color', 'k');

leg = legend([p1, p2, p3], 'CMIP5 historical', 'CMIP5 future', 'Predicted');
set(leg, 'FontSize', 20, 'location', 'best');
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
export_fig(['r2Prediction-' regionAb{regionInd} '-' dataset '-BT-' monthlyMeanStr '.png'], '-m2');
close all;



