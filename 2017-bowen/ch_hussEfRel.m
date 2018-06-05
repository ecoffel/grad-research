txxAnom = true;
warmSeasonAnom = false;

showscatter = false;
var = 'ev';

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', ...
          'canesm2', 'cnrm-cm5', 'csiro-mk3-6-0', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', ...
          'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
          'miroc5', 'mri-cgcm3', 'noresm1-m'};
models = {'access1-0'};
hussHist = [];
efHist = [];

ampVarFut = [];
driverVarFut = [];
    
for m = 1:length(models)
    load(['E:\data\projects\bowen\huss-chg-data\huss-txx-historical-1981-2005-' models{m} '-txxDays.mat']);
    hussHist(:,:,:,m) = hussTxxHist;
    
    load(['E:\data\projects\bowen\ef-chg-data\ef-txx-historical-1981-2005-' models{m} '-txxDays.mat']);
    efHist(:,:,:,m) = efTxxHist;
    efHist(efHist > 1) = NaN;
end

load waterGrid.mat;
waterGrid = logical(waterGrid);

load lat;
load lon;
       
slopesHist = [];
slopesFut = [];
corrHist = [];
corrFut = [];

for m = 1:length(models)
    fprintf('processing %s...\n', models{m});

    huss = squeeze(hussHist(:,:,:,m));
    hHist = [];
    for year = 1:size(huss,3)
        hTmp = huss(:,:,year);
        hTmp(waterGrid) = NaN;
        hHist(:,:,year) = hTmp;
    end

    ef = squeeze(efHist(:,:,:,m));
    efHist = [];
    for year = 1:size(ef,3)
        eTmp = ef(:,:,year);
        eTmp(waterGrid) = NaN;
        efHist(:,:,year) = eTmp;
    end

    
    for xlat = 1:size(lat, 1)
        for ylon = 1:size(lat, 2)
            
            curh = squeeze(hHist(xlat, ylon, :));
            curef = squeeze(efHist(xlat, ylon, :));
            
            nn = find(isnan(curh) | isnan(curef));
            if length(nn) > 15
                slopesHist(xlat, ylon, m) = NaN;
                continue;
            end
            
            curh(nn) = [];
            curef(nn) = [];
            
            f = fit(curef, curh, 'poly1');

            slopesHist(xlat, ylon, m) = f.p1;
        end
    end
end

slopesHist = slopesHist';
slopesFut = slopesFut';
corrHist = corrHist';
corrFut = corrFut';

corrs = [];
slopes = [];
i = 1;
for r = 1:size(slopesHist,2)
    slopes(:,i) = slopesHist(:,r);
    slopes(:,i+1) = slopesFut(:,r);
    corrs(:,i) = corrHist(:,r);
    corrs(:,i+1) = corrFut(:,r);
    i = i+2;
end


slopesScatter = false;
if slopesScatter
    region = 4;

    figure('Color', [1,1,1]);
    hold on;
    box on;
    axis square;
    grid on;

    load(['e:/data/projects/bowen/derived-chg/txxAmp.mat']);
    [latInds, lonInds] = latLonIndexRange({lat, lon, []}, regions(region, [1 2]), regions(region, [3 4]));
    txxAmp = squeeze(nanmean(nanmean(amp(latInds,lonInds,:),2),1));

    v3Colormap = '*RdBu';
    v3ChgSort = sort(txxAmp);
    v3Color = brewermap(length(v3ChgSort)*2, v3Colormap) .* .7;
    v3ZeroInd = find(abs(v3ChgSort) == min(abs(v3ChgSort)));

    % loop over all models
    for m = 1:length(models)
        color = v3Color(length(v3ChgSort)-v3ZeroInd+find(v3ChgSort == txxAmp(m))-1, :);
        t = text(slopesHist(m,2), txxAmp(m), num2str(m), 'HorizontalAlignment', 'center', 'Color', 'k');
        t.FontSize = 30;
        t.FontWeight = 'bold';
    end

    colormap(v3Color);
    caxis([-max(abs(v3ChgSort)) max(abs(v3ChgSort))]);
    cb = colorbar();
    ylabel(cb, 'TXx amplification');

    set(gca, 'FontSize', 40);

    ylabel('TXx amplification');
    ylim([-1 3]);
    set(gca, 'YTick', -1:3);
    xlabel('Historical TXx-EF anom slope');
    xlim([-1.6 1]);
    set(gca, 'XTick', -1.5:.5:1);

    title([regionNames{region}]);
    plot([-100 100], [0 0], '--k');
    plot([0 0], [-100 100], '--k');
    set(gcf, 'Position', get(0,'Screensize'));
    export_fig txx-amp-ef-slope-ef-chg-4.eps;
    close all;
