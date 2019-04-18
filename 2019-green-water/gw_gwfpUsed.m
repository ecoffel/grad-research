load('2019-green-water/iizumiMaize');

load('2019-green-water/gldasDataET-regrid.mat');
load('2019-green-water/gldasDataP-regrid.mat');
load('2019-green-water/gwfpData.mat');

lat = iizumiMaize{1};
lon = iizumiMaize{2};

monthLengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

cru = loadMonthlyData('E:\data\cru\output\pre', 'pre', 'startYear', 1981, 'endYear', 2010);
cruData = cru{3};
% 
% % regrid gpcp if necessary
% gpcp = loadMonthlyData('E:\data\gpcp\output\precip\monthly\1979-2017', 'precip', 'startYear', 1981, 'endYear', 2010);
% gpcpLat = gpcp{1};
% gpcpLon = gpcp{2};
% gpcpData = gpcp{3};
% gpcpRegridData = [];
% for y = 1:size(gpcpData, 3)
%     for m = 1:size(gpcpData, 4)
%         fprintf('regridding %d/%d\n', y, m);
%         tmp = squeeze(gpcpData(:, :, y, m)) .* monthLengths(m);
%         tmpRegrid = regridGriddata({gpcpLat, gpcpLon, tmp}, iizumiMaize, false);
%         gpcpRegridData(:, :, y, m) = tmpRegrid{3};
%     end
% end
% 
% save('2019-green-water/gpcpData-regrid.mat', 'gpcpRegridData');




% gldasNormData = squeeze(nanmean(gldasETData(:, :, 1995-1981+1:2004-1981+1, :), 3)) ./ squeeze(nanmean(gldasPData(:, :, 1995-1981+1:2004-1981+1, :), 3));
% gwfpNormData = gwfpData ./ squeeze(nanmean(gpcpRegridData(:, :, 1995-1981+1:2004-1981+1, :), 3));
% p = gwfpNormData ./ gldasNormData;


gldasET = squeeze(nansum(nanmean(gldasETData(:, :, 1995-1981+1:2004-1981+1, :), 3), 4)) ./ squeeze(nansum(nanmean(gldasPData(:, :, 1995-1981+1:2004-1981+1, :), 3), 4));
gwfp = nansum(gwfpData, 3) ./ squeeze(nansum(nanmean(cruData(:, :, 1995-1981+1:2004-1981+1, :), 3), 4));

gwfpData(gwfpData == Inf) = NaN;

regions = [[33, 52, [-110, -85]+360]; ... % us midwest
           [31, 41, [110, 123]]; ... % ne china
           [10, 30, 71, 83]; ...  % west india
           [42, 55, 355, 40];      % europe
           [-40, -30, [-56, -65]+360] % argentina
           [4, 15, [354, 9]]]; % w africa


pctGWSupplyUsed = gwfp ./ gldasET;

colors = brewermap(8, 'Accent');

result = {lat, lon, pctGWSupplyUsed .* 100};
saveData = struct('data', {result}, ...
                  'plotRegion', 'green-water', ...
                  'plotRange', [0 100], ...
                  'cbXTicks', 0:10:100, ...
                  'plotTitle', [''], ...
                  'fileTitle', ['gw-supply-used.pdf'], ...
                  'plotXUnits', ['Human use of available ET (%, 1995 - 2004)'], ...
                  'blockWater', true, ...
                  'plotCountries', true, ...
                  'colormap', brewermap([],'Greens'));
plotFromDataFile(saveData);


% save('2019-green-water/pct-gw-used.mat', 'pctGWSupplyUsed');



