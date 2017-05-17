% leave out 'bcc-csm1-1-m' and 'inmcm4' due to bad bowen performance
models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
                  'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                  'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                  'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
                  'mpi-esm-mr', 'mri-cgcm3'};

% models={'ncep-reanalysis'};

% should we look at change between rcp & historical (only for cmip5)
change = true;

% look at monthly mean temp/bowen fit or daily
monthlyMean = true;

% plot curves for each model separately
plotEachModel = false;

% type of model to fit to data
fitType = 'poly2';

rcpHistorical = 'historical';
rcpFuture = 'rcp85';

timePeriodHistorical = '1985-2004';
timePeriodFuture = '2060-2080';

dataset = 'cmip5';
if length(models) == 1 && strcmp(models{1}, 'ncep-reanalysis')
    dataset = 'ncep';
end

monthlyMeanStr = 'monthlyMean';
if ~monthlyMean
    monthlyMeanStr = 'daily';
end

load lat;
load lon;

regionInd = 2;
months = 1:12;

regionNames = {'World', ...
                'Eastern U.S.', ...
                'Western Europe', ...
                'Amazon', ...
                'India', ...
                'China', ...
                'Central Africa', ...
                'Tropics'};
regionAb = {'world', ...
            'us', ...
            'europe', ...
            'amazon', ...
            'india', ...
            'china', ...
            'africa', ...
            'tropics'};
            
