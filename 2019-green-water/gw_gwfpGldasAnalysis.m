

load('2019-green-water/iizumiMaize');
load('2019-green-water/iizumiSoybean');
load('2019-green-water/iizumiRice');
load('2019-green-water/iizumiWheat');

load('2019-green-water/sacks-Maize');
sacksCalMaize = calendar;
load('2019-green-water/sacks-Soybeans');
sacksCalSoybean = calendar;
load('2019-green-water/sacks-Rice');
sacksCalRice = calendar;
load('2019-green-water/sacks-Wheat');
sacksCalWheat = calendar;

load('2019-green-water/gldasDataET-regrid.mat');
load('2019-green-water/gldasDataP-regrid.mat');
load('2019-green-water/gwfpData.mat');

load('2019-green-water/gpcpData-regrid.mat');

lat = iizumiMaize{1};
lon = iizumiMaize{2};

monthLengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

if ~exist('gldasETData') 
    fprintf('loading GLDAS pr...\n');
    gldas_p = loadMonthlyData('E:\data\gldas-noah-v2\output\Rainf_f_tavg', 'Rainf_f_tavg', 'startYear', 1981, 'endYear', 2010);
    gldas_p{2}(gldas_p{2}<0) = 360+gldas_p{2}(gldas_p{2}<0);
    
% 
%     fprintf('loading GLDAS t...\n');
%     gldas_t = loadMonthlyData('E:\data\gldas-noah-v2\output\Tair_f_inst', 'Tair_f_inst', 'startYear', 1981, 'endYear', 2010);

    fprintf('loading GLDAS et...\n');
%     gldas_et = loadMonthlyData('E:\data\gldas-noah-v2\output\Evap_tavg', 'Evap_tavg', 'startYear', 1981, 'endYear', 2010);
    
    % both of these are regridded to the iizumi grid
    gwfpLat = [];
    gwfpLon = [];
    gwfpData = [];

    gldasLat = [];
    gldasLon = [];
%     gldasETData = [];
%     gldasTData = [];
    gldasPData = [];
    
    for year = 1:length(1981:2010)
        
        fprintf('processing year %d...\n', 1981+year-1);
        
        for m = 1:12
%             gldas_et{3}(:, :, year, m) = gldas_et{3}(:, :, year, m) .* (60*60*24*monthLengths(m));
            gldas_p{3}(:, :, year, m) = gldas_p{3}(:, :, year, m) .* (60*60*24*monthLengths(m));
%             gldas_t{3}(:, :, year, m) = gldas_t{3}(:, :, year, m) - 273.15;

            
%             gldasETRegrid = regridGriddata({gldas_et{1}, gldas_et{2}, gldas_et{3}(:, :, year, m)}, iizumiMaize, false);
%             gldasETData(:, :, year, m) = gldasETRegrid{3};
            
%             gldasTRegrid = regridGriddata({gldas_t{1}, gldas_t{2}, gldas_t{3}(:, :, year, m)}, iizumiMaize, false);
%             gldasTData(:, :, year, m) = gldasTRegrid{3};
            
            gldasPRegrid = regridGriddata({gldas_p{1}, gldas_p{2}, gldas_p{3}(:, :, year, m)}, iizumiMaize, false);
            gldasPData(:, :, year, m) = gldasPRegrid{3};
            
%             if year == 1
%                 gldasLat = gldasETRegrid{1};
%                 gldasLon = gldasETRegrid{2};
%                 
%                 
%                 fprintf('loading gwfp month %d...\n', m);
% 
%                 load(['E:\data\bgwfp\output\ag\gwfp\gwfp_' num2str(m)]);
%                 if m == 1
%                     eval(['gwfpLat(:, :, ' num2str(m) ') = gwfp_' num2str(m) '{1};']);
%                     eval(['gwfpLon(:, :, ' num2str(m) ') = gwfp_' num2str(m) '{2};']);
% 
%                     gldas_et{2}(gldas_et{2} < 0) = gldas_et{2}(gldas_et{2} < 0)+360;
%                     gwfpLon(gwfpLon < 0) = gwfpLon(gwfpLon < 0)+360;    
%                 end
%                 eval(['gwfptmp = gwfp_' num2str(m) '{3};']);
%                 gwfpRegrid = regridGriddata({gwfpLat, gwfpLon, gwfptmp}, iizumiMaize, false);
%                 gwfpData(:,:,m) = gwfpRegrid{3};
%             end
        end
    end
end

