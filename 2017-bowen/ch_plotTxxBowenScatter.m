load lat;
load lon;
load waterGrid;
waterGrid = logical(waterGrid);

showOutliers = true;
plotModels = false;
useSeasonalAmp = false;
useTxxSeasonalAmp = false;

var1 = 'cloudSWChg';
var1Months = [6 7 8];
v1XStr = 'JJA cloud SW chg (W/m^2)';
v1XLim = [-20 20];
v1XTick = -20:5:20;
v1AbsoluteStr = '-absolute';
v1FileStr = [var1 v1AbsoluteStr '-JJA'];

showVar3 = false;
% shown in colors
var3 = 'hflsChg';
var3Months = [6 7 8];
v3YLim = [0 40];
v3YTicks = 0:10:40;
v3AbsoluteStr = '-absolute';
v3FileStr = [var3 v3AbsoluteStr '-JJA'];
v3ColorOffset = 15;
v3Color = brewermap(v3ColorOffset + 25, 'Reds');

scatterPlots = true;
saveScatter = false;
globalCorrMap = false;

% txx amp
load e:/data/projects/bowen/derived-chg/txxAmp-clouds.mat;
ampVar = amp;

load(['e:/data/projects/bowen/derived-chg/' var1 v1AbsoluteStr '']);
eval(['v1 = ' var1 ';']);
v1(v1>1000 | v1<-1000) = NaN;

load(['e:/data/projects/bowen/derived-chg/' var3 v3AbsoluteStr '']);
eval(['v3 = ' var3 ';']);
v3(v3>1000 | v3 < -1000) = NaN;

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
load('2017-bowen/hottest-season-ncep.mat');

if scatterPlots
    % loop over regions
    for region = [2 4 10]%[2 4 7 10]
        % select lat lon coords for region
        [latInds, lonInds] = latLonIndexRange({lat, lon, []}, regions(region, [1 2]), regions(region, [3 4]));

        % select amp for region for all models
        regionAmp = squeeze(nanmean(nanmean(ampVar(latInds, lonInds, :))));

        v1Chg = squeeze(nanmean(nanmean(nanmean(v1(latInds, lonInds, :, var1Months), 4), 2), 1));
        
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
            ampOutlierStdMult = 2;
            v1OutlierStdMult = 2;

            v1Outliers = find(v1Chg > nanstd(v1Chg)*v1OutlierStdMult+nanmean(v1Chg) | ...
                                 v1Chg < -nanstd(v1Chg)*v1OutlierStdMult+nanmean(v1Chg));
            ampOutliers = find(regionAmp > nanstd(regionAmp)*ampOutlierStdMult+nanmean(regionAmp) | ...
                               regionAmp < -nanstd(regionAmp)*ampOutlierStdMult+nanmean(regionAmp));

            outliers = union(v1Outliers, ampOutliers);
            v1ChgNoOutliers = v1Chg;
            v1ChgNoOutliers(outliers) = [];
            regionAmpNoOutliers = regionAmp;
            regionAmpNoOutliers(outliers) = [];
        end

        figure('Color', [1,1,1]);
        hold on;
        box on;
        axis square;
        grid on;
        
        v3ChgSort = sort(v3Chg);
        
        % loop over all models
        for m = 1:length(v1Chg)
            
            color = v3Color(v3ColorOffset+find(v3ChgSort == v3Chg(m)), :);
            
            if showVar3
                t = text(v1Chg(m), regionAmp(m), num2str(m), 'HorizontalAlignment', 'center', 'Color', color);
            else
                t = text(v1Chg(m), regionAmp(m), num2str(m), 'HorizontalAlignment', 'center', 'Color', 'k');
            end
            t.FontSize = 18;
        end


        if showOutliers
            f = fit(v1ChgNoOutliers, regionAmpNoOutliers, 'poly1');
            pNoOutliers = plot([min(v1ChgNoOutliers) max(v1ChgNoOutliers)], [f(min(v1ChgNoOutliers)) f(max(v1ChgNoOutliers))], '--b', 'LineWidth', 2);
            cNoOutliers = confint(f);
            sigOutliers = 'Not sig';
            if sign(cNoOutliers(1,1)) == sign(cNoOutliers(2,1))
                sigOutliers = 'Sig';
            end
        end

        f = fit(v1Chg, regionAmp, 'poly1');
        pAll = plot([min(v1Chg) max(v1Chg)], [f(min(v1Chg)) f(max(v1Chg))], '--', 'Color', [.6 .6 .6], 'LineWidth', 2);
        cAll = confint(f);
        sigAll = 'Not sig';
        if sign(cAll(1,1)) == sign(cAll(2,1))
            sigAll = 'Sig';
        end
        
        set(gca, 'FontSize', 40);
        
        xlabel(v1XStr);
        xlim(v1XLim);
        set(gca, 'XTick', v1XTick);

        ylabel(['TXx amplification (' char(176) ')']);
        ylim([-2 5.5]);
        set(gca, 'YTick', -2:5.5);
        title([regionNames{region}]);
        legend([pAll pNoOutliers], {['All: (' sigAll ')'], ['No outliers: (' sigOutliers ')']});
        set(gcf, 'Position', get(0,'Screensize'));

        tempVar = 'txx';
        
        if saveScatter
            export_fig(['txx-amp-' v1FileStr '-scatter-' num2str(region) '.eps']);
            close all;
        end
    end
