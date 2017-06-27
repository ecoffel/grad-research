
% should we look at change between rcp & historical (only for cmip5)
change = true;

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
timePeriodFuture = '2060-2080';

monthlyMeanStr = 'monthlyMean';
if ~monthlyMean
    monthlyMeanStr = 'monthlyMax';
end

load lat;
load lon;

regionInd = 2;
months = 1:12;

baseDir = 'e:/data/bowen';

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
                'Central Africa'};
regionAb = {'world', ...
            'us-cent', ...
            'us-se', ...
            'europe', ...
            'med', ...
            'sa-n', ...
            'amazon', ...
            'africa-cent'};
            
regions = [[[-90 90], [0 360]]; ...             % world
           [[35 46], [-107 -88] + 360]; ...     % central us
           [[30 41], [-95 -75] + 360]; ...      % southeast us
           [[45, 55], [10, 35]]; ...            % Europe
           [[36 45], [-5+360, 40]]; ...        % Med
           [[5 20], [-90 -45]+360]; ...         % Northern SA
           [[-10, 1], [-75, -53]+360]; ...      % Amazon
           [[-10 10], [15, 30]]];                % central africa

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
%         models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
%               'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
%               'hadgem2-cc', 'ipsl-cm5a-mr', 'miroc-esm'};
    case 'us-se'
        models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
              'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'gfdl-cm3', 'hadgem2-cc', ...
              'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
              'mpi-esm-mr'};
%         models = {'access1-0', 'access1-3', 'bnu-esm', ...
%               'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
%               'gfdl-cm3', 'hadgem2-cc', ...
%               'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
%               'mpi-esm-mr'};
    case 'europe'
        models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
              'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'gfdl-cm3', 'hadgem2-cc', ...
              'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
              'mpi-esm-mr'};
%         models = {'access1-0', 'access1-3', 'canesm2', ...
%               'gfdl-cm3', 'hadgem2-cc', ...
%               'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm'};
    case 'med'
        models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
              'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'gfdl-cm3', 'hadgem2-cc', ...
              'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
              'mpi-esm-mr'};
