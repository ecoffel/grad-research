
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
useNcep = false;

% use bowen lag months behind temperature as predictor
lags = 0;

% show monthly temp and bowen variability
showVar = true;

% type of model to fit to data
fitType = 'poly2';

rcpHistorical = 'historical';
rcpFuture = 'rcp85';

timePeriodHistorical = '1985-2004';
timePeriodFuture = '2021-2040';

monthlyMeanStr = 'monthlyMean';
if ~monthlyMean
    monthlyMeanStr = 'monthlyMax';
end

load lat;
load lon;

regionInd = 4;
months = 1:12;

baseDir = 'f:/data/bowen';

rcpStr = 'historical';
if change
    rcpStr = 'chg';
end

datasetStr = 'cmip5';
if useNcep
    datasetStr = 'ncep-reanalysis';
end

regionNames = {'World', ...
                'Central U.S.', ...
                'Southeast U.S.', ...
                'Central Europe', ...
                'Mediterranean', ...
                'Northern SA', ...
                'Amazon', ...
                'India', ...
                'West Africa', ...
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
            'africa-west', ...
            'africa-cent', ...
            'tropics'};
            
regions = [[[-90 90], [0 360]]; ...             % world
           [[35 46], [-107 -88] + 360]; ...     % central us
           [[25 35], [-103 -75] + 360]; ...      % southeast us
           [[45, 55], [10, 35]]; ...            % Europe
           [[36 45], [-5+360, 40]]; ...        % Med
           [[5 20], [-90 -45]+360]; ...         % Northern SA
           [[-10, 1], [-75, -53]+360]; ...      % Amazon
           [[8, 26], [67, 90]]; ...             % India
           [[7, 20], [-15 + 360, 15]]; ...          % west Africa
           [[-10 10], [15, 30]]; ...            % central Africa
           [[-20 20], [0 360]]];                % Tropics

switch regionAb{regionInd}
    
    %         {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
%               'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
%               'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
%               'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
%               'mpi-esm-mr', 'mri-cgcm3'};

    
    case 'us-cent'
        models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
              'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'gfdl-cm3', 'hadgem2-cc', ...
              'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
              'mpi-esm-mr'};
    case 'us-se'
        models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
              'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'gfdl-cm3', 'hadgem2-cc', ...
              'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
              'mpi-esm-mr'};
    case 'europe'
        models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
              'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'gfdl-cm3', 'hadgem2-cc', ...
              'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
              'mpi-esm-mr'};
    case 'med'
        models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
              'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'gfdl-cm3', 'hadgem2-cc', ...
              'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
              'mpi-esm-mr'};
    case 'sa-n'
        models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
              'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3'};
    case 'amazon'
        models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
              'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3'};
    case 'india'
        models = {'bnu-esm', 'cnrm-cm5', ...
                  'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', ...
                  'ipsl-cm5a-mr', 'miroc-esm'};
    case 'africa-west'
        models = {'cnrm-cm5', 'csiro-mk3-6-0', ...
                  'gfdl-esm2g', 'gfdl-esm2m'};
    case 'africa-cent'
        models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
              'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3'};
end


if useNcep
    models = {''};
end

dataset = 'cmip5';
if useNcep
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


