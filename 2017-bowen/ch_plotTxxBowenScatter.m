load lat;
load lon;
load waterGrid;
waterGrid = logical(waterGrid);

showOutliers = true;
plotModels = false;
useTxxSeasonalAmp = true;
useTxxChg = false;
useTxWarmAnom = false;
useTxWarmChg = false;

var1 = 'prChgWarmTxxAnom';
var1Months = [1];
v1XStr = ['TXx hfss chg minus warm (W/m^2)'];
v1XLim = [-15 20];
v1XTick = -15:5:20;
v1AbsoluteStr = '';
v1Subset = '';
v1FileStr = [var1 v1AbsoluteStr '-warm'];

showVar3 = false;
% shown in colors
var3 = 'mrsoChgWarmTxxAnom';
v3YStr = ['TXx mrso chg minus warm (%)'];
var3Months = [1];

v3AbsoluteStr = '';
v3FileStr = [var3 v3AbsoluteStr];
v3ColorOffset = 0;
v3Colormap = 'BrBG';

scatterPlots = true;
saveScatter = false;
globalCorrMap = false;
oneToOne = false;

selRegions = [11];

% txx amp
if useTxxSeasonalAmp
    load e:/data/projects/bowen/derived-chg/txxAmpThresh99.mat;
    ampVar = amp;
elseif useTxxChg
    load e:/data/projects/bowen/derived-chg/txxChg.mat;
    ampVar = txxChg;
elseif useTxWarmAnom
    load e:/data/projects/bowen/derived-chg/warmTxAnom.mat;
    ampVar = warmTxAnom;
elseif useTxWarmChg
    load e:/data/projects/bowen/derived-chg/txChgWarm.mat;
    ampVar = txChgWarm;
else
    load e:/data/projects/bowen/derived-chg/txxAmp.mat;
    ampVar = amp;
end

load(['e:/data/projects/bowen/derived-chg/' var1 v1AbsoluteStr v1Subset '']);
eval(['v1 = ' var1 ';']);
v1(v1>1000 | v1<-1000) = NaN;
%v1 = v1 .* 3600 .* 24;

load(['e:/data/projects/bowen/derived-chg/' var3 v3AbsoluteStr '']);
eval(['v3 = ' var3 ';']);
v3(v3>1000 | v3 < -1000) = NaN;
%v3 = v3 .* 3600 .* 24;
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
                'South Africa'};
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
            's-africa'};
            
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
           [[-24 -8], [14 40]]];                      % south africa

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

seasons = [[12 1 2];
           [3 4 5];
           [6 7 8];
           [9 10 11]];

% load hottest seasons for each grid cell
load('2017-bowen/hottest-season-txx-rel-cmip5.mat');

