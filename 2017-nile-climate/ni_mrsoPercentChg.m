makeCounts = false;
plotModels = false;

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

curInds = regionInds(region);

north = false;

if ~exist('mrsoChg', 'var')
mrsoChg = [];
prChg = [];

for m = 1:length(models)
    
    fprintf('loading %s mrso...\n', models{m});
    mrsoHist = loadMonthlyData(['e:/data/cmip5/output/' models{m} '/mon/r1i1p1/historical/mrso/regrid/world'], 'mrso', 'startYear', 1981, 'endYear', 2005);
    mrsoHist = nanmean(nanmean(mrsoHist{3}(curInds{1}, curInds{2}, :, :), 4), 3);

    fprintf('loading %s mrso future...\n', models{m});
    mrsoFut = loadMonthlyData(['e:/data/cmip5/output/' models{m} '/mon/r1i1p1/rcp85/mrso/regrid/world'], 'mrso', 'startYear', 2056, 'endYear', 2080);
    mrsoFut = nanmean(nanmean(mrsoFut{3}(curInds{1}, curInds{2}, :, :), 4), 3);
    
    fprintf('loading %s pr...\n', models{m});
    prHist = loadMonthlyData(['e:/data/cmip5/output/' models{m} '/mon/r1i1p1/historical/pr/regrid/world'], 'pr', 'startYear', 1981, 'endYear', 2005);
    prHist = nanmean(nanmean(prHist{3}(curInds{1}, curInds{2}, :, :), 4), 3);

    fprintf('loading %s pr future...\n', models{m});
    prFut = loadMonthlyData(['e:/data/cmip5/output/' models{m} '/mon/r1i1p1/rcp85/pr/regrid/world'], 'pr', 'startYear', 2056, 'endYear', 2080);
    prFut = nanmean(nanmean(prFut{3}(curInds{1}, curInds{2}, :, :), 4), 3);

    mrsoChg(:, :, m) = (mrsoFut - mrsoHist) ./ mrsoHist;
    prChg(:, :, m) = (prFut - prHist) ./ prHist;
end
end

if north
    curLatInds = latIndsNorth;
    curLonInds = lonIndsNorth;
else
    curLatInds = latIndsSouth;
    curLonInds = lonIndsSouth;
end

curMrsoChgN = squeeze(nanmean(nanmean(mrsoChg(latIndsNorth, lonIndsNorth, :)))) .* 100;
curPrChgN = squeeze(nanmean(nanmean(prChg(latIndsNorth, lonIndsNorth, :)))) .* 100;
curMrsoChgS = squeeze(nanmean(nanmean(mrsoChg(latIndsSouth, lonIndsSouth, :)))) .* 100;
curPrChgS = squeeze(nanmean(nanmean(prChg(latIndsSouth, lonIndsSouth, :)))) .* 100;

figure('Color', [1,1,1]);
hold on;
box on;
axis square;
grid on;

plot([0 3], [0 0], '--k');

b = boxplot([curMrsoChgN curPrChgN curMrsoChgS curPrChgS], 'positions', [.8 1.2 1.8 2.2]);

for bind = 1:size(b, 2)
    if ismember(bind, [1 3])
        set(b(:,bind), {'LineWidth', 'Color'}, {2, [85/255.0, 158/255.0, 237/255.0]})
        lines = findobj(b(:, bind), 'type', 'line', 'Tag', 'Median');
        set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2); 
    elseif bind == 2 || bind == 4
        set(b(:, bind), {'LineWidth', 'Color'}, {2, [110, 191, 66]./255.0})
        lines = findobj(b(:, bind), 'type', 'line', 'Tag', 'Median');
        set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2); 
    end
end

set(gca, 'XTick', [1 2], 'XTickLabels', {'North', 'South'});
set(gca, 'FontSize', 36);
xlim([.5 2.5]);
ylabel('Change (%)');
set(gcf, 'Position', get(0,'Screensize'));
export_fig nile-mrso-pr-chg.eps;
close all;