% save('2019-green-water/gldasDataP-regrid.mat', 'gldasPData');
% save('2019-green-water/gldasDataT-regrid.mat', 'gldasTData');
% save('2019-green-water/gldasDataET-regrid.mat', 'gldasETData');
% save('2019-green-water/gwfpData-regrid.mat', 'gwfpData');



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


for m = 1:12
    gldasETData(:, :, :, m) = gldasETData(:, :, :, m) ./ squeeze(nanmean(gldasPData(:, :, 1995-1981+1:2004-1981+1, m), 3));
    gwfpData(:, :, m) = gwfpData(:, :, m) ./ squeeze(nanmean(cruData(:, :, 1995-1981+1:2004-1981+1, m), 3));
end
gwfpData(gwfpData == Inf) = NaN;

regions = [[33, 52, [-110, -85]+360]; ... % us midwest
           [31, 41, [110, 123]]; ... % ne china
           [10, 30, 71, 83]; ...  % west india
           [42, 55, 355, 40];      % europe
           [-40, -30, [-56, -65]+360] % argentina
           [4, 15, [354, 9]]]; % w africa


if ~exist('pctGWSupplyUsedWeighted')

    maizeYield = iizumiMaize{3};
    soyYield = iizumiSoybean{3};
    riceYield = iizumiRice{3};
    wheatYield = iizumiWheat{3};

    x = reshape(maizeYield, [numel(maizeYield), 1]);
    x = x - nanmin(x);
    maizeYield = reshape(x ./ nanmax(x), [size(iizumiMaize{3})]);

    x = reshape(soyYield, [numel(soyYield), 1]);
    x = x - nanmin(x);
    soyYield = reshape(x ./ nanmax(x), [size(iizumiSoybean{3})]);

    x = reshape(riceYield, [numel(riceYield), 1]);
    x = x - nanmin(x);
    riceYield = reshape(x ./ nanmax(x), [size(iizumiRice{3})]);

    x = reshape(wheatYield, [numel(wheatYield), 1]);
    x = x - nanmin(x);
    wheatYield = reshape(x ./ nanmax(x), [size(iizumiWheat{3})]);

    gwfpYieldRelMaize = [];
    gwfpYieldRelSoy = [];
    gwfpYieldRelRice = [];
    gwfpYieldRelWheat = [];

    pctGWSupplyUsed = [];
    pctGWSupplyUsedWeighted = [];

    regionalTotalYield = [];

    totalYieldRef = [];

    for xlat = 1:size(lat, 1)
        for ylon = 1:size(lat, 2)
            totalYieldRef(xlat, ylon) = nanmean(maizeYield(xlat, ylon, (1995-1981+1):(2004-1981+1)), 3);
%                                         ;nansum([nanmean(maizeYield(xlat, ylon, (1995-1981+1):(2004-1981+1)), 3), ...
%                                                nanmean(soyYield(xlat, ylon, (1995-1981+1):(2004-1981+1)), 3), ...
%                                                nanmean(riceYield(xlat, ylon, (1995-1981+1):(2004-1981+1)), 3), ...
%                                                nanmean(wheatYield(xlat, ylon, (1995-1981+1):(2004-1981+1)), 3)]);
        end
    end
    totalYieldRef(totalYieldRef == 0) = NaN;
    

    for m = 1:12

        gwfpYieldRelMaize(:, :, m) = gwfpData(:, :, m) ./ totalYieldRef;
        gwfpYieldRelSoy(:, :, m) = gwfpData(:, :, m) ./ totalYieldRef;
        gwfpYieldRelRice(:, :, m) = gwfpData(:, :, m) ./ totalYieldRef;
        gwfpYieldRelWheat(:, :, m) = gwfpData(:, :, m) ./ totalYieldRef;

        for year = 1:length(1981:2010)
            gwfpScaledMaize(:, :, year, m) = maizeYield(:, :, year) .* gwfpYieldRelMaize(:, :, m);
            gwfpScaledSoy(:, :, year, m) = soyYield(:, :, year) .* gwfpYieldRelSoy(:, :, m);
            gwfpScaledRice(:, :, year, m) = riceYield(:, :, year) .* gwfpYieldRelRice(:, :, m);
            gwfpScaledWheat(:, :, year, m) = wheatYield(:, :, year) .* gwfpYieldRelWheat(:, :, m);
        end

        for xlat = 1:size(lat, 1)
            for ylon = 1:size(lat, 2)
                for year = 1:length(1981:2010)
                    pctGWSupplyUsed(xlat, ylon, year, m) = gwfpScaledMaize(xlat, ylon, year, m) ./ gldasETData(xlat, ylon, year, m);
                                   