end


if showscatter
    var3 = 'txxAmp';
    var3Months = [1];
    v3FileStr = [var3];
    v3YStr = ['TXx amplification (' char(176) 'C)'];
    v3ColorOffset = 0;
    v3Colormap = '*RdBu';
    v3FileStr = [var3];
    load(['e:/data/projects/bowen/derived-chg/' var3]);
    eval(['v3 = amp;']);
    v3(v3>1000 | v3 < -1000) = NaN;

    var2 = 'efChgWarmTxxAnom';
    var2Months = [1];
    v2YStr = 'EF TXx rel change (Fraction)';
    v2YLim = [-.075 .125];
    v2YTick = -.075:.025:.125;
    % v2YLim = [-2 2];
    % v2YTick = -.075:.025:.075;
    v2FileStr = [var2];
    load(['e:/data/projects/bowen/derived-chg/' var2]);
    eval(['v2 = ' var2 ';']);
    v2(v2>1000 | v2<-1000) = NaN;
    %v2 = v2 .* 3600 .* 24;
    load('2017-bowen/hottest-season-txx-rel-cmip5.mat');

    figure('Color', [1,1,1]);
    hold on;
    box on;
    axis square;
    grid on;

    region = 10;

    [latInds, lonInds] = latLonIndexRange({lat, lon, []}, regions(region, [1 2]), regions(region, [3 4]));

    if length(var2Months) == 0
        var2Months = round(squeeze(nanmean(nanmean(hottestSeason(latInds, lonInds, :)))));
        var2Months = [var2Months-1 var2Months var2Months+1];
        var2Months(var2Months == 0) = 12;
        var2Months(var2Months == 13) = 1;
    end

    % and bowen
    v2Chg = squeeze(nanmean(nanmean(nanmean(v2(latInds, lonInds, :, var2Months), 4), 2), 1));
    v3Chg = squeeze(nanmean(nanmean(nanmean(v3(latInds, lonInds, :, var3Months), 4), 2), 1));
    nn = find(~isnan(v3Chg) & ~isnan(v2Chg));
    v2Chg = v2Chg(nn);
    v3Chg = v3Chg(nn);

    v3ChgSort = sort(v3Chg);
    v3Color = brewermap(length(v3ChgSort)*2, v3Colormap) .* .7;
    v3ZeroInd = find(abs(v3ChgSort) == min(abs(v3ChgSort)));

    % loop over all models
    for m = 1:length(models)
        color = v3Color(length(v3ChgSort)-v3ZeroInd+find(v3ChgSort == v3Chg(m))-1, :);
        t = text(slopes(m,7), v2Chg(m), num2str(m), 'HorizontalAlignment', 'center', 'Color', color);
        t.FontSize = 30;
        t.FontWeight = 'bold';
    end

    colormap(v3Color);
    caxis([-max(abs(v3ChgSort)) max(abs(v3ChgSort))]);
    cb = colorbar();
    ylabel(cb, v3YStr);

    set(gca, 'FontSize', 40);

    ylabel(v2YStr);
    ylim(v2YLim);
    set(gca, 'YTick', v2YTick);

    title([regionNames{region}]);
    xlabel('Historical EF-TXx anom slope');
    xlim([-.75 .5]);
    set(gca, 'XTick', [-.75:.25:.5]);
    plot([-100 100], [0 0], '--k');
    plot([0 0], [-100 100], '--k');
    set(gcf, 'Position', get(0,'Screensize'));
    export_fig txx-amp-ef-slope-ef-chg-10.eps;
    close all;
end






figure('Color',[1,1,1]);
hold on;
grid on;
axis square;
box on;
b = boxplot(slopes,'positions',[.8 1.2 1.8 2.2 2.8 3.2 3.8 4.2],'colors','brbrbrbr');
plot([0 6], [0 0], '--k');
xlim([0 5]);
ylim([-1 1]);
set(gca, 'FontSize', 40);
set(gca, 'XTick', 1:4, 'XTickLabel', {'U.S.', 'Europe', 'Amazon', 'China'});
xtickangle(45);
ylabel(['Spearman correlation']);
set(b,{'LineWidth'},{2})
lines = findobj(gcf, 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2);
title('TXx - EF correlation');
set(gcf, 'Position', get(0,'Screensize'));
export_fig(['txx-' var '-corr-time.eps']);
export_fig(['txx-' var '-corr-time.png']);
close all;