for lag = lags

    % create lagged months list to index monthly bowen
    laggedMonths = [];
    for i = 1:12
        laggedMonths(i) = i+lag;
        if laggedMonths(i) > 12
            laggedMonths(i) = laggedMonths(i) - 12;
        end
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

    for model = 1:length(models)
        ['processing ' models{model} '...']

        if monthlyMean
            load([baseDir '/monthly-bowen-temp/monthlyBowenTemp-' datasetStr '-' rcpHistorical '-' models{model} '-' timePeriodHistorical '.mat']);
            bowenTemp = monthlyBowenTemp;
            clear monthlyBowenTemp;
        end

        if change
            ['loading future ' models{model} '...']

            % load historical bowen data for comparison
            if monthlyMean
                load([baseDir '/monthly-bowen-temp/monthlyBowenTemp-' datasetStr '-' rcpFuture '-' models{model} '-' timePeriodFuture '.mat']);
                bowenTempFuture = monthlyBowenTemp;
                clear monthlyBowenTemp;
            end
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

                        % lists of temps for current month for all years
                        curMonthTemps = bowenTemp{1}{tempMonth}{curLat(xlat)}{curLon(ylon)};
                        curMonthBowens = abs(bowenTemp{2}{bowenMonth}{curLat(xlat)}{curLon(ylon)});

                        ind = find(curMonthBowens <= 10);
                        
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

                            % this condition will slightly change the mean
                            % temperature and bowen for lagged plots
                            if bowenYear > 0
                                nextTemp = curMonthTemps(tempYear);
                                nextBowen = curMonthBowens(bowenYear);

                                if ~isnan(nextTemp) && ~isnan(nextBowen)
                                    temp = [temp; nextTemp];
                                    bowen = [bowen; nextBowen];
                                end
                            end
                        end

                        % get STD for temp/bowen for this gridcell/month
                        nextTempStd = nanstd(curMonthTemps);
                        nextBowenStd = nanstd(curMonthBowens);

                        % add to error lists
                        tempStd = [tempStd; nextTempStd];
                        bowenStd = [bowenStd; nextBowenStd];

                    end

                    if change
                        % and do the same for future data if we're looking
                        % at a change
                        if monthlyMean
                           
                            % lists of temps for current month for all years
                            curMonthTemps = bowenTempFuture{1}{tempMonth}{curLat(xlat)}{curLon(ylon)};
                            curMonthBowens = abs(bowenTempFuture{2}{bowenMonth}{curLat(xlat)}{curLon(ylon)});

                            ind = find(curMonthBowens <= 10);
                        
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

                                % this condition will slightly change the mean
                                % temperature and bowen for lagged plots
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
            end

            if plotScatter
                scatter(bowen, temp);
                export_fig(['2017-concurrent-heat/bowen-temp-scatter/scatter-' regionAb{regionInd} '-' num2str(month) '-' dataset '-historical.png']);
                close all;
            end

            modelBT = fitlm(bowen, temp, fitType);
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
                modelFutureBT = fitlm(bowenFuture, tempFuture, fitType);
                r2FutureBT(model, month) = modelFutureBT.Rsquared.Ordinary;
                meanTempFuture(model, month) = nanmean(tempFuture);
                meanBowenFuture(model, month) = nanmean(bowenFuture);

                % test for significance of bowen change at 95%
                [h, p, ci, stats] = ttest(bowen(1:min(length(bowen), length(bowenFuture))), bowenFuture(1:min(length(bowen), length(bowenFuture))), 0.05);
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
            for k = 1:size(meanTemp, 1)
                p3 = plot(ax(1), 1:12, meanTemp(k, :), 'Color', [239/255.0, 71/255.0, 85/255.0], 'LineWidth', 1);
                p4 = plot(ax(2), 1:12, meanBowen(k, laggedMonths), 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 1);
            end

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
            set(ax(2), 'YLim', [-5 15], 'YTick', -5:3:15);
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
            for k = 1:size(r2BT, 1)
                plot(1:12, r2FutureBT(k, :) - r2BT(k, :), 'Color', [0.6 0.6 0.6]);
            end
            plot(1:12, nanmean(r2FutureBT - r2BT, 1), 'Color', [0.3 0.3 0.3], 'LineWidth', 4);
            ylim([-0.5 0.5]);
        else
            %plot(1:12, r2TB, 'Color', [0.4 0.4 0.4]);
            %plot(1:12, nanmean(r2TB, 1), 'Color', [0.4 0.4 0.4], 'LineWidth', 3);
            for k = 1:size(r2BT, 1)
                plot(1:12, r2BT(k, :), 'Color', [0.6 0.6 0.6], 'LineWidth', 1);
            end
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
        if change
            export_fig(['r2Fit-' regionAb{regionInd} '-' dataset '-' rcpStr '-BT-' monthlyMeanStr '-lag-' num2str(lag) '-' timePeriodFuture  '.png'], '-m2');
        else
            export_fig(['r2Fit-' regionAb{regionInd} '-' dataset '-' rcpStr '-BT-' monthlyMeanStr '-lag-' num2str(lag) '-' timePeriodHistorical  '.png'], '-m2');
        end
        close all;
    end
end



