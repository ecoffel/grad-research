% plot monthly max temperature change alongside mean monthly bowen ratio changes

% fgoals, hadgem-cc, hadgem-es with weird snow relationships

dataset = 'reanalysis';

tasmaxMetric = 'monthly-mean-max';
tasminMetric = 'monthly-mean-min';

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

% show correlation between Tx and Bowen
showCorr = true;

load waterGrid;
load lat;
load lon;
waterGrid = logical(waterGrid);

% load snow mask from ERA
if ~exist('snowMask', 'var')
    fprintf('building snow mask...\n');
    snowMask = zeros(size(lat));
    sdHistorical = loadDailyData('E:\data\era-interim\output\sd\regrid\world', 'yearStart', 1985, 'yearEnd', 2004);
    for xlat = 1:size(sdHistorical{1}, 1)
        for ylon = 1:size(sdHistorical{1}, 2)
            % get current time series for DJF
            curSd = permute(squeeze(sdHistorical{3}(xlat, ylon, :, [12 1 2], :)), [3 2 1]);
            if nanmedian(curSd) > 0
                snowMask(xlat, ylon) = 1;
            end
        end
    end
    snowMask = logical(snowMask);
end
       
% load ncep/era data if needed and conver to monthly mean
if ~exist('snwNcep', 'var')
    fprintf('loading reanalysis data...\n');
    snwNcep = loadDailyData('e:/data/ncep-reanalysis/output/weasd/regrid/world', 'yearStart', 1985, 'yearEnd', 2004);
    snwNcep = dailyToMonthly(snwNcep);
    
    tempNcep = loadDailyData('e:/data/ncep-reanalysis/output/tmin/regrid/world', 'yearStart', 1985, 'yearEnd', 2004);
    tempNcep{3} = tempNcep{3}-273.15;
    tempNcep = dailyToMonthly(tempNcep);
    
    snwEra = loadDailyData(['e:/data/era-interim/output/sd/regrid/world'], 'yearStart', 1985, 'yearEnd', 2004);
    snwEra = dailyToMonthly(snwEra);
    
    tempEra = loadDailyData('e:/data/era-interim/output/mn2t/regrid/world', 'yearStart', 1985, 'yearEnd', 2004);
    tempEra{3} = tempEra{3} - 273.15;
    tempEra = dailyToMonthly(tempEra);
    
    for year = 1:size(snwNcep{3}, 3)
        for month = 1:size(snwNcep{3}, 4)
            curGrid = snwNcep{3}(:, :, year, month);
            curGrid(~snowMask) = NaN;
            snwNcep{3}(:, :, year, month) = curGrid;
            
            curGrid = tempNcep{3}(:, :, year, month);
            curGrid(~snowMask) = NaN;
            tempNcep{3}(:, :, year, month) = curGrid;
            
            curGrid = snwEra{3}(:, :, year, month);
            curGrid(~snowMask) = NaN;
            snwEra{3}(:, :, year, month) = curGrid;
            
            curGrid = tempEra{3}(:, :, year, month);
            curGrid(~snowMask) = NaN;
            tempEra{3}(:, :, year, month) = curGrid;
        end
    end
    
    % select data and average over years
    snwNcep = snwNcep{3};
    tempNcep = tempNcep{3};
    snwEra = snwEra{3};
    tempEra = tempEra{3};
end

