dataset = 'cmip5';

coordPairs = csvread('ni-region.txt');

switch (dataset)
    case 'cmip5'
        models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
        timePeriod = [2051 2080];
        rcp = 'rcp85';
        
    case 'era-interim'
        timePeriod = [1980 2016];
        fprintf('loading ERA temps...\n');
        tmaxHistorical = loadDailyData('e:/data/era-interim/output/mx2t/regrid/world', 'startYear', timePeriod(1), 'endYear', timePeriod(end));
        tmaxHistorical{3} = tmaxHistorical{3}(min(coordPairs(:,1)):max(coordPairs(:,1)), min(coordPairs(:,2)):max(coordPairs(:,2)), :, :, :) - 273.15;
        models = {''};
        
    case 'ncep-reanalysis'
        timePeriod = [1980 2016];
        fprintf('loading NCEP temps...\n');
        tmaxHistorical = loadDailyData('e:/data/ncep-reanalysis/output/tmax/regrid/world', 'startYear', timePeriod(1), 'endYear', timePeriod(end));
        tmaxHistorical{3} = tmaxHistorical{3}(min(coordPairs(:,1)):max(coordPairs(:,1)), min(coordPairs(:,2)):max(coordPairs(:,2)), :, :, :) - 273.15;
        models = {''};
end

numYears = (timePeriod(end)-timePeriod(1)+1);

load lat;
load lon;

regionBounds = [[2 32]; [25, 44]];
[latInds, lonInds] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));

