
% should we look at change between rcp & historical (only for cmip5)
change = false;

% look at monthly mean temp/bowen fit or monthly mean max temperature &
% mean bowen
monthlyMean = true;

% plot curves for each model separately
plotEachModel = false;

% plot scatter plots for each month of bowen, temp
plotScatter = false;

% use CMIP5 or ncep
useNcep = true;

% use bowen lag months behind temperature as predictor
lag = 0;

% show monthly temp and bowen variability
showVar = true;

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

regionInd = 4;
months = 1:12;

baseDir = 'f:/data';

rcpStr = 'historical';
if change
    rcpStr = 'chg';
end

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

if useNcep
    models = {'ncep-reanalysis'};
end

dataset = 'cmip5';
if length(models) == 1 && strcmp(models{1}, 'ncep-reanalysis')
    dataset = 'ncep';
end
       
regionLatLonInd = {};

% loop over all regions to find lat/lon indicies
for i = 1:size(regions, 1)
    [latIndexRange, lonIndexRange] = latLonIndexRange({lat, lon, []}, regions(i, 1:2), regions(i, 3:4));
    regionLatLonInd{i} = {latIndexRange, lonIndexRange};
end

curLat = regionLatLonInd{regionInd}{1};
curLon = regionLatLonInd{regionInd}{2};

regionalAnalysis = true;