% load cmip5 historical data
if ~exist('tempCmip5', 'var')
    fprintf('loading cmip5 data...\n');
    
    % dimensions: x, y, month, model
    tempCmip5 = [];
    snwCmip5 = [];

    tempRegionsCmip5 = {};
    snwRegionsCmip5 = {};

    for m = 1:length(models)

        curSnw = loadMonthlyData(['e:/data/cmip5/output/' models{m} '/mon/r1i1p1/historical/snw/regrid/world'], 'snw', 'yearStart', 1985, 'yearEnd', 2004);
        
        % apply snow mask to model
        for year = 1:size(curSnw{3}, 3)
            for month = 1:size(curSnw{3}, 4)
                curGrid = curSnw{3}(:, :, year, month);
                curGrid(~snowMask) = NaN;
                curSnw{3}(:, :, year, month) = curGrid;
            end
        end
        
        snwCmip5(:, :, m, :, :) = curSnw{3};

        curTemp = loadDailyData(['e:/data/cmip5/output/' models{m} '/r1i1p1/historical/tasmin/regrid/world'], 'yearStart', 1985, 'yearEnd', 2004);
        
        if nanmean(nanmean(nanmean(nanmean(nanmean(curTemp{3}))))) > 100
            curTemp{3} = curTemp{3} - 273.15;
        end
        curTemp = dailyToMonthly(curTemp);
        
        % apply snow mask to model
        for year = 1:size(curTemp{3}, 3)
            for month = 1:size(curTemp{3}, 4)
                curGrid = curTemp{3}(:, :, year, month);
                curGrid(~snowMask) = NaN;
                curTemp{3}(:, :, year, month) = curGrid;
            end
        end
        
        tempCmip5(:, :, m, :, :) = curTemp{3};

    end
end

% plot ----------------------------------------------------

% loop over all regions for plotting
%for i = 1:length(regionNames)
fprintf('processing correlations...\n');

seasons = [[12 1 2];
           [3 4 5];
           [6 7 8];
           [9 10 11]];

cmip5Corr = zeros(size(snwNcep, 1), size(snwNcep, 2), length(models));
ncepCorr = zeros(size(snwNcep, 1), size(snwNcep, 2));
eraCorr = zeros(size(snwNcep, 1), size(snwNcep, 2));

cmip5Corr(cmip5Corr == 0) = NaN;
ncepCorr(ncepCorr == 0) = NaN;
eraCorr(eraCorr == 0) = NaN;

cmip5AnomT = {};
cmip5AnomS = {};
ncepAnomT = [];
ncepAnomS = [];
eraAnomT = [];
eraAnomS = [];

% loop over all gridboxes
for xlat = 45:size(snwNcep, 1)
    for ylon = 1:size(snwNcep, 2)
        if ~snowMask(xlat, ylon) || waterGrid(xlat, ylon)
            continue;
        end

        % list of winter snow and temp values for each gridbox
        % in region and for each year
        curS = squeeze(nanmean(snwNcep(xlat, ylon, :, seasons(1, :)), 4));
        curT = squeeze(nanmean(tempNcep(xlat, ylon, :, seasons(1, :)), 4));

        nn = find(~isnan(curS) & ~isnan(curT));
        curS = normc(curS(nn));
        curT = normc(curT(nn));

        ncepAnomT = [ncepAnomT; (curT-nanmean(curT))];
        ncepAnomS = [ncepAnomS; (curS-nanmean(curS))];
        
        % calculate seasonal corr for each grid cell
        if length(curT) > 10
            ncepCorr(xlat, ylon) = corr(curS, curT);
        end

        curS = squeeze(nanmean(snwEra(xlat, ylon, :, seasons(1, :)), 4));
        curT = squeeze(nanmean(tempEra(xlat, ylon, :, seasons(1, :)), 4));

        nn = find(~isnan(curS) & ~isnan(curT));
        curS = normc(curS(nn));
        curT = normc(curT(nn));

        eraAnomT = [eraAnomT; (curT-nanmean(curT))];
        eraAnomS = [eraAnomS; (curS-nanmean(curS))];
        
        
        % calculate seasonal corr for each grid cell
        if length(curT) > 10
            eraCorr(xlat, ylon) = corr(curS, curT);
        end

        % same over all cmip5 models
        for model = 1:length(models)
            curS = normc(squeeze(nanmean(snwCmip5(xlat, ylon, model, :, seasons(1, :)), 5)));
            curT = normc(squeeze(nanmean(tempCmip5(xlat, ylon, model, :, seasons(1, :)), 5)));
            
            if length(cmip5AnomT) < model
                cmip5AnomS{model} = curS-nanmean(curS);
                cmip5AnomT{model} = curT-nanmean(curT);
            else
                cmip5AnomS{model} = [cmip5AnomS{model}; curS-nanmean(curS)];
                cmip5AnomT{model} = [cmip5AnomT{model}; curT-nanmean(curT)];
            end
               
            cmip5Corr(xlat, ylon, model) = corr(curS, curT);
        end

    end
