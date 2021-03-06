makeCounts = false;
plotModels = false;
plotMaps = false;

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

load lat;
load lon;
[regionInds, regions, regionNames] = ni_getRegions();

regionBounds = [[2 32]; [25, 44]];
[latInds, lonInds] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));

regionBoundsSouth = [[2 13]; [25, 42]];
regionBoundsNorth = [[13 32]; [29, 34]];

[latIndsNorth, lonIndsNorth] = latLonIndexRange({lat,lon,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
[latIndsSouth, lonIndsSouth] = latLonIndexRange({lat,lon,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));
latIndsNorth = latIndsNorth - latInds(1) + 1;
lonIndsNorth = lonIndsNorth - lonInds(1) + 1;
latIndsSouth = latIndsSouth - latInds(1) + 1;
lonIndsSouth = lonIndsSouth - lonInds(1) + 1;

region = 'nile';

if plotModels
    modelLeg = {};
    figure('Color', [1,1,1]);
    hold on;
    axis off;
    for m = 1:length(models)
        plot(0, 0, 'k');
        modelLeg{m} = [num2str(m) ' ' models{m}];
    end
    set(gca, 'FontSize', 20);
    legend(modelLeg)
    export_fig model-list.eps;
end

curInds = regionInds(region);

mrsoMeanChg = [];
mrsoHotChg = [];
mrsoMeanChgPer = [];

for m = 1:length(models)
    
    fprintf('loading %s mrso...\n', models{m});
    mrsoHist = loadMonthlyData(['e:/data/cmip5/output/' models{m} '/mon/r1i1p1/historical/mrso/regrid/world'], 'mrso', 'startYear', 1980, 'endYear', 2004);
    mrsoHist = mrsoHist{3}(curInds{1}, curInds{2}, :, :);
    mrsoHistMean = nanmean(nanmean(mrsoHist, 4), 3);
    mrsoHist = mrsoHist - mrsoHistMean;
    mrsoHist = mrsoHist ./ mrsoHistMean;

    fprintf('loading %s tasmax...\n', models{m});
    tasmaxHist = loadDailyData(['e:/data/cmip5/output/' models{m} '/r1i1p1/historical/tasmax/regrid/world'], 'startYear', 1980, 'endYear', 2004);
    if nanmean(nanmean(nanmean(nanmean(nanmean(tasmaxHist{3}))))) > 100
        tasmaxHist{3} = tasmaxHist{3} - 273.15;
    end
    tasmaxHist = tasmaxHist{3}(curInds{1}, curInds{2}, :, :, :);
    tasmaxHistMean = nanmean(nanmean(nanmean(tasmaxHist, 5), 4), 3);
    tasmaxHist = squeeze(nanmax(tasmaxHist, [], 5));
    tasmaxHist = tasmaxHist - tasmaxHistMean;

    for xlat = 1:size(tasmaxHist, 1)
        for ylon = 1:size(tasmaxHist, 2)
            for year = 1:size(tasmaxHist, 3)
                curTasmax = squeeze(tasmaxHist(xlat, ylon, year, :));
                if length(find(isnan(curTasmax))) > 0 || length(find(curTasmax == nanmedian(curTasmax))) > 1
                    heatTmaxHist(xlat, ylon, year) = NaN;
                    heatMrsoHist(xlat, ylon, year) = NaN;
                else
                    curTasmaxMonth = find(curTasmax == max(curTasmax));
                    heatTmaxHist(xlat, ylon, year) = curTasmax(curTasmaxMonth(1));
                    heatMrsoHist(xlat, ylon, year) = mrsoHist(xlat, ylon, year, curTasmaxMonth(1));
                end

                curMrso = squeeze(mrsoHist(xlat, ylon, year, :));
                if length(find(isnan(curMrso))) > 0 || length(find(curMrso == nanmedian(curMrso))) > 1
                    dryTmaxHist(xlat, ylon, year) = NaN;
                    dryMrsoHist(xlat, ylon, year) = NaN;
                else
                    curMinMrsoMonth = find(curMrso == min(curMrso));
                    dryTmaxHist(xlat, ylon, year) = tasmaxHist(xlat, ylon, year, curMinMrsoMonth(1));
                    dryMrsoHist(xlat, ylon, year) = curMrso(curMinMrsoMonth(1));
                end
            end
        end
    end

    fprintf('loading %s mrso future...\n', models{m});
    mrsoFut = loadMonthlyData(['e:/data/cmip5/output/' models{m} '/mon/r1i1p1/rcp85/mrso/regrid/world'], 'mrso', 'startYear', 2056, 'endYear', 2080);
    mrsoFut = mrsoFut{3}(curInds{1}, curInds{2}, :, :);
    mrsoFut = mrsoFut - mrsoHistMean;
    mrsoFut = mrsoFut ./ mrsoHistMean;

    fprintf('loading %s tasmax future...\n', models{m});
    tasmaxFut = loadDailyData(['e:/data/cmip5/output/' models{m} '/r1i1p1/rcp85/tasmax/regrid/world'], 'startYear', 2056, 'endYear', 2080);
    if nanmean(nanmean(nanmean(nanmean(nanmean(tasmaxFut{3}))))) > 100
        tasmaxFut{3} = tasmaxFut{3} - 273.15;
    end
    tasmaxFut = tasmaxFut{3}(curInds{1}, curInds{2}, :, :, :);
    tasmaxFut = squeeze(nanmax(tasmaxFut, [], 5));
    tasmaxFut = tasmaxFut - tasmaxHistMean;

    for xlat = 1:size(tasmaxFut, 1)
        for ylon = 1:size(tasmaxFut, 2)
            for year = 1:size(tasmaxFut, 3)
                curTasmax = squeeze(tasmaxFut(xlat, ylon, year, :));
                if length(find(isnan(curTasmax))) > 0 || length(find(curTasmax == nanmedian(curTasmax))) > 1
                    heatTmaxFut(xlat, ylon, year) = NaN;
                    heatMrsoFut(xlat, ylon, year) = NaN;
                else
                    curTasmaxMonth = find(curTasmax == max(curTasmax));
                    heatTmaxFut(xlat, ylon, year) = curTasmax(curTasmaxMonth(1));
                    heatMrsoFut(xlat, ylon, year) = mrsoFut(xlat, ylon, year, curTasmaxMonth(1));
                end


                curMrso = squeeze(mrsoFut(xlat, ylon, year, :));
                if length(find(isnan(curMrso))) > 0 || length(find(curMrso == nanmedian(curMrso))) > 1
                    dryTmaxFut(xlat, ylon, year) = NaN;
                    dryMrsoFut(xlat, ylon, year) = NaN;
                else
                    curMinMrsoMonth = find(curMrso == min(curMrso));
                    dryTmaxFut(xlat, ylon, year) = tasmaxFut(xlat, ylon, year, curMinMrsoMonth(1));
                    dryMrsoFut(xlat, ylon, year) = curMrso(curMinMrsoMonth(1));
                end
            end
        end
    end

    mrsoHotChg(:,:,m) = nanmean(heatMrsoFut,3) - nanmean(heatMrsoHist,3);
    mrsoMeanChg(:,:,m) = nanmean(nanmean(mrsoFut,4),3) - nanmean(nanmean(mrsoHist,4),3);
    mrsoDryChg(:,:,m) = nanmean(dryMrsoFut,3) - nanmean(dryMrsoHist,3);

end

mrsoHotChg = mrsoHotChg .* 100;
mrsoMeanChg = mrsoMeanChg .* 100;
mrsoDryChg = mrsoDryChg .* 100;


figure('Color', [1,1,1]);
hold on;
box on;
grid on;
axis square;

b = boxplot([squeeze(nanmean(nanmean(mrsoDryChg(latIndsNorth, lonIndsNorth, :),2),1)) ...
             squeeze(nanmean(nanmean(mrsoHotChg(latIndsNorth, lonIndsNorth, :),2),1)) ...
             squeeze(nanmean(nanmean(mrsoMeanChg(latIndsNorth, lonIndsNorth, :),2),1))], 'positions', [1 2 3]);

set(b(:, 1), {'LineWidth', 'Color'}, {2, [147 66 0]./255.0})
lines = findobj(b(:, 1), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2); 

set(b(:, 2), {'LineWidth', 'Color'}, {2, [247, 92, 81]./255.0})
lines = findobj(b(:, 2), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2); 

set(b(:, 3), {'LineWidth', 'Color'}, {2, [239, 168, 55]./255.0})
lines = findobj(b(:, 3), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2); 

plot([0 10], [0 0], '--k');
set(gca, 'XTick', [1,2,3], 'XTickLabels', {'Driest month', 'Hottest month', 'Annual mean'});
ylim([-13 13]);
xlim([.5 3.5]);
ylabel('Soil moisture change (%)');
set(gca, 'YTick', -15:5:15);
set(gca, 'FontSize', 40);
xtickangle(45);
set(gcf, 'Position', get(0,'Screensize'));
export_fig(['soil-moisture-change-north.eps']);
close all;

if plotMaps
    result = {lat(curInds{1},curInds{2}), lon(curInds{1},curInds{2}), nanmedian(mrsoMeanChg,3)};
    saveData = struct('data', {result}, ...
                      'plotRegion', 'nile', ...
                      'plotRange', [-5 5], ...
                      'cbXTicks', -5:2:5, ...
                      'plotTitle', [''], ...
                      'fileTitle', ['mrso-mean-chg-rcp85.eps'], ...
                      'plotXUnits', ['%'], ...
                      'blockWater', true, ...
                      'colormap', brewermap([], 'BrBG'), ...
                      'plotCountries', true, ...
                      'boxCoords', {[[13 32], [29, 34];
                                     [2 13], [25 42]]});
    plotFromDataFile(saveData);
    
    result = {lat(curInds{1},curInds{2}), lon(curInds{1},curInds{2}), nanmedian(mrsoHotChg,3)};
    saveData = struct('data', {result}, ...
                      'plotRegion', 'nile', ...
                      'plotRange', [-5 5], ...
                      'cbXTicks', -5:2:5, ...
                      'plotTitle', [''], ...
                      'fileTitle', ['mrso-hot-chg-rcp85.eps'], ...
                      'plotXUnits', ['%'], ...
                      'blockWater', true, ...
                      'colormap', brewermap([], 'BrBG'), ...
                      'plotCountries', true, ...
                      'boxCoords', {[[13 32], [29, 34];
                                     [2 13], [25 42]]});
    plotFromDataFile(saveData);
    
    result = {lat(curInds{1},curInds{2}), lon(curInds{1},curInds{2}), nanmedian(mrsoDryChg,3)};
    saveData = struct('data', {result}, ...
                      'plotRegion', 'nile', ...
                      'plotRange', [-5 5], ...
                      'cbXTicks', -5:2:5, ...
                      'plotTitle', [''], ...
                      'fileTitle', ['mrso-dry-chg-rcp85.eps'], ...
                      'plotXUnits', ['%'], ...
                      'blockWater', true, ...
                      'colormap', brewermap([], 'BrBG'), ...
                      'plotCountries', true, ...
                      'boxCoords', {[[13 32], [29, 34];
                                     [2 13], [25 42]]});
    plotFromDataFile(saveData);
end