if scatterPlots
    % loop over regions
    for region = selRegions%[2 4 7 10]
        % select lat lon coords for region
        [latInds, lonInds] = latLonIndexRange({lat, lon, []}, regions(region, [1 2]), regions(region, [3 4]));

        % select amp for region for all models
        regionAmp = squeeze(nanmean(nanmean(ampVar(latInds, lonInds, :))));

        if length(var1Months) == 0
            var1Months = round(squeeze(nanmean(nanmean(hottestSeason(latInds, lonInds, :)))));
            var1Months = [var1Months-1 var1Months var1Months+1];
            var1Months(var1Months == 0) = 12;
            var1Months(var1Months == 13) = 1;
        end
        
        v1Chg = squeeze(nanmean(nanmean(nanmean(v1(latInds, lonInds, :, var1Months), 4), 2), 1));
        
        if length(var3Months) == 0
            var3Months = round(squeeze(nanmean(nanmean(hottestSeason(latInds, lonInds, :)))));
            var3Months = [var3Months-1 var3Months var3Months+1];
            var3Months(var3Months == 0) = 12;
            var3Months(var3Months == 13) = 1;
        end
        
        if showVar3
            v3Chg = squeeze(nanmean(nanmean(nanmean(v3(latInds, lonInds, :, var3Months), 4), 2), 1));
        else
            v3Chg = ones(size(v1Chg));
        end

        nn = find(~isnan(v3Chg) & ~isnan(v1Chg) & ~isnan(regionAmp));
        regionAmp = regionAmp(nn);
        v1Chg = v1Chg(nn);
        v3Chg = v3Chg(nn);
        
        if showOutliers
            ampOutlierStdMult = 5;
            v1OutlierStdMult = 3;

            v1Outliers = find(v1Chg > nanstd(v1Chg)*v1OutlierStdMult+nanmean(v1Chg) | ...
                                 v1Chg < -nanstd(v1Chg)*v1OutlierStdMult+nanmean(v1Chg));
            ampOutliers = find(regionAmp > nanstd(regionAmp)*ampOutlierStdMult+nanmean(regionAmp) | ...
                               regionAmp < -nanstd(regionAmp)*ampOutlierStdMult+nanmean(regionAmp));

            outliers = union(v1Outliers, ampOutliers);
            v1ChgNoOutliers = v1Chg;
            %v1ChgNoOutliers(outliers) = [];
            regionAmpNoOutliers = regionAmp;
            %regionAmpNoOutliers(outliers) = [];
            %v3Chg(outliers) = [];
        end

        figure('Color', [1,1,1]);
        hold on;
        box on;
        axis square;
        grid on;
        
        v3ChgSort = sort(v3Chg);
        
        v3Color = brewermap(length(v3ChgSort)*2, v3Colormap) .* .7;
        v3ZeroInd = find(abs(v3ChgSort) == min(abs(v3ChgSort)));
        
        % loop over all models
        for m = 1:length(v1ChgNoOutliers)
            
            color = v3Color(length(v3ChgSort)-v3ZeroInd+find(v3ChgSort == v3Chg(m))-1, :);
            
            if showVar3
                t = text(v1ChgNoOutliers(m), regionAmpNoOutliers(m), num2str(m), 'HorizontalAlignment', 'center', 'Color', color);
            else
                t = text(v1ChgNoOutliers(m), regionAmpNoOutliers(m), num2str(m), 'HorizontalAlignment', 'center', 'Color', 'k');
            end
            t.FontSize = 26;
        end

        if oneToOne
            plot([-20 20], [-20 20], '--', 'Color', [.6 .6 .6], 'LineWidth', 2);
        end
        
        if showOutliers
            [f,gof,out] = fit(v1ChgNoOutliers, regionAmpNoOutliers, 'poly1');
            cNoOutliers = confint(f);
            pNoOutliers = plot([min(v1ChgNoOutliers) max(v1ChgNoOutliers)], [f(min(v1ChgNoOutliers)) f(max(v1ChgNoOutliers))], '--b', 'LineWidth', 2);
 
            if showVar3
                pc = partialcorr([regionAmpNoOutliers v1ChgNoOutliers], v3Chg);
                legText = sprintf('Partial correlation = %.2f\n', pc(2,1));
            else
                pc = corr(regionAmpNoOutliers, v1ChgNoOutliers);
                legText = sprintf('Correlation = %.2f\n', pc);
            end
        end

        f = fit(v1Chg, regionAmp, 'poly1');
%        pAll = plot([min(v1Chg) max(v1Chg)], [f(min(v1Chg)) f(max(v1Chg))], '--', 'Color', [.6 .6 .6], 'LineWidth', 2);
        cAll = confint(f);
        sigAll = 'Not sig';
        if sign(cAll(1,1)) == sign(cAll(2,1))
            sigAll = 'Sig';
        end
        
        set(gca, 'FontSize', 40);
        
        xlabel(v1XStr);
        xlim(v1XLim);
        set(gca, 'XTick', v1XTick);

        if useTxxSeasonalAmp
            if region == 1
                ylim([-1 1]);
                set(gca, 'YTick', -1:.5:1);
            elseif region == 7
                ylim([-4 5]);
                set(gca, 'YTick', -4:5);
            else
                ylim([-2 3]);
                set(gca, 'YTick', -2:3);
            end
            ylabel(['TXx - warm Tx (' char(176) 'C)']);
        elseif useTxxChg
            ylabel(['TXx chg (' char(176) 'C)']);
            ylim([-2 12]);
            set(gca, 'YTick', -2:2:12);
        elseif useTxWarmAnom
            ylabel(['Warm season Tx - annual Tx (' char(176) 'C)']);
            ylim([-2 12]);
            set(gca, 'YTick', -2:2:12);
        elseif useTxWarmChg
            ylabel(['Warm season Tx chg (' char(176) 'C)']);
            if region == 7
                ylim([-2 14]);
            set(gca, 'YTick', -2:2:14);
            else
                ylim([-2 12]);
                set(gca, 'YTick', -2:2:12);
            end
        else
            ylabel(['TXx amplification (' char(176) 'C)']);
            ylim([-2 5.5]);
            set(gca, 'YTick', -2:5.5);
        end
        
        title([regionNames{region}]);
        legend([pNoOutliers], {[legText]});
        set(gcf, 'Position', get(0,'Screensize'));

        if showVar3
            colormap(v3Color);
            caxis([-max(abs(v3ChgSort)) max(abs(v3ChgSort))]);
            cb = colorbar();
            ylabel(cb, v3YStr);
        end
        
        tempVar = 'txx';
        
        if saveScatter
            if useTxxSeasonalAmp
                export_fig(['txx-warm-amp-' v1FileStr '-scatter-' num2str(region) '.eps']); 
            elseif useTxxChg
                export_fig(['txx-chg-' v1FileStr '-scatter-' num2str(region) '.eps']);
            elseif useTxWarmAnom
                export_fig(['tx-warm-anom-' v1FileStr '-scatter-' num2str(region) '.eps']);
            elseif useTxWarmChg
                export_fig(['tx-warm-chg-' v1FileStr '-scatter-' num2str(region) '.eps']);
            end
            close all;
        end
    end