end

ind = find(ncepAnomS == 0 | ncepAnomT == 0)
ncepAnomS(ind) = [];
ncepAnomT(ind) = [];

ind = find(eraAnomS == 0 | eraAnomT == 0)
eraAnomS(ind) = [];
eraAnomT(ind) = [];

% figure('Color', [1,1,1]);
% hold on;
% axis square;
% box on;
% grid on;
% 
% % plot area average seasonal temp-bowen correlations
% b = boxplot(squeeze(nanmean(nanmean(cmip5Corr, 2), 1)));
% plot(1:4, squeeze(nanmean(nanmean(ncepCorr, 2), 1)), 'ko', 'MarkerSize', 15, 'LineWidth', 2);
% plot(1:4, squeeze(nanmean(nanmean(eraCorr, 2), 1)), 'kx', 'MarkerSize', 15, 'LineWidth', 2);
% 
% set(b,{'LineWidth', 'Color'},{2, [85/255.0, 158/255.0, 237/255.0]})
% lines = findobj(gcf, 'type', 'line', 'Tag', 'Median');
% set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2);
% 
% set(gca, 'XTick', [1], 'XTickLabels', {''});
% xlim([.75 1.25]);
% ylim([-1 1]);
% ylabel('Correlation', 'FontSize', 24);
% set(gca, 'FontSize', 24);

figure('Color', [1,1,1]);
hold on;
axis square;
box on;
grid on;

for model = 1:length(cmip5AnomT)
    % remove zero values
    ind = find(cmip5AnomS{model} == 0 | cmip5AnomT{model} == 0);
    cmip5AnomS{model}(ind) = [];
    cmip5AnomT{model}(ind) = [];

    f = fit(cmip5AnomT{model}, cmip5AnomS{model}, 'poly1');
    p3 = plot([min(cmip5AnomT{model}) max(cmip5AnomT{model})], [f(min(cmip5AnomT{model})) f(max(cmip5AnomT{model}))], 'Color', [.5 .5 .5], 'LineWidth', 1);
end

colors = get(gca, 'colororder');

f = fit(ncepAnomT, ncepAnomS, 'poly1');
p1 = plot([min(ncepAnomT) max(ncepAnomT)], [f(min(ncepAnomT)) f(max(ncepAnomT))], 'LineWidth', 3, 'Color', colors(1, :));

f = fit(eraAnomT, eraAnomS, 'poly1');
p2 = plot([min(eraAnomT) max(eraAnomT)], [f(min(eraAnomT)) f(max(eraAnomT))], 'LineWidth', 3, 'Color', colors(2, :));

xlim([-1 1]);
ylim([-1 1]);
ylabel('Normalized snow mass anomaly', 'FontSize', 36, 'Color', [.1 .1 .1]);
xlabel('Normalized Tn anomaly', 'FontSize', 36, 'Color', [.1 .1 .1]);
set(gca, 'FontSize', 36);
leg = legend([p1 p2 p3], {'NCEP II', 'ERA-Interim', 'CMIP5'});
set(leg, 'FontSize', 36, 'location', 'northeast');
set(gcf, 'Position', get(0,'Screensize'));
export_fig 'snw-temp-fit.pdf';

print(['snw-temp-fit.eps'], '-depsc', '-r300');
close all;

for model = 1:length(cmip5AnomT)
    % remove zero values
    ind = find(cmip5AnomS{model} == 0 | cmip5AnomT{model} == 0);
    cmip5AnomS{model}(ind) = [];
    cmip5AnomT{model}(ind) = [];

    figure;
    f = fit(cmip5AnomT{model}, cmip5AnomS{model}, 'poly1');
    p3 = plot([min(cmip5AnomT{model}) max(cmip5AnomT{model})], [f(min(cmip5AnomT{model})) f(max(cmip5AnomT{model}))], 'Color', [.5 .5 .5], 'LineWidth', 1);
end