regions = [[[-90 90], [0 360]]; ...             % world
           [[30 48], [-97 -62] + 360]; ...      % USNE
           [[35, 60], [-10+360, 20]]; ...       % Europe
           [[-10, 10], [-70, -40]+360]; ...     % Amazon
           [[8, 28], [67, 90]]; ...             % India
           [[20, 40], [100, 125]]; ...          % China
           [[-10 10], [15, 30]]; ...            % central Africa
           [[-20 20], [0 360]]];                % Tropics
           
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
    % temp/bowen pairs for this region, by months
    linModels = {};
    meanTemp = [];
    meanBowen = [];
    r2 = [];
    
    if change
        linModelsFuture = {};
        meanTempFuture = [];
        meanBowenFuture = [];
        r2Future = [];
    end

    for model = 1:length(models)
        ['processing ' models{model} '...']
        
        load(['f:\data\daily-bowen-temp\dailyBowenTemp-' rcpHistorical '-' models{model} '-' timePeriodHistorical '.mat']);
        bowenTemp=dailyBowenTemp;
        clear dailyBowenTemp;

        if change
            ['loading future ' models{model} '...']
            
            % load historical bowen data for comparison
            load(['f:\data\daily-bowen-temp\dailyBowenTemp-' rcpFuture '-' models{model} '-' timePeriodFuture '.mat']);
            bowenTempFuture=dailyBowenTemp;
            clear dailyBowenTemp;
        end
        
        linModels{model} = {};
        if change
            linModelsFuture{model} = {};
        end
        
        for month = months
            ['month = ' num2str(month) '...']
            temp = [];
            bowen = [];
            
            if change
                tempFuture = [];
                bowenFuture = [];
            end
            
            for xlat = 1:length(curLat)
                for ylon = 1:length(curLon)
                    % get all temp/bowen daily points for current region
                    % into one list (combines gridboxes & years for current model)
                    if monthlyMean
                        temp = [temp; nanmean(bowenTemp{1}{month}{curLat(xlat)}{curLon(ylon)}')];
                        bowen = [bowen; nanmean(abs(bowenTemp{2}{month}{curLat(xlat)}{curLon(ylon)}'))];
                    else
                        temp = [temp; bowenTemp{1}{month}{curLat(xlat)}{curLon(ylon)}'];
                        bowen = [bowen; abs(bowenTemp{2}{month}{curLat(xlat)}{curLon(ylon)}')];
                    end
                    
                    if change
                        % and do the same for future data if we're looking
                        % at a change
                        if monthlyMean
                            tempFuture = [tempFuture; nanmean(bowenTempFuture{1}{month}{curLat(xlat)}{curLon(ylon)}')];
                            bowenFuture = [bowenFuture; nanmean(abs(bowenTempFuture{2}{month}{curLat(xlat)}{curLon(ylon)}'))];
                        else
                            tempFuture = [tempFuture; bowenTempFuture{1}{month}{curLat(xlat)}{curLon(ylon)}'];
                            bowenFuture = [bowenFuture; abs(bowenTempFuture{2}{month}{curLat(xlat)}{curLon(ylon)}')];
                        end

                    end
                end
            end
            
            linModels{model}{month} = fitlm(temp, bowen, fitType);
            r2(model, month) = linModels{model}{month}.Rsquared.Ordinary;
            meanTemp(model, month) = nanmean(temp);
            meanBowen(model, month) = nanmean(bowen);
            
            % fit model for future data if looking at change
            if change
                linModelsFuture{model}{month} = fitlm(tempFuture, bowenFuture, fitType);
                r2Future(model, month) = linModelsFuture{model}{month}.Rsquared.Ordinary;
                meanTempFuture(model, month) = nanmean(tempFuture);
                meanBowenFuture(model, month) = nanmean(bowenFuture);
                
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
                plot(1:12, r2Future(model,:) - r2(model,:), 'Color', [0.4 0.4 0.4]);
                ylim([-0.5 0.5]);
            else
                plot(1:12, r2(model,:), 'Color', [0.4 0.4 0.4]);
                plot(1:12, nanmean(r2(model,:), 1), 'Color', [0.4 0.4 0.4], 'LineWidth', 3);
                ylim([0 1]);
            end
            xlabel('month');
            ylabel('r2');
            export_fig(['r2-' regionAb{regionInd} '-' dataset '-historical-' monthlyMeanStr '-' models{model} '.png'], '-m2');
            close all;
        end
    else
        figure('Color',[1,1,1]);
        subplot(1,2,1);
        hold on;
        axis square;
        grid on;
        box on;
        if change
            [ax,p1,p2] = plotyy(1:12, meanTempFuture - meanTemp, 1:12, meanBowenFuture - meanBowen);
        else
            [ax,p1,p2] = plotyy(1:12, meanTemp, 1:12, meanBowen);
            [ax2,p3,p4] = plotyy(1:12, nanmean(meanTemp, 1), 1:12, nanmean(meanBowen, 1));
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
            plot(1:12, r2Future - r2, 'Color', [0.4 0.4 0.4]);
            ylim([-0.5 0.5]);
        else
            plot(1:12, r2, 'Color', [0.4 0.4 0.4]);
            plot(1:12, nanmean(r2, 1), 'Color', [0.4 0.4 0.4], 'LineWidth', 3);
            ylim([0 1]);
        end
        xlabel('month');
        ylabel('r2');
    end
    
else
    
    r2 = [];
    rmse = [];
    
    for model = 1:length(models)
        ['processing ' models{model} '...']
        load(['f:\data\daily-bowen-temp\dailyBowenTemp-historical-' models{model} '-1985-2004.mat']);
        bowenTemp=dailyBowenTemp;
        clear dailyBowenTemp;
        for month = months
            
            for xlat = 1:length(curLat)
                for ylon = 1:length(curLon)

                    ind = find(~isnan(bowenTemp{1}{month}{curLat(xlat)}{curLon(ylon)}));
                    if length(ind) > 100
                        lm = fitlm(bowenTemp{1}{month}{curLat(xlat)}{curLon(ylon)}(ind)', bowenTemp{2}{month}{curLat(xlat)}{curLon(ylon)}(ind)', fitType);
                        r2(xlat, ylon, model, month) = lm.Rsquared.Ordinary;
                        rmse(xlat, ylon, model, month) = lm.RMSE;
                    else
                        r2(xlat, ylon, model, month) = NaN;
                        rmse(xlat, ylon, model, month) = NaN;
                    end
                end
            end

            
        end
    end
    
    for month = months
        result = {lat(curLat,curLon), lon(curLat,curLon), squeeze(nanmean(r2(:,:,:,month), 3))};
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