% regionBoundsNorth = [[13 32]; [29, 34]];
% [latIndsNorth, lonIndsNorth] = latLonIndexRange({lat,lon,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
% 
% regionBoundsSouth = [[2 13]; [25, 42]];
% [latIndsSouth, lonIndsSouth] = latLonIndexRange({lat,lon,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));

lat = lat(latInds, lonInds);
lon = lon(latInds, lonInds);

drawMaps = false;
drawLines = false;

% temperature: 
threshPrc = 90;
% duration (days)
threshDur = 5;
% look for heat waves relative to each month's climatology or the whole
% year?
monthlyHeat = false;

for model = 1:length(models)
        
    % heat wave maps at each percentile...
    heatWaves = {};
    
    % if needed, load current cmip5 model
    if strcmp(dataset, 'cmip5')
        fprintf('loading historical %s\n', models{model});
        tmaxHistorical = loadDailyData(['e:/data/cmip5/output/' models{model} '/r1i1p1/historical/tasmax/regrid/world'], 'startYear', 1980, 'endYear', 2004);
        tmaxHistorical = tmaxHistorical{3};
        if nanmean(nanmean(nanmean(nanmean(nanmean(tmaxHistorical))))) > 100
            tmaxHistorical = tmaxHistorical - 273.15;
        end
        tmaxHistorical = tmaxHistorical(latInds, lonInds, :, :, :);
        
        fprintf('loading future %s\n', models{model});
        tmaxFuture = loadDailyData(['e:/data/cmip5/output/' models{model} '/r1i1p1/' rcp '/tasmax/regrid/world'], 'startYear', timePeriod(1), 'endYear', timePeriod(end));
        tmaxFuture = tmaxFuture{3};
        if nanmean(nanmean(nanmean(nanmean(nanmean(tmaxFuture))))) > 100
            tmaxFuture = tmaxFuture - 273.15;
        end
        tmaxFuture = tmaxFuture(latInds, lonInds, :, :, :);
        
        heatWaves = findHeatWaves(tmaxHistorical, tmaxFuture, threshPrc, threshDur, monthlyHeat);
    else
        heatWaves = findHeatWaves(tmaxHistorical, threshPrc, threshDur, monthlyHeat);
    end
    
%     for xlat = 1:length(latInds)
%         for ylon = 1:length(lonInds)
%             if length(find(coordPairs(:,1) == latInds(xlat) & coordPairs(:,2) == lonInds(ylon))) == 0
%                 heatWaves(xlat, ylon, :, :) = NaN;
%             end
%         end
%     end

    if drawLines
        % number of heat waves per year averaged across all regional grid cells
        figure('Color',[1,1,1]);
        hold on;
        axis square;
        grid on;
        box on;

        p1=plot(timePeriod(1):timePeriod(end), squeeze(nansum(nansum(nansum(heatWaves,4),2),1)), '-', 'Color', [81, 165, 239]./255.0, 'LineWidth', 2);
        p2=plot(timePeriod(1):timePeriod(end), squeeze(nansum(nansum(nansum(heatProbEra,4),2),1)), '-', 'Color', [242, 146, 77]./255.0, 'LineWidth', 2);

        f1 = fit((timePeriod(1):timePeriod(end))', squeeze(nansum(nansum(nansum(heatWaves,4),2),1)), 'poly1');
        f2 = fit((timePeriod(1):timePeriod(end))', squeeze(nansum(nansum(nansum(heatProbEra,4),2),1)), 'poly1');

        if Mann_Kendall(squeeze(nansum(nansum(nansum(heatWaves,4),2),1)),0.05)
            plot((timePeriod(1):timePeriod(end))', f1((timePeriod(1):timePeriod(end))'), '--', 'Color', [81, 165, 239]./255.0);
        end

        if Mann_Kendall(squeeze(nansum(nansum(nansum(heatProbEra,4),2),1)),0.05)
            plot((timePeriod(1):timePeriod(end))', f2((timePeriod(1):timePeriod(end))'), '--', 'Color', [242, 146, 77]./255.0);
        end

        legend([p1,p2],{'NCEP', 'Era'},'location','northwest');
        title(['5-day temperatures above local ' num2str(t) 'th percentile']);
        ylabel('Number of events');
        xlabel('Year');
        set(gca, 'FontSize',24);
        set(gcf, 'Position', get(0,'Screensize'));
        export_fig(['nile-annual-heat-waves-historical-' num2str(t) '.eps']);
        close all;
    end


    if strcmp(dataset, 'cmip5')
        if monthlyHeat
            save(['2017-nile-climate/nile-heat-waves-90-5day-' rcp '-' models{model} '-monthly-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '.mat'], 'heatWaves');
        else
            save(['2017-nile-climate/nile-heat-waves-90-5day-' rcp '-' models{model} '-annual-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '.mat'], 'heatWaves');
        end
    else
        save(['2017-nile-climate/nile-heat-waves-90-5day-' dataset '-annual.mat'], 'heatProb');
    end
    clear tmaxHistorical tmaxFuture heatWaves;
end


if drawMaps
    
    resultNcep = {lat, lon, sum(sum(heatWaves, 4), 3)};

    saveData = struct('data', {resultNcep}, ...
                      'plotRegion', 'nile', ...
                      'plotRange', [0 100], ...
                      'cbXTicks', 0:25:100, ...
                      'plotTitle', ['Total heat waves (1980-2016)'], ...
                      'fileTitle', ['nile-heat-waves-historical-ncep.png'], ...
                      'plotXUnits', ['Number'], ...
                      'blockWater', true, ...
                      'colormap', cmocean('thermal'), ...
                      'plotCountries', true, ...
                      'vector', true, ...
                      'boxCoords', {[[13 32], [29, 34];
                                     [2 13], [25 42]]});
    plotFromDataFile(saveData);

    resultNcep = {lat, lon, sum(sum(heatProbEra, 4), 3)};
    saveData = struct('data', {resultNcep}, ...
                      'plotRegion', 'nile', ...
                      'plotRange', [0 100], ...
                      'cbXTicks', 0:25:100, ...
                      'plotTitle', ['Total heat waves (1980-2016)'], ...
                      'fileTitle', ['nile-heat-waves-historical-era.png'], ...
                      'plotXUnits', ['Number'], ...
                      'blockWater', true, ...
                      'colormap', cmocean('thermal'), ...
                      'plotCountries', true, ...
                      'vector', true, ...
                      'boxCoords', {[[13 32], [29, 34];
                                     [2 13], [25 42]]});
    plotFromDataFile(saveData);
end


function heatWaves = findHeatWaves(dataBase, data, percentile, duration, monthly)
    heatWaves = []; 
    
    % for all months, calculate the chance of there being a heatwave matching
    % defined characteristics...
    
    % loop over all gridcells
    for xlat = 1:size(data, 1)
        for ylon = 1:size(data, 2)
            
            % calculate threshold relative to whole gridcell climatology
            if ~monthly
                threshTemp = prctile(reshape(dataBase(xlat,ylon,:,:,:), [numel(dataBase(xlat,ylon,:,:,:)),1]), percentile);
            end
            
            for month = 1:12
                % threshold relative to climatology for this month
                if monthly
                    threshTemp = prctile(reshape(dataBase(xlat,ylon,:,month,:), [numel(dataBase(xlat,ylon,:,month,:)),1]), percentile);
                end

                for year = 1:size(data, 3)
                    % convert to 1D for current gridcell
                    % if there is no future data provided, look at
                    % historical data
                    if length(data) == 0
                        d = reshape(permute(squeeze(dataBase(xlat, ylon, year, month, :)), [3,2,1]), [numel(dataBase(xlat, ylon, year, month, :)), 1]);
                    else
                        d = reshape(permute(squeeze(data(xlat, ylon, year, month, :)), [3,2,1]), [numel(data(xlat, ylon, year, month, :)), 1]);
                    end

                    % find all days above threshold temperature
                    indTemp = find(d > threshTemp);

                    % for how ever many days long wave we're looking for, take
                    % difference of temp threshold indices - so if 1, that means
                    % consequitive hot days
                    % look for sub-arrays that contain X number of sequential ones
                    x = (diff(indTemp))'==1;
                    f = find([false, x] ~= [x, false]);
                    indDur = length(find(f(2:2:end)-f(1:2:end-1) >= duration));

                    % average number of events per year
                    heatWaves(xlat, ylon, year, month) = indDur;
                end 
            end
        end
    end
end