end

if globalCorrMap
    
    corrMap = [];
    corrSig = [];
    
    driverWarm = zeros(size(lat,1),size(lat,2),size(ampVar,3));
    driverWarm(driverWarm==0) = NaN;
    
    for xlat = 1:size(lat, 1)
        for ylon = 1:size(lat, 2)
            if waterGrid(xlat, ylon)
                corrMap(xlat, ylon) = NaN;
                corrSig(xlat, ylon) = 0;
                continue;
            end
                       
            %select txx/bowen for region for all models
            regionAmp = squeeze(ampVar(xlat, ylon, :));

            %and bowen
            regionDriverChg = squeeze(nanmean(driverVar(xlat, ylon, :, seasons(hottestSeason(xlat, ylon), :)), 4));
            driverWarm(xlat, ylon, :) = regionDriverChg;
            
            nn = find(~isnan(regionDriverChg) & ~isnan(regionAmp));
            regionAmp = regionAmp(nn);
            regionDriverChg = regionDriverChg(nn);

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
                v1ChgNoOutliers(outliers) = [];
                regionAmpNoOutliers = regionAmp;
                regionAmpNoOutliers(outliers) = [];
            end
%             
%             if showOutliers
%                 f = fit(regionAmpNoOutliers, regionDriverChgNoOutliers, 'poly1');
%                 c = confint(f);
%             else
%                 f = fit(regionAmp, regionDriverChg, 'poly1');
%                 c = confint(f);
%                 
%             end
%             corrMap(xlat, ylon) = f.p1;
%             corrSig(xlat, ylon) = sign(c(1,1)) == sign(c(2,1));
            
            if showOutliers
                corrMap(xlat, ylon) = corr(regionAmpNoOutliers, v1ChgNoOutliers);
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
    if useSeasonalAmp
        tempVar = 'tx-seasonal';
    end

    
    if useHfss
        title = ['TXx chg - hfss chg corr'];
        file = [tempVar '-hfss-chg-corr.eps'];
    elseif useHfls
        title = ['TXx chg - hfls chg corr'];
        file = [tempVar '-hfls-chg-corr.eps'];
    elseif useRsds
        title = ['TXx chg - rsds-chg corr'];
        file = [tempVar '-rsds-chg-corr.eps'];
    else
        title = ['TXx chg - Bowen chg corr'];
        file = [tempVar '-bowen-chg-corr.eps'];
    end
    
    sigChg(1:15,:) = 0;
    sigChg(80:90,:) = 0;
    
    saveData = struct('data', {result}, ...
                      'plotRegion', 'world', ...
                      'plotRange', [-1 1], ...
                      'cbXTicks', -1:.25:1, ...
                      'plotTitle', title, ...
                      'fileTitle', file, ...
                      'plotXUnits', ['Slope'], ...
                      'blockWater', true, ...
                      'statData', corrSig, ...
                      'stippleInterval', 5, ...
                      'colormap', brewermap([], '*RdBu'), ...
                      'boxCoords', {regions([2,4,7], :)});
                  
                  
                      
    plotFromDataFile(saveData);
end