%         models = {'bnu-esm', ...
%               'csiro-mk3-6-0', 'gfdl-cm3', 'hadgem2-cc', ...
%               'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm'};
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
%         models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
%               'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', ...
%               'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
%               'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
%               'mpi-esm-mr', 'mri-cgcm3'};
    case 'india'
        models = {'bnu-esm', 'cnrm-cm5', ...
                  'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', ...
                  'ipsl-cm5a-mr', 'miroc-esm'};
    case 'africa-west'
        models = {'cnrm-cm5', 'csiro-mk3-6-0', ...
                  'gfdl-esm2g', 'gfdl-esm2m'};
    case 'africa-central'
        models = {'access1-0', 'access1-3', 'bnu-esm', ...
                  'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                  'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                  'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
                  'mpi-esm-mr'};
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
    meanLFlux = [];
    meanLFluxStd = [];
    meanSFlux = [];
    meanSFluxStd = [];
    r2LT = [];
    r2ST = [];
    modelLSig = [];
    modelSSig = [];

    if change
        meanTempFuture = [];
        meanLFluxFuture = [];
        meanSFluxFuture = [];
        r2LFutureBT = [];
        r2SFutureBT = [];

        % are the monthly/model changes in bowen statistically significant
        changeLPower = [];
        changeLSig = [];
    end

    for model = 1:length(models)
        ['processing ' models{model} '...']

        if monthlyMean
            load([baseDir '/monthly-flux-temp/monthlyFluxTemp-' datasetStr '-' rcpHistorical '-' models{model} '-' timePeriodHistorical '.mat']);
            fluxTemp = monthlyFluxTemp;
            clear monthlyFluxTemp;
        end

        if change
            ['loading future ' models{model} '...']

            % load historical bowen data for comparison
            if monthlyMean
                load([baseDir '/monthly-flux-temp/monthlyFluxTemp-' datasetStr '-' rcpFuture '-' models{model} '-' timePeriodFuture '.mat']);
                fluxTempFuture = monthlyFluxTemp;
                clear monthlyFluxTemp;
            end
        end

        for month = months

            % look at temps in current month
            tempMonth = month;
            % look at bowens in lagged month
            fluxMonth = month - lag;
            % limit bowen month and roll over (0 -> dec, -1 -> nov, etc)
            if fluxMonth <= 0
                fluxMonth = 12 + fluxMonth;
            end

            ['temp month = ' num2str(tempMonth) ', bowen month = ' num2str(fluxMonth) '...']

            temp = [];
            tempStd = [];
            lFlux = [];
            lFluxStd = [];
            sFlux = [];
            sFluxStd = [];

            if change
                tempFuture = [];
                lFluxFuture = [];
                sFluxFuture = [];
            end

            for xlat = 1:length(curLat)
                for ylon = 1:length(curLon)
                    % get all temp/bowen daily points for current region
                    % into one list (combines gridboxes & years for current model)
                    if monthlyMean

                        % lists of temps for current month for all years
                        curMonthTemps = fluxTemp{1}{tempMonth}{curLat(xlat)}{curLon(ylon)};
                        curMonthSFlux = abs(fluxTemp{2}{fluxMonth}{curLat(xlat)}{curLon(ylon)});
                        curMonthLFlux = abs(fluxTemp{3}{fluxMonth}{curLat(xlat)}{curLon(ylon)});

                        for year = 1:length(curMonthTemps)

                            tempYear = year;
                            fluxYear = year;
                            % if bowen month is *after* temp month, go to
                            % previous year
                            if tempMonth - fluxMonth < 0
                                fluxYear = fluxYear - 1;
                            end

                            % this condition will slightly change the mean
                            % temperature and bowen for lagged plots
                            if fluxYear > 0
                                nextTemp = curMonthTemps(tempYear);
                                nextLFlux = curMonthLFlux(fluxYear);
                                nextSFlux = curMonthSFlux(fluxYear);

                                if ~isnan(nextTemp) && ~isnan(nextLFlux) && ~isnan(nextSFlux)
                                    temp = [temp; nextTemp];
                                    lFlux = [lFlux; nextLFlux];
                                    sFlux = [sFlux; nextSFlux];
                                end
                            end
                        end

                        % get STD for temp/bowen for this gridcell/month
                        nextTempStd = nanstd(curMonthTemps);
                        nextLFluxStd = nanstd(curMonthLFlux);
                        nextSFluxStd = nanstd(curMonthSFlux);

                        % add to error lists
                        tempStd = [tempStd; nextTempStd];
                        lFluxStd = [lFluxStd; nextLFluxStd];
                        sFluxStd = [sFluxStd; nextSFluxStd];

                    end

                    if change
                        % and do the same for future data if we're looking
                        % at a change
                        if monthlyMean
                           
                            % lists of temps for current month for all years
                            curMonthTemps = fluxTempFuture{1}{tempMonth}{curLat(xlat)}{curLon(ylon)};
                            curMonthSFlux = abs(fluxTempFuture{2}{fluxMonth}{curLat(xlat)}{curLon(ylon)});
                            curMonthLFlux = abs(fluxTempFuture{3}{fluxMonth}{curLat(xlat)}{curLon(ylon)});
                            
                            for year = 1:length(curMonthTemps)

                                tempYear = year;
                                fluxYear = year;
                                % if bowen month is *after* temp month, go to
                                % previous year
                                if tempMonth - fluxMonth < 0
                                    fluxYear = fluxYear - 1;
                                end

                                % this condition will slightly change the mean
                                % temperature and bowen for lagged plots
                                if fluxYear > 0
                                    nextTemp = curMonthTemps(tempYear);
                                    nextLFlux = curMonthLFlux(fluxYear);
                                    nextSFlux = curMonthSFlux(fluxYear);

                                    if ~isnan(nextTemp) && ~isnan(nextLFlux) && ~isnan(nextSFlux)
                                        tempFuture = [tempFuture; nextTemp];
                                        lFluxFuture = [lFluxFuture; nextLFlux];
                                        sFluxFuture = [sFluxFuture; nextSFlux];
                                    end
                                end
                            end
                            
                        end
                    end
                end
            end

            % build model for lflux
            modelLBT = fitlm(lFlux, temp, fitType);
            r2LT(model, month) = modelLBT.Rsquared.Ordinary;
            
            % and for sflux
            modelSBT = fitlm(sFlux, temp, fitType);
            r2ST(model, month) = modelSBT.Rsquared.Ordinary;

            % get the model pValue out of the anova structure
            a = anova(modelLBT, 'summary');
            modelLSig(model, month) = a(2, 5).pValue < 0.05;
            
            a = anova(modelSBT, 'summary');
            modelSSig(model, month) = a(2, 5).pValue < 0.05;

            meanTemp(model, month) = nanmean(temp);
            meanLFlux(model, month) = nanmean(lFlux);
            meanSFlux(model, month) = nanmean(sFlux);

            meanTempStd(model, month) = nanmean(tempStd);
            meanLFluxStd(model, month) = nanmean(lFluxStd);
            meanSFluxStd(model, month) = nanmean(sFluxStd);

            % fit model for future data if looking at change
            if change
                modelLFutureBT = fitlm(lFluxFuture, tempFuture, fitType);
                r2LFutureBT(model, month) = modelLFutureBT.Rsquared.Ordinary;
                
                modelSFutureBT = fitlm(sFluxFuture, tempFuture, fitType);
                r2SFutureBT(model, month) = modelSFutureBT.Rsquared.Ordinary;
                
                meanTempFuture(model, month) = nanmean(tempFuture);
                meanLFluxFuture(model, month) = nanmean(lFluxFuture);
                meanSFluxFuture(model, month) = nanmean(sFluxFuture);

                % test for significance of bowen change at 95%
                [h, p, ci, stats] = ttest(lFlux(1:min(length(lFlux), length(lFluxFuture))), lFluxFuture(1:min(length(lFlux), length(lFluxFuture))), 0.05);
                changeLPower(model, month) = p;
                changeLSig(model, month) = h;
                
                [h, p, ci, stats] = ttest(sFlux(1:min(length(sFlux), length(sFluxFuture))), sFluxFuture(1:min(length(sFlux), length(sFluxFuture))), 0.05);
                changeSPower(model, month) = p;
                changeSSig(model, month) = h;

                clear tempFuture lFluxFuture sFluxFuture;
            end

            clear temp lFlux sFlux;
        end
        clear fluxTemp fluxTempFuture;
    end

    fig = figure('Color',[1,1,1]);
    subplot(1,2,1);
    hold on;
    box on;
    
    if change
        % plot multi-model mean change
        [ax,p1,p2] = plotyy(1:12, nanmean(meanTempFuture - meanTemp, 1), 1:12, nanmean(meanLFluxFuture - meanLFlux));
        
        [ax2,p3,p4] = plotyy(1:12, nanmean(meanTempFuture - meanTemp, 1), 1:12, nanmean(meanSFluxFuture - meanSFlux));
        
        hold(ax(1));
        hold(ax(2));
        
        hold(ax2(1));
        hold(ax2(2));
        
        axis(ax(1), 'square');
        axis(ax(2), 'square');
        
        axis(ax2(1), 'square');
        axis(ax2(2), 'square');

        set(p3, 'Color', [239/255.0, 71/255.0, 85/255.0], 'LineWidth', 4);
        set(p2, 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 4);
        set(p4, 'Color', [66/255.0, 170/255.0, 244/255.0], 'LineWidth', 4);

        % plot individual models for temp/bowen change
        for model = 1:length(models)        
            p5 = plot(ax2(1), 1:12, meanTempFuture(model, :) - meanTemp(model, :), 'Color', [239/255.0, 71/255.0, 85/255.0], 'LineWidth', 1);
            p6 = plot(ax2(2), 1:12, meanLFluxFuture(model, :) - meanLFlux(model, :), 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 1);
            p7 = plot(ax2(2), 1:12, meanSFluxFuture(model, :) - meanSFlux(model, :), 'Color', [66/255.0, 170/255.0, 244/255.0], 'LineWidth', 1);
        end

        for month = 1:size(meanLFluxFuture, 2)
            p8 = plot(ax2(2), month, nanmean(meanLFluxFuture(:, month) - meanLFlux(:, month), 1), 'o', 'MarkerSize', 15, 'Color', [25/255.0, 158/255.0, 56/255.0], 'MarkerEdgeColor', 'k');
            if length(find(changeLSig(:, month))) > 0.66*length(models)
                set(p8, 'LineWidth', 3, 'MarkerFaceColor', [25/255.0, 158/255.0, 56/255.0]);
            else
                set(p8, 'LineWidth', 3);
            end
            
            p9 = plot(ax2(2), month, nanmean(meanSFluxFuture(:, month) - meanSFlux(:, month), 1), 'o', 'MarkerSize', 15, 'Color', [66/255.0, 170/255.0, 244/255.0], 'MarkerEdgeColor', 'k');
            if length(find(changeSSig(:, month))) > 0.66*length(models)
                set(p9, 'LineWidth', 3, 'MarkerFaceColor', [66/255.0, 170/255.0, 244/255.0]);
            else
                set(p9, 'LineWidth', 3);
            end
        end
        
        % plot zero line
        plot(ax2(2), 1:12, zeros(12, 1), '--', 'LineWidth', 2, 'Color', [0.2 0.2 0.2]);
    else

        % plot multi-model mean
        [ax,p1,p2] = plotyy(1:12, nanmean(meanTemp, 1), 1:12, nanmean(meanLFlux(:, laggedMonths), 1));
        
        [ax2,p3,p4] = plotyy(1:12, nanmean(meanTemp, 1), 1:12, nanmean(meanSFlux(:, laggedMonths), 1));
        
        hold(ax(1));
        hold(ax(2));
        hold(ax2(1));
        hold(ax2(2));
        
        axis(ax(1), 'square');
        axis(ax(2), 'square');
        
        axis(ax2(1), 'square');
        axis(ax2(2), 'square');

        set(p3, 'Color', [239/255.0, 71/255.0, 85/255.0], 'LineWidth', 4);
        set(p2, 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 4);
        set(p4, 'Color', [66/255.0, 170/255.0, 244/255.0], 'LineWidth', 4);

        % plot individual models for temp/bowen change
        for k = 1:size(meanTemp, 1)
            p5 = plot(ax2(1), 1:12, meanTemp(k, :), 'Color', [239/255.0, 71/255.0, 85/255.0], 'LineWidth', 1);
            p6 = plot(ax2(2), 1:12, meanLFlux(k, laggedMonths), 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 1);
            p7 = plot(ax2(2), 1:12, meanSFlux(k, laggedMonths), 'Color', [66/255.0, 170/255.0, 244/255.0], 'LineWidth', 1);
        end

        % plot zero lines
        plot(ax2(1), 1:12, zeros(12, 1), '--', 'LineWidth', 2, 'Color', [239/255.0, 71/255.0, 85/255.0]);
        plot(ax2(2), 1:12, zeros(12, 1), '--', 'LineWidth', 2, 'Color', [25/255.0, 158/255.0, 56/255.0]);

        %tempCV = nanmean(meanTempStd, 1) ./ nanmean(meanTemp, 1);
        lFluxCV = nanmean(meanLFluxStd, 1) ./ nanmean(meanLFlux, 1);
        sFluxCV = nanmean(meanSFluxStd, 1) ./ nanmean(meanSFlux, 1);

        % plot the temperature STD
        er1 = errorbar(ax2(1), 1:12, nanmean(meanTemp, 1), nanmean(meanTempStd, 1) ./ 2);
        set(er1, 'LineWidth', 2, 'Color', [239/255.0, 71/255.0, 85/255.0]);

        % and the bowen coefficient of variability (STD / mean)
        er2 = errorbar(ax2(2), 1:12, nanmean(meanLFlux(:, laggedMonths), 1), lFluxCV(laggedMonths) ./ 2);
        set(er2, 'LineWidth', 2, 'Color', [25/255.0, 158/255.0, 56/255.0]);
        
        er3 = errorbar(ax2(2), 1:12, nanmean(meanSFlux(:, laggedMonths), 1), sFluxCV(laggedMonths) ./ 2);
        set(er3, 'LineWidth', 2, 'Color', [66/255.0, 170/255.0, 244/255.0]);

    end

    set(ax(1), 'YColor', 'k');
    set(ax(2), 'YColor', 'k');
    set(ax2(1), 'YColor', 'k');
    set(ax2(2), 'YColor', 'k');
    
    set(ax(1), 'XLim', [0.5 12.5], 'XTick', 1:12);
    set(ax(2), 'XLim', [0.5 12.5], 'XTick', []);
    set(ax2(1), 'XLim', [0.5 12.5], 'XTick', 1:12);
    set(ax2(2), 'XLim', [0.5 12.5], 'XTick', []);
    if change
        set(ax(1), 'YLim', [-1 8], 'YTick', -1:8);
        set(ax(2), 'YLim', [-40 40], 'YTick', -40:10:40);
        set(ax2(1), 'YLim', [-1 8], 'YTick', -1:8);
        set(ax2(2), 'YLim', [-40 40], 'YTick', -40:10:40);
    else
        set(ax(1), 'YLim', [-10 40], 'YTick', [-10 0 10 20 30 40]);
        set(ax(2), 'YLim', [-5 200], 'YTick', [0 50 100 150 200]);
        set(ax2(1), 'YLim', [-10 40], 'YTick', [-10 0 10 20 30 40]);
        set(ax2(2), 'YLim', [-5 200], 'YTick', [0 50 100 150 200]);
    end
    set(ax(1), 'FontSize', 24);
    set(ax(2), 'FontSize', 24);
    set(ax2(1), 'FontSize', 24);
    set(ax2(2), 'FontSize', 24);
    
    xlabel('Month', 'FontSize', 24);
    if change
        ylabel(ax2(1), 'Temperature change', 'FontSize', 24);
        ylabel(ax2(2), 'Flux change', 'FontSize', 24);
    else
        ylabel(ax2(1), 'Temperature', 'FontSize', 24);
        ylabel(ax2(2), 'Flux', 'FontSize', 24);
    end
    
    leg = legend([p3 p2 p4], {'Temperature', 'Latent heat flux', 'Sensible heat flux'});
    set(leg, 'location', 'northwest', 'FontSize', 20);

    % right hand plot -------------------
    subplot(1,2,2);
    hold on;
    axis square;
    grid on;
    box on;
    if change
        %plot(1:12, r2FutureTB - r2TB, 'Color', [0.4 0.4 0.4]);
        %plot(1:12, nanmean(r2FutureTB - r2TB, 1), 'Color', [0.4 0.4 0.4], 'LineWidth', 3);
        for k = 1:size(r2LT, 1)
            plot(1:12, r2LFutureBT(k, :) - r2LT(k, :), 'Color', [25/255.0, 158/255.0, 56/255.0]);
        end
        plot(1:12, nanmean(r2LFutureBT - r2LT, 1), 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 4);
        ylim([-0.5 0.5]);
        
        for k = 1:size(r2ST, 1)
            plot(1:12, r2SFutureBT(k, :) - r2ST(k, :), 'Color', [66/255.0, 170/255.0, 244/255.0]);
        end
        plot(1:12, nanmean(r2SFutureBT - r2ST, 1), 'Color', [66/255.0, 170/255.0, 244/255.0], 'LineWidth', 4);
        ylim([-0.5 0.5]);
    else
        %plot(1:12, r2TB, 'Color', [0.4 0.4 0.4]);
        %plot(1:12, nanmean(r2TB, 1), 'Color', [0.4 0.4 0.4], 'LineWidth', 3);
        for k = 1:size(r2LT, 1)
            plot(1:12, r2LT(k, :), 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 1);
        end
        plot(1:12, nanmean(r2LT, 1), 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 4);
        ylim([0 1]);
        
        for k = 1:size(r2ST, 1)
            plot(1:12, r2ST(k, :), 'Color', [66/255.0, 170/255.0, 244/255.0], 'LineWidth', 1);
        end
        plot(1:12, nanmean(r2ST, 1), 'Color', [66/255.0, 170/255.0, 244/255.0], 'LineWidth', 4);
        ylim([0 1]);

        for month = 1:size(r2LT, 2)
            p5 = plot(month, nanmean(r2LT(:, month), 1), 'o', 'MarkerSize', 15, 'Color', [0.5 0.5 0.5], 'MarkerEdgeColor', 'k');
            if length(find(modelLSig(:, month))) > 0.66*length(models)
                set(p5, 'LineWidth', 3, 'MarkerFaceColor', [0.5 0.5 0.5]);
            else
                set(p5, 'LineWidth', 3);
            end
            
            p6 = plot(month, nanmean(r2ST(:, month), 1), 'o', 'MarkerSize', 15, 'Color', [0.5 0.5 0.5], 'MarkerEdgeColor', 'k');
            if length(find(modelSSig(:, month))) > 0.66*length(models)
                set(p6, 'LineWidth', 3, 'MarkerFaceColor', [0.5 0.5 0.5]);
            else
                set(p6, 'LineWidth', 3);
            end
        end
    end
    
    % plot zero line
    plot(1:12, zeros(12, 1), '--', 'LineWidth', 2, 'Color', [0.2 0.2 0.2]);
    
    xlim([0.5 12.5]);
    set(gca, 'FontSize', 24);
    xlabel('Month', 'FontSize', 24);
    if change
        ylabel('R2 change', 'FontSize', 24);
    else
        ylabel('R2', 'FontSize', 24);
    end

    set(gcf, 'Position', get(0,'Screensize'));
    export_fig(['fluxR2Fit-' regionAb{regionInd} '-' dataset '-' rcpStr '-BT-' monthlyMeanStr '-lag-' num2str(lag)  '.png'], '-m2');
    close all;

end