%                     pctGWSupplyUsed(xlat, ylon, year, m) = nansum([gwfpScaledMaize(xlat, ylon, year, m), gwfpScaledSoy(xlat, ylon, year, m), ...
%                                        gwfpScaledRice(xlat, ylon, year, m), gwfpScaledWheat(xlat, ylon, year, m)]) ./ gldasETData(xlat, ylon, year, m);
                end
            end
        end

        for r = 1:size(regions, 1)
            [latInds, lonInds] = latLonIndexRange({lat, lon, []}, regions(r, 1:2), regions(r, 3:4));
            for year = 2:length(1981:2010)

                regionalTotalYield(r, year-1, m) = squeeze(nanmean(nanmean(maizeYield(latInds, lonInds, year))));
                
%                 regionalTotalYield(r, year-1, m) = squeeze(nanmean([nanmean(nanmean(maizeYield(latInds, lonInds, year))), ...
%                                                                     nanmean(nanmean(soyYield(latInds, lonInds, year))), ...
%                                                                     nanmean(nanmean(riceYield(latInds, lonInds, year))), ...
%                                                                     nanmean(nanmean(wheatYield(latInds, lonInds, year)))]));

                yieldSumMaize = squeeze(nansum(nansum(maizeYield(latInds, lonInds, year))));
%                 yieldSumSoy = squeeze(nansum(nansum(soyYield(latInds, lonInds, year))));
%                 yieldSumRice = squeeze(nansum(nansum(riceYield(latInds, lonInds, year))));
%                 yieldSumWheat = squeeze(nansum(nansum(wheatYield(latInds, lonInds, year))));

                yieldWeightMaize = maizeYield(latInds, lonInds, year) ./ (yieldSumMaize);
%                 yieldWeightMaize = maizeYield(latInds, lonInds, year) ./ (yieldSumMaize+yieldSumSoy+yieldSumRice+yieldSumWheat);
%                 yieldWeightSoy = soyYield(latInds, lonInds, year) ./ (yieldSumMaize+yieldSumSoy+yieldSumRice+yieldSumWheat);
%                 yieldWeightRice = riceYield(latInds, lonInds, year) ./ (yieldSumMaize+yieldSumSoy+yieldSumRice+yieldSumWheat);
%                 yieldWeightWheat = wheatYield(latInds, lonInds, year) ./ (yieldSumMaize+yieldSumSoy+yieldSumRice+yieldSumWheat);

                weightedGwfpMaize = yieldWeightMaize .* maizeYield(latInds, lonInds, year) .* gwfpYieldRelMaize(latInds, lonInds, m);
%                 weightedGwfpSoy = yieldWeightSoy .* soyYield(latInds, lonInds, year) .* gwfpYieldRelSoy(latInds, lonInds, m);
%                 weightedGwfpRice = yieldWeightRice .* riceYield(latInds, lonInds, year) .* gwfpYieldRelRice(latInds, lonInds, m);
%                 weightedGwfpWheat = yieldWeightWheat .* wheatYield(latInds, lonInds, year) .* gwfpYieldRelWheat(latInds, lonInds, m);

                weightedGldasMaize = yieldWeightMaize .* nanmean(gldasETData(latInds, lonInds, year, m), 4);
%                 weightedGldasSoy = yieldWeightSoy .* nanmean(gldasETData(latInds, lonInds, year, m), 4);
%                 weightedGldasRice = yieldWeightRice .* nanmean(gldasETData(latInds, lonInds, year, m), 4);
%                 weightedGldasWheat = yieldWeightWheat .* nanmean(gldasETData(latInds, lonInds, year, m), 4);

                pctMaize = nansum(nansum(weightedGwfpMaize)) / nansum(nansum(weightedGldasMaize));
%                 pctSoy = nansum(nansum(weightedGwfpSoy)) / nansum(nansum(weightedGldasSoy));
%                 pctRice = nansum(nansum(weightedGwfpRice)) / nansum(nansum(weightedGldasRice));
%                 pctWheat = nansum(nansum(weightedGwfpWheat)) / nansum(nansum(weightedGldasWheat));

                pctGWSupplyUsedWeighted(r, year-1, m) =  pctMaize;%nansum([pctMaize, pctSoy, pctRice, pctWheat]);
            end
        end
    end
    pctGWSupplyUsedWeighted = pctGWSupplyUsedWeighted .* 100;
end

colors = brewermap(8, 'Accent');

figure('Color', [1,1,1]);
hold on;
axis square;
grid on;
box on;

plot(1982:2010, squeeze(nanmax(pctGWSupplyUsedWeighted(1,:, :), [], 3)), 'linewidth', 12, 'color', colors(1,:));

