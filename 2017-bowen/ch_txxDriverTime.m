txxAnom = true;
warmSeasonAnom = false;

showscatter = false;
var = 'netRad';

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

regionNames = {'World', ...
                'Eastern U.S.', ...
                'Southeast U.S.', ...
                'Central Europe', ...
                'Mediterranean', ...
                'Northern SA', ...
                'Amazon', ...
                'Central Africa', ...
                'North Africa', ...
                'China', ...
                'South Africa', ...
                'Southern SA'};
regionAb = {'world', ...
            'us-east', ...
            'us-se', ...
            'europe', ...
            'med', ...
            'sa-n', ...
            'amazon', ...
            'africa-cent', ...
            'n-africa', ...
            'china', ...
            's-africa', ...
            'sa-s'};
            
regions = [[[-90 90], [0 360]]; ...             % world
           [[30 42], [-91 -75] + 360]; ...     % eastern us
           [[30 41], [-95 -75] + 360]; ...      % southeast us
           [[45, 55], [10, 35]]; ...            % Europe
           [[35 50], [-10+360 45]]; ...        % Med
           [[5 20], [-90 -45]+360]; ...         % Northern SA
           [[-10, 7], [-75, -62]+360]; ...      % Amazon
           [[-10 10], [15, 30]]; ...            % central africa
           [[15 30], [-4 29]]; ...              % north africa
           [[22 40], [105 122]]; ...               % china
           [[-24 -8], [14 40]]; ...                      % south africa
           [[-45 -25], [-65 -49]+360]];


ampVarHist = [];
driverVarHist = [];

ampVarFut = [];
driverVarFut = [];
       
if txxAnom
    
    for m = 1:length(models)
        load(['E:\data\projects\bowen\temp-chg-data\cmip5-ann-max-' models{m} '-historical-1981-2005.mat']);
        ampVarHist(:,:,:,m) = annExt;
        load(['E:\data\projects\bowen\' var '-chg-data\' var '-txx-warm-anom-historical-1981-2005-' models{m} '.mat']);
        driverVarHist(:,:,:,m) = regionalFluxHistoricalTxx;
        driverVarHist(driverVarHist>1)=NaN;
        
        load(['E:\data\projects\bowen\temp-chg-data\cmip5-ann-max-' models{m} '-rcp85-2061-2085.mat']);
        ampVarFut(:,:,:,m) = annExt;
        load(['E:\data\projects\bowen\' var '-chg-data\' var '-txx-anom-future-2061-2085-' models{m} '.mat']);
        driverVarFut(:,:,:,m) = regionalFluxFutureTxx;
        driverVarFut(driverVarFut>1)=NaN;
    end
    
elseif warmSeasonAnom
    
end

load waterGrid.mat;
waterGrid = logical(waterGrid);

load lat;
load lon;

regionNames = {'World', ...
                'Eastern U.S.', ...
                'Southeast U.S.', ...
                'Central Europe', ...
                'Mediterranean', ...
                'Northern SA', ...
                'Amazon', ...
                'Central Africa', ...
                'North Africa', ...
                'China'};
regionAb = {'world', ...
            'us-east', ...
            'us-se', ...
            'europe', ...
            'med', ...
            'sa-n', ...
            'amazon', ...
            'africa-cent', ...
            'n-africa', ...
            'china'};
            
regions = [[[-90 90], [0 360]]; ...             % world
           [[30 42], [-91 -75] + 360]; ...     % eastern us
           [[30 41], [-95 -75] + 360]; ...      % southeast us
           [[45, 55], [10, 35]]; ...            % Europe
           [[35 50], [-10+360 45]]; ...        % Med
           [[5 20], [-90 -45]+360]; ...         % Northern SA
           [[-10, 1], [-75, -53]+360]; ...      % Amazon
           [[-10 10], [15, 30]]; ...            % central africa
           [[15 30], [-4 29]]; ...              % north africa
           [[22 40], [105 122]]];               % china


       
       
rind = 1;
slopesHist = [];
slopesFut = [];
corrHist = [];
corrFut = [];

for region = [2 4 7 10]
    [latInds, lonInds] = latLonIndexRange({lat, lon, []}, regions(region, [1 2]), regions(region, [3 4]));

    for m = 1:length(models)
        fprintf('processing %s...\n', models{m});
        
        curAmpVar = squeeze(ampVarHist(:,:,:,m));
        aHist = [];
        for year = 1:size(curAmpVar,3)
            aTmp = curAmpVar(:,:,year);
            aTmp(waterGrid) = NaN;
            aTmp = aTmp(latInds,lonInds);
            aHist(:,:,year) = aTmp;
        end
        aHist = squeeze(nanmean(nanmean(aHist,2),1));
        aHist = (aHist-nanmean(aHist)) ./ nanmean(aHist); 
        
        curDVar = squeeze(driverVarHist(:,:,:,m));
        dHist = [];
        for year = 1:size(curDVar,3)
            dTmp = curDVar(:,:,year);
            dTmp(waterGrid) = NaN;
            dTmp = dTmp(latInds,lonInds);
            dHist(:,:,year) = dTmp;
        end
        dHist = squeeze(nanmean(nanmean(dHist,2),1));
        
        X = [ones(size(aHist)), dHist];
        b = regress(aHist,X);
        afit = X*b;
        resid = aHist-afit;        
        s = bootstrp(1000, @(bootr)regress(afit+bootr,X),resid);
        slopesHist(rind,m) = nanmean(s(:,2));
        corrHist(rind,m) = corr(aHist, dHist, 'type', 'Spearman');
        
        
        
        
        
        
        
        curAmpVar = squeeze(ampVarFut(:,:,:,m));
        aFut = [];
        for year = 1:size(curAmpVar,3)
            aTmp = curAmpVar(:,:,year);
            aTmp(waterGrid) = NaN;
            aTmp = aTmp(latInds,lonInds);
            aFut(:,:,year) = aTmp;
        end
        aFut = squeeze(nanmean(nanmean(aFut,2),1));
        aFut = (aFut-nanmean(aFut)) ./ nanmean(aFut); 
        
        curDVar = squeeze(driverVarFut(:,:,:,m));
        dFut = [];
        for year = 1:size(curDVar,3)
            dTmp = curDVar(:,:,year);
            dTmp(waterGrid) = NaN;
            dTmp = dTmp(latInds,lonInds);
            dFut(:,:,year) = dTmp;
        end
        dFut = squeeze(nanmean(nanmean(dFut,2),1));
        
        
        X = [ones(size(aFut)), dFut];
        b = regress(aFut,X);
        afit = X*b;
        resid = aFut-afit;        
        s = bootstrp(1000, @(bootr)regress(afit+bootr,X),resid);
        slopesFut(rind,m) = nanmean(s(:,2));
        corrFut(rind,m) = corr(aFut, dFut, 'type', 'Spearman');
        
    end

    rind = rind+1;
    
    
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
        t = text(slopesHist(m,2), slopesFut(m,2), num2str(m), 'HorizontalAlignment', 'center', 'Color', color);
        t.FontSize = 30;
        t.FontWeight = 'bold';
    end

    colormap(v3Color);
    caxis([-max(abs(v3ChgSort)) max(abs(v3ChgSort))]);
    cb = colorbar();
    ylabel(cb, 'TXx amplification');

    set(gca, 'FontSize', 40);

    ylabel('Future TXx-EF anom slope');
    ylim([-1.5 1]);
    set(gca, 'YTick', -1.5:.5:1);
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