end




if globalCorrMap
    
    load hottest-season-txx-rel-cmip5-all-txx.mat;
    
    corrMap = zeros(size(lat,1),size(lat,2));
    corrSig = zeros(size(lat,1),size(lat,2));
    
    driverWarm = zeros(size(lat,1),size(lat,2),size(ampVar,3));
    driverWarm(driverWarm==0) = NaN;
    
    driver2Warm = zeros(size(lat,1),size(lat,2),size(ampVar,3));
    driver2Warm(driver2Warm==0) = NaN;
    
    for xlat = 1:size(lat, 1)
        for ylon = 1:size(lat, 2)
            if waterGrid(xlat, ylon)
                corrMap(xlat, ylon) = NaN;
                corrSig(xlat, ylon) = 0;
                continue;
            end
            
            months = [squeeze(hottestSeason(xlat, ylon, :)-1) squeeze(hottestSeason(xlat, ylon, :)) squeeze(hottestSeason(xlat, ylon, :)+1)];
            months(months == 0) = 12;
            months(months == 13) = 1;

            months(isnan(months(:,1)),1) = mode(months(:,1));
            months(isnan(months(:,2)),2) = mode(months(:,2));
            months(isnan(months(:,3)),3) = mode(months(:,3));
            
            %select txx/bowen for region for all models
            regionAmp = squeeze(ampVar(xlat, ylon, :));

            %and bowen
            regionDriverChg = squeeze(nanmean(v1(xlat, ylon, :, months), 4));
            driverWarm(xlat, ylon, :) = regionDriverChg;
            driver2Warm = squeeze(nanmean(v3(xlat, ylon, :, months), 4));
            
            nn = find(~isnan(regionDriverChg) & ~isnan(regionAmp) & ~isnan(driver2Warm));
            regionAmp = regionAmp(nn);
            regionDriverChg = regionDriverChg(nn);
            regionDriverChg2 = driver2Warm(nn);

            if length(nn) < 10
                corrMap(xlat, ylon) = NaN;
                corrSig(xlat, ylon) = 0;
                continue;
            end
            
            if showOutliers
                ampOutlierStdMult = 2;
                v1OutlierStdMult = 2;

                v1Outliers = find(regionDriverChg > nanstd(regionDriverChg)*v1OutlierStdMult+nanmean(regionDriverChg) | ...
                                     regionDriverChg < -nanstd(regionDriverChg)*v1OutlierStdMult+nanmean(regionDriverChg));
                ampOutliers = find(regionAmp > nanstd(regionAmp)*ampOutlierStdMult+nanmean(regionAmp) | ...
                                   regionAmp < -nanstd(regionAmp)*ampOutlierStdMult+nanmean(regionAmp));

                outliers = union(v1Outliers, ampOutliers);
                v1ChgNoOutliers = regionDriverChg;
                %v1ChgNoOutliers(outliers) = [];
                regionAmpNoOutliers = regionAmp;
                %regionAmpNoOutliers(outliers) = [];
            end
            
            if showOutliers
                %[f,gof,out] = fit(v1ChgNoOutliers, regionAmpNoOutliers, 'poly1');
                pc=partialcorr([regionAmpNoOutliers, v1ChgNoOutliers], regionDriverChg2);
                corrMap(xlat, ylon) = pc(2,1);
            else
                corrMap(xlat, ylon) = corr(regionAmp, regionDriverChg);
            end
            
        end
    end
    
    corrSig = nanmedian(driverWarm, 3) > 1;
    corrSig(1:15,:) = 0;
    corrSig(75:90,:) = 0;
    
    result = {lat, lon, corrMap};

    tempVar = 'txx';

    title = ['TXx amp - hfss/ef corr'];
    file = ['txx-amp-mrso-var.eps'];
    
    sigChg(1:15,:) = 0;
    sigChg(80:90,:) = 0;
    
    saveData = struct('data', {result}, ...
                      'plotRegion', 'world', ...
                      'plotRange', [0 1], ...
                      'cbXTicks', 0:.25:1, ...
                      'plotTitle', title, ...
                      'fileTitle', file, ...
                      'plotXUnits', ['R^2'], ...
                      'blockWater', true, ...
                      'colormap', brewermap([], 'Reds'), ...
                      'boxCoords', {regions([2,4,7], :)});
                  
                  
                      
    plotFromDataFile(saveData);
end