ylabel('% GW');
set(gca, 'ytick', 0:25:100);
ylim([0 100])
% 
% yyaxis right;
% plot(1982:2010, squeeze(nanmax(pctGWSupplyUsedWeighted(1,:, :), [], 3)), 'linewidth', 12, 'color', colors(1,:));

set(gca, 'fontsize', 80);
set(gca, 'xtick', 1985:10:2010);
xtickangle(45)
xlim([1980, 2012])

set(gcf, 'Position', get(0,'Screensize'));
export_fig gw-pct-used-us-midwest.eps;
close all;



figure('Color', [1,1,1]);
hold on;
axis square;
grid on;
box on;

plot(1982:2010, squeeze(nanmax(pctGWSupplyUsedWeighted(2,:, :), [], 3)), 'linewidth', 12, 'color', colors(1,:));
plot([1982 2010], [100 100], '--k', 'linewidth', 6);
ylabel('% GW');
set(gca, 'fontsize', 80);
set(gca, 'xtick', 1985:10:2010, 'ytick', 0:50:200);
xtickangle(45)
xlim([1980, 2012])
ylim([0 200])
set(gcf, 'Position', get(0,'Screensize'));
export_fig gw-pct-used-ne-china.eps;
close all;



figure('Color', [1,1,1]);
hold on;
axis square;
grid on;
box on;

plot(1982:2010, squeeze(nanmax(pctGWSupplyUsedWeighted(3,:, :), [], 3)), 'linewidth', 12, 'color', colors(1,:));
plot([1982 2010], [100 100], '--k', 'linewidth', 6);
ylabel('% GW');
set(gca, 'fontsize', 80);
set(gca, 'xtick', 1985:10:2010, 'ytick', 0:50:200);
xtickangle(45)
xlim([1980, 2012])
ylim([0 200])
set(gcf, 'Position', get(0,'Screensize'));
export_fig gw-pct-used-w-india.eps;
close all;



figure('Color', [1,1,1]);
hold on;
axis square;
grid on;
box on;

plot(1982:2010, squeeze(nanmax(pctGWSupplyUsedWeighted(4,:, :), [], 3)), 'linewidth', 12, 'color', colors(1,:));
plot([1982 2010], [100 100], '--k', 'linewidth', 6);
ylabel('% GW');
set(gca, 'fontsize', 80);
set(gca, 'xtick', 1985:10:2010, 'ytick', 0:25:125);
xtickangle(45)
xlim([1980, 2012])
ylim([0 125])
set(gcf, 'Position', get(0,'Screensize'));
export_fig gw-pct-used-europe.eps;
close all;






figure('Color', [1,1,1]);
hold on;
axis square;
grid on;
box on;

plot(1982:2010, squeeze(nanmax(pctGWSupplyUsedWeighted(5,:, :), [], 3)), 'linewidth', 12, 'color', colors(1,:));

ylabel('% GW');
set(gca, 'fontsize', 80);
set(gca, 'xtick', 1985:10:2010, 'ytick', 0:25:100);
xtickangle(45)
xlim([1980, 2012])
ylim([0 100])
set(gcf, 'Position', get(0,'Screensize'));
export_fig gw-pct-used-argentina.eps;
close all;




figure('Color', [1,1,1]);
hold on;
axis square;
grid on;
box on;

plot(1982:2010, squeeze(nanmax(pctGWSupplyUsedWeighted(6,:, :), [], 3)), 'linewidth', 12, 'color', colors(1,:));

ylabel('% GW');
set(gca, 'fontsize', 80);
set(gca, 'xtick', 1985:10:2010, 'ytick', 0:25:100);
xtickangle(45)
xlim([1980, 2012])
ylim([0 100])
set(gcf, 'Position', get(0,'Screensize'));
export_fig gw-pct-used-w-africa.eps;
close all;


result = {lat, lon, nanmean(nansum(pctGWSupplyUsed(:, :, (1995-1981+1):(2004-1981+1), :), 4), 3) .* 100};
saveData = struct('data', {result}, ...
                  'plotRegion', 'green-water', ...
                  'plotRange', [0 100], ...
                  'cbXTicks', 0:10:100, ...
                  'plotTitle', [''], ...
                  'fileTitle', ['gw-supply-used-maize.eps'], ...
                  'plotXUnits', ['Human use of available ET (%, 1995 - 2004)'], ...
                  'blockWater', true, ...
                  'plotCountries', true, ...
                  'colormap', brewermap([],'Greens'), ...
                  'boxCoords', {regions});
plotFromDataFile(saveData);


save('2019-green-water/pct-gw-used-maize.mat', 'pctGWSupplyUsed');