if regionalAnalysis
    
    % create lagged months list to index monthly bowen
    laggedMonths = [];
    for i = 1:12
        laggedMonths(i) = i+lag;
        if laggedMonths(i) > 12
            laggedMonths(i) = laggedMonths(i) - 12;
        end
    end
    
    % temp/bowen pairs for this region, by months
    linModels = {};
    meanTemp = [];
    meanTempStd = [];
    meanBowen = [];
    meanBowenStd = [];
    r2TB = [];
    r2BT = [];
    
    modelSig = [];
    
    if change
        linModelsFuture = {};
        meanTempFuture = [];
        meanBowenFuture = [];
        r2FutureTB = [];
        r2FutureBT = [];
        
        % are the monthly/model changes in bowen statistically significant
        changePower = [];
        changeSig = [];
    end

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
        
        linModels{model} = {};
        if change
            linModelsFuture{model} = {};
        end
        
        for month = months
            
            % look at temps in current month
            tempMonth = month;
            % look at bowens in lagged month
            bowenMonth = month - lag;
            % limit bowen month and roll over (0 -> dec, -1 -> nov, etc)
            if bowenMonth <= 0
                bowenMonth = 12 + bowenMonth;
            end
            
            ['temp month = ' num2str(tempMonth) ', bowen month = ' num2str(bowenMonth) '...']
            
            temp = [];
            tempStd = [];
            bowen = [];
            bowenStd = [];
            
            if change
                tempFuture = [];
                bowenFuture = [];
            end
            
            for xlat = 1:length(curLat)
                for ylon = 1:length(curLon)
                    % get all temp/bowen daily points for current region
                    % into one list (combines gridboxes & years for current model)
                    if monthlyMean
                        nextTemp = nanmean(bowenTemp{1}{tempMonth}{curLat(xlat)}{curLon(ylon)}');
                        nextTempStd = nanstd(bowenTemp{1}{tempMonth}{curLat(xlat)}{curLon(ylon)}');
                        nextBowen = nanmean(abs(bowenTemp{2}{bowenMonth}{curLat(xlat)}{curLon(ylon)}'));
                        nextBowenStd = nanstd(abs(bowenTemp{2}{bowenMonth}{curLat(xlat)}{curLon(ylon)}'));
                        
                        % only add full pairs
                        if length(nextTemp) > 0 && ~isnan(nextTemp) && ~isnan(nextBowen)
                            temp = [temp; nextTemp];
                            bowen = [bowen; nextBowen];
                            tempStd = [tempStd; nextTempStd];
                            bowenStd = [bowenStd; nextBowenStd];
                        end
                    else
                        nextTemp = nanmax(bowenTemp{1}{tempMonth}{curLat(xlat)}{curLon(ylon)}');
                        nextBowen = nanmean(abs(bowenTemp{2}{bowenMonth}{curLat(xlat)}{curLon(ylon)}'));
                        
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
                            nextTemp = nanmean(bowenTempFuture{1}{tempMonth}{curLat(xlat)}{curLon(ylon)}');
                            nextBowen = nanmean(abs(bowenTempFuture{2}{bowenMonth}{curLat(xlat)}{curLon(ylon)}'));
                            
                            % only add full pairs
                            if length(nextTemp) > 0 && ~isnan(nextTemp) && ~isnan(nextBowen)
                                tempFuture = [tempFuture; nextTemp];
                                bowenFuture = [bowenFuture; nextBowen];
                            end
                        else
                            nextTemp = nanmax(bowenTempFuture{1}{tempMonth}{curLat(xlat)}{curLon(ylon)}');
                            nextBowen = nanmean(abs(bowenTempFuture{2}{bowenMonth}{curLat(xlat)}{curLon(ylon)}'));

                            % only add full pairs
                            if length(nextTemp) > 0 && ~isnan(nextTemp) && ~isnan(nextBowen)
                                tempFuture = [tempFuture; nextTemp];
                                bowenFuture = [bowenFuture; nextBowen];
                            end
                        end

                    end
                end
            end
            
            if plotScatter
                scatter(bowen, temp);
                export_fig(['2017-concurrent-heat/bowen-temp-scatter/scatter-' regionAb{regionInd} '-' num2str(month) '-' dataset '-historical.png']);
                close all;
            end
            
            modelTB = fitlm(temp, bowen, fitType);
            modelBT = fitlm(bowen, temp, fitType);
            r2TB(model, month) = modelTB.Rsquared.Ordinary;
            r2BT(model, month) = modelBT.Rsquared.Ordinary;
            
            % get the model pValue out of the anova structure
            a = anova(modelBT, 'summary');
            modelSig(model, month) = a(2, 5).pValue < 0.05;
            
            meanTemp(model, month) = nanmean(temp);
            meanBowen(model, month) = nanmean(bowen);
            
            meanTempStd(model, month) = nanmean(tempStd);
            meanBowenStd(model, month) = nanmean(bowenStd);
            
            % fit model for future data if looking at change
            if change
                modelFutureTB = fitlm(tempFuture, bowenFuture, fitType);
                modelFutureBT = fitlm(bowenFuture, tempFuture, fitType);
                r2FutureTB(model, month) = modelFutureTB.Rsquared.Ordinary;
                r2FutureBT(model, month) = modelFutureBT.Rsquared.Ordinary;
                meanTempFuture(model, month) = nanmean(tempFuture);
                meanBowenFuture(model, month) = nanmean(bowenFuture);
                
                % test for significance of bowen change at 95%
                [h, p, ci, stats] = ttest(bowen, bowenFuture, 0.05);
                changePower(model, month) = p;
                changeSig(model, month) = h;
                
                clear tempFuture bowenFuture;
            end

            clear temp bowen;
        end
        clear bowenTemp bowenTempFuture;
    end

    if plotEachModel
        for model = 1:length(models)
            figure('Color',[1,1,1]);
            subplot(1,2,1);
            hold on;
            axis square;
            grid on;
            box on;
            if change
                [ax,p1,p2] = plotyy(1:12, meanTempFuture(model,:) - meanTemp(model,:), 1:12, meanBowenFuture(model,:) - meanBowen(model,:));
            else
                [ax,p1,p2] = plotyy(1:12, meanTemp(model,:), 1:12, meanBowen(model,:));
                [ax2,p3,p4] = plotyy(1:12, nanmean(meanTemp(model,:), 1), 1:12, nanmean(meanBowen(model,:), 1));
            end
            hold(ax(1));
            hold(ax(2));
            hold(ax2(1));
            hold(ax2(2));
            box(ax(1), 'on');
            box(ax2(1), 'on');
            axis(ax(1), 'square');
            axis(ax(2), 'square');
            axis(ax2(1), 'square');
            axis(ax2(2), 'square');
            set(p1, 'Color', 'r');
            set(p2, 'Color', 'b');
            set(p3, 'Color', 'r', 'LineWidth', 3);
            set(p4, 'Color', 'b', 'LineWidth', 3);
            set(ax(1), 'YColor', 'r');
            set(ax(2), 'YColor', 'b');
            set(ax(1), 'XLim', [1 12], 'XTick', 1:12);
            set(ax(2), 'XLim', [1 12], 'XTick', []);
            set(ax2(1), 'YColor', 'r');
            set(ax2(2), 'YColor', 'b');
            set(ax2(1), 'XLim', [1 12], 'XTick', 1:12);
            set(ax2(2), 'XLim', [1 12], 'XTick', []);
            if change
                set(ax(1), 'YLim', [-1 8], 'YTick', -1:8);
                set(ax(2), 'YLim', [-5 5], 'YTick', -5:5);
                set(ax2(1), 'YLim', [-1 8], 'YTick', -1:8);
                set(ax2(2), 'YLim', [-5 5], 'YTick', -5:5);
            else
                set(ax(1), 'YLim', [0 40], 'YTick', [0 10 20 30 40]);
                set(ax(2), 'YLim', [0 5], 'YTick', [0 1 2 3 4 5]);
                set(ax2(1), 'YLim', [0 40], 'YTick', [0 10 20 30 40]);
                set(ax2(2), 'YLim', [0 5], 'YTick', [0 1 2 3 4 5]);
            end
            xlabel('month');
            ylabel(ax(1), 'temp');
            ylabel(ax(2), 'bowen');
            subplot(1,2,2);
            hold on;
            axis square;
            grid on;
            box on;
            if change
                plot(1:12, r2FutureTB(model,:) - r2TB(model,:), 'Color', [0.4 0.4 0.4]);
                ylim([-0.5 0.5]);
            else
                plot(1:12, r2TB(model,:), 'Color', [0.4 0.4 0.4]);
                plot(1:12, nanmean(r2TB(model,:), 1), 'Color', [0.4 0.4 0.4], 'LineWidth', 3);
                ylim([0 1]);
            end
            xlabel('month');
            ylabel('r2');
            export_fig(['r2-' regionAb{regionInd} '-' dataset '-historical-' monthlyMeanStr '-' models{model} '.png'], '-m2');
            close all;
        end
    else
        fig = figure('Color',[1,1,1]);
        subplot(1,2,1);
        box on;
        if change
            % plot multi-model mean change
            [ax,p1,p2] = plotyy(1:12, nanmean(meanTempFuture - meanTemp, 1), 1:12, nanmean(meanBowenFuture - meanBowen));
            hold(ax(1));
            hold(ax(2));
            
            set(p1, 'Color', [239/255.0, 71/255.0, 85/255.0], 'LineWidth', 4);
            set(p2, 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 4);
            
            % plot individual models for temp/bowen change
            for model = 1:length(models)        
                p3 = plot(ax(1), 1:12, meanTempFuture(model, :) - meanTemp(model, :), 'Color', [239/255.0, 71/255.0, 85/255.0], 'LineWidth', 1);
                p3 = plot(ax(2), 1:12, meanBowenFuture(model, :) - meanBowen(model, :), 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 1);
            end
            
            for month = 1:size(meanBowenFuture, 2)
                p5 = plot(ax(2), month, nanmean(meanBowenFuture(:, month) - meanBowen(:, month), 1), 'o', 'MarkerSize', 15, 'Color', [25/255.0, 158/255.0, 56/255.0], 'MarkerEdgeColor', 'k');
                if length(find(changeSig(:, month))) > 0.66*length(models)
                    set(p5, 'LineWidth', 3, 'MarkerFaceColor', [25/255.0, 158/255.0, 56/255.0]);
                else
                    set(p5, 'LineWidth', 3);
                end
            end
        else
            
            % plot multi-model mean
            [ax,p1,p2] = plotyy(1:12, nanmean(meanTemp, 1), 1:12, nanmean(meanBowen(:, laggedMonths), 1));
            hold(ax(1));
            hold(ax(2));
            
            set(p1, 'Color', [239/255.0, 71/255.0, 85/255.0], 'LineWidth', 4);
            set(p2, 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 4);
            
            % plot individual models for temp/bowen change
            p3 = plot(ax(1), 1:12, meanTemp, 'Color', [239/255.0, 71/255.0, 85/255.0], 'LineWidth', 1);
            p4 = plot(ax(2), 1:12, meanBowen(:, laggedMonths), 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 1);
            
            % plot zero lines
            plot(ax(1), 1:12, zeros(12, 1), '--', 'LineWidth', 2, 'Color', [239/255.0, 71/255.0, 85/255.0]);
            plot(ax(2), 1:12, zeros(12, 1), '--', 'LineWidth', 2, 'Color', [25/255.0, 158/255.0, 56/255.0]);
            
            %tempCV = nanmean(meanTempStd, 1) ./ nanmean(meanTemp, 1);
            bowenCV = nanmean(meanBowenStd, 1) ./ nanmean(meanBowen, 1);
            
            % plot the temperature STD
            er1 = errorbar(ax(1), 1:12, nanmean(meanTemp, 1), nanmean(meanTempStd, 1) ./ 2);
            set(er1, 'LineWidth', 2, 'Color', [239/255.0, 71/255.0, 85/255.0]);
            
            % and the bowen coefficient of variability (STD / mean)
            er2 = errorbar(ax(2), 1:12, nanmean(meanBowen(:, laggedMonths), 1), bowenCV(laggedMonths) ./ 2);
            set(er2, 'LineWidth', 2, 'Color', [25/255.0, 158/255.0, 56/255.0]);
            
        end
        
        %grid(ax(1), 'on');
        box(ax(1), 'on');
        axis(ax(1), 'square');
        axis(ax(2), 'square');
        set(ax(1), 'YColor', [239/255.0, 71/255.0, 85/255.0]);
        set(ax(2), 'YColor', [25/255.0, 158/255.0, 56/255.0]);
        set(ax(1), 'XLim', [0.5 12.5], 'XTick', 1:12);
        set(ax(2), 'XLim', [0.5 12.5], 'XTick', []);
        if change
            set(ax(1), 'YLim', [-1 8], 'YTick', -1:8);
            set(ax(2), 'YLim', [-5 5], 'YTick', -5:5);
        else
            set(ax(1), 'YLim', [-10 40], 'YTick', [-10 0 10 20 30 40]);
            if strcmp(regionAb{regionInd}, 'india')
                set(ax(2), 'YLim', [0 15], 'YTick', 0:3:15);
            else
                set(ax(2), 'YLim', [-5 15], 'YTick', -5:3:15);
            end
        end
        set(ax(1), 'FontSize', 24);
        set(ax(2), 'FontSize', 24);
        xlabel('Month', 'FontSize', 24);
        if change
            ylabel(ax(1), 'Temperature change', 'FontSize', 24);
            ylabel(ax(2), 'Bowen change', 'FontSize', 24);
        else
            ylabel(ax(1), 'Temperature', 'FontSize', 24);
            ylabel(ax(2), 'Bowen', 'FontSize', 24);
        end
        
        % right hand plot -------------------
        subplot(1,2,2);
        hold on;
        axis square;
        grid on;
        box on;
        if change
            %plot(1:12, r2FutureTB - r2TB, 'Color', [0.4 0.4 0.4]);
            %plot(1:12, nanmean(r2FutureTB - r2TB, 1), 'Color', [0.4 0.4 0.4], 'LineWidth', 3);
            plot(1:12, r2FutureBT - r2BT, 'Color', [0.6 0.6 0.6]);
            plot(1:12, nanmean(r2FutureBT - r2BT, 1), 'Color', [0.3 0.3 0.3], 'LineWidth', 4);
            ylim([-0.5 0.5]);
        else
            %plot(1:12, r2TB, 'Color', [0.4 0.4 0.4]);
            %plot(1:12, nanmean(r2TB, 1), 'Color', [0.4 0.4 0.4], 'LineWidth', 3);
            plot(1:12, r2BT, 'Color', [0.6 0.6 0.6], 'LineWidth', 1);
            plot(1:12, nanmean(r2BT, 1), 'Color', [0.3 0.3 0.3], 'LineWidth', 4);
            ylim([0 1]);
            
            for month = 1:size(r2BT, 2)
                p5 = plot(month, nanmean(r2BT(:, month), 1), 'o', 'MarkerSize', 15, 'Color', [0.5 0.5 0.5], 'MarkerEdgeColor', 'k');
                if length(find(modelSig(:, month))) > 0.66*length(models)
                    set(p5, 'LineWidth', 3, 'MarkerFaceColor', [0.5 0.5 0.5]);
                else
                    set(p5, 'LineWidth', 3);
                end
            end
        end
        xlim([0.5 12.5]);
        set(gca, 'FontSize', 24);
        xlabel('Month', 'FontSize', 24);
        if change
            ylabel('R2 change', 'FontSize', 24);
        else
            ylabel('R2', 'FontSize', 24);
        end
        
        set(gcf, 'Position', get(0,'Screensize'));
        export_fig(['r2-' regionAb{regionInd} '-' dataset '-' rcpStr '-BT-' monthlyMeanStr '-lag-' num2str(lag)  '.png'], '-m2');
        
    end
    
else
    
    r2TB = [];
    r2BT = [];
    rmse = [];
    
    for model = 1:length(models)
        ['processing ' models{model} '...']
        load([baseDir '/daily-bowen-temp/dailyBowenTemp-historical-' models{model} '-1985-2004.mat']);
        bowenTemp=dailyBowenTemp;
        clear dailyBowenTemp;
        for month = months
            
            for xlat = 1:length(curLat)
                for ylon = 1:length(curLon)

                    ind = find(~isnan(bowenTemp{1}{month}{curLat(xlat)}{curLon(ylon)}));
                    if length(ind) > 100
                        lm = fitlm(bowenTemp{1}{month}{curLat(xlat)}{curLon(ylon)}(ind)', bowenTemp{2}{month}{curLat(xlat)}{curLon(ylon)}(ind)', fitType);
                        r2TB(xlat, ylon, model, month) = lm.Rsquared.Ordinary;
                        rmse(xlat, ylon, model, month) = lm.RMSE;
                        
                        lm = fitlm(bowenTemp{2}{month}{curLat(xlat)}{curLon(ylon)}(ind)', bowenTemp{1}{month}{curLat(xlat)}{curLon(ylon)}(ind)', fitType);
                        r2BT(xlat, ylon, model, month) = lm.Rsquared.Ordinary;
                    else
                        r2TB(xlat, ylon, model, month) = NaN;
                        r2BT(xlat, ylon, model, month) = NaN;
                        rmse(xlat, ylon, model, month) = NaN;
                    end
                end
            end

            
        end
    end
    
    for month = months
        result = {lat(curLat,curLon), lon(curLat,curLon), squeeze(nanmean(r2BT(:,:,:,month), 3))};
        saveData = struct('data', {result}, ...
                          'plotRegion', 'world', ...
                          'plotRange', [0 1], ...
                          'cbXTicks', [0 .25 .5 .75 1], ...
                          'plotTitle', 'R2', ...
                          'fileTitle', ['r2-' dataset '-' num2str(month) '-' rcpHistorical '-' timePeriodHistorical '.png'], ...
                          'plotXUnits', 'R2', ...
                          'blockWater', true, ...
                          'magnify', '2');
        plotFromDataFile(saveData);  
    end

end




