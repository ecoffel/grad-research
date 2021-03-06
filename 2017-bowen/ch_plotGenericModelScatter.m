load lat;
load lon;
load waterGrid;
waterGrid = logical(waterGrid);

showOutliers = true;
v1AbsoluteStr = '';
v2AbsoluteStr = '';
v3AbsoluteStr = '';

var1 = 'netSurfDownRadChgWarmTxxAnom';
var1Months = [1];
v1XStr = 'RSDS TXx rel change (W/m^2)';
v1XLim = [-30 30];
v1XTick = -30:10:30;
v1FileStr = [var1 v1AbsoluteStr];

var2 = 'efChgWarmTxxAnom';
var2Months = [1];
v2YStr = 'EF TXx rel change (Fraction)';
v2YLim = [-.075 .075];
v2YTick = -.075:.025:.075;
% v2YLim = [-2 2];
% v2YTick = -.075:.025:.075;
v2FileStr = [var2 v2AbsoluteStr];

showVar3 = true;
% shown in colors
var3 = 'txxAmp';
var3Months = [1];
v3FileStr = [var3 v3AbsoluteStr '-JJA'];
v3YStr = ['TXx amplification (' char(176) 'C)'];
v3ColorOffset = 0;
v3Colormap = '*RdBu';
v3FileStr = [var3];

regionIds = [4];

scatterPlots = true;
saveScatter = false;
showFit = false;

globalCorrMap = false;
plotModels = false;

% load selected variables
load(['e:/data/projects/bowen/derived-chg/' var1 v1AbsoluteStr '']);
eval(['v1 = ' var1 ';']);
%v1 = v1 .* 3600 .* 24;

load(['e:/data/projects/bowen/derived-chg/' var2 v2AbsoluteStr '']);
eval(['v2 = ' var2 ';']);
v2(v2>1000 | v2<-1000) = NaN;
%v2 = v2 .* 3600 .* 24;

load(['e:/data/projects/bowen/derived-chg/' var3 v3AbsoluteStr '']);
eval(['v3 = amp;']);
v3(v3>1000 | v3 < -1000) = NaN;

load e:/data/projects/bowen/derived-chg/txxAmp.mat;
txxAmp = amp;

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
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

load('2017-bowen/hottest-season-txx-rel-cmip5.mat');
seasons = [[12 1 2];
           [3 4 5];
           [6 7 8];
           [9 10 11]];
       
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

if scatterPlots
    % loop over regions
    for region = regionIds
        % select lat lon coords for region
        [latInds, lonInds] = latLonIndexRange({lat, lon, []}, regions(region, [1 2]), regions(region, [3 4]));

        if length(var1Months) == 0
            var1Months = round(squeeze(nanmean(nanmean(hottestSeason(latInds, lonInds, :)))));
            var1Months = [var1Months-1 var1Months var1Months+1];
            var1Months(var1Months == 0) = 12;
            var1Months(var1Months == 13) = 1;
        end
        
        % select txx/bowen for region for all models
        v1Chg = squeeze(nanmean(nanmean(nanmean(v1(latInds, lonInds, :, var1Months), 4), 2), 1));

        if length(var2Months) == 0
            var2Months = round(squeeze(nanmean(nanmean(hottestSeason(latInds, lonInds, :)))));
            var2Months = [var2Months-1 var2Months var2Months+1];
            var2Months(var2Months == 0) = 12;
            var2Months(var2Months == 13) = 1;
        end
        
        % and bowen
        v2Chg = squeeze(nanmean(nanmean(nanmean(v2(latInds, lonInds, :, var2Months), 4), 2), 1));
        
        if showVar3
            v3Chg = squeeze(nanmean(nanmean(nanmean(v3(latInds, lonInds, :, var3Months), 4), 2), 1));
        else
            v3Chg = ones(size(v2Chg));
        end

        nn = find(~isnan(v3Chg) & ~isnan(v2Chg) & ~isnan(v1Chg));
        v1Chg = v1Chg(nn);
        v2Chg = v2Chg(nn);
        v3Chg = v3Chg(nn);

        if showOutliers
            v1OutlierStdMult = 2;
            v2OutlierStdMult = 2;

            v2Outliers = find(v2Chg > nanstd(v2Chg)*v2OutlierStdMult+nanmean(v2Chg) | ...
                                 v2Chg < -nanstd(v2Chg)*v2OutlierStdMult+nanmean(v2Chg));
            v1Outliers = find(v1Chg > nanstd(v1Chg)*v1OutlierStdMult+nanmean(v1Chg) | ...
                               v1Chg < -nanstd(v1Chg)*v1OutlierStdMult+nanmean(v1Chg));

            outliers = union(v2Outliers, v1Outliers);
            regionV2ChgNoOutliers = v2Chg;
            %regionV2ChgNoOutliers(outliers) = [];
            regionV1NoOutliers = v1Chg;
            %regionV1NoOutliers(outliers) = [];
        end

        figure('Color', [1,1,1]);
        hold on;
        box on;
        axis square;
        grid on;

        v3ChgSort = sort(v3Chg);
        
        v3Color = brewermap(length(v3ChgSort)*2, v3Colormap) .* .7;
        v3ZeroInd = find(abs(v3ChgSort) == min(abs(v3ChgSort)));
        
        plot([-100 100], [0 0], '--k');
        plot([0 0], [-100 100], '--k');
        
        % loop over all models
        for m = 1:length(v1Chg)
            
            color = v3Color(length(v3ChgSort)-v3ZeroInd+find(v3ChgSort == v3Chg(m))-1, :);
            
                if showVar3
                    t = text(v1Chg(m), v2Chg(m), num2str(m), 'HorizontalAlignment', 'center', 'Color', color);
                else
                    t = text(v1Chg(m), v2Chg(m), num2str(m), 'HorizontalAlignment', 'center', 'Color', 'k');
                end
            
            t.FontSize = 30;
            t.FontWeight = 'bold';
        end

        if showFit
            if showOutliers
                [f,gof,out] = fit(regionV1NoOutliers, regionV2ChgNoOutliers, 'poly1');
                pNoOutliers = plot([min(regionV1NoOutliers) max(regionV1NoOutliers)], [f(min(regionV1NoOutliers)) f(max(regionV1NoOutliers))], '--b', 'LineWidth', 2);
                legText = sprintf('R^2 = %.2f\n', gof.rsquare);
            end
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
        xlabel(v1XStr);
        xlim(v1XLim);
        set(gca, 'XTick', v1XTick);

        %title([regionNames{region}]);
        if showFit
            legend([pNoOutliers], {legText});
        end
        set(gcf, 'Position', get(0,'Screensize'));
        
        if saveScatter
            export_fig([v1FileStr '-' v2FileStr '-' v3FileStr '-scatter-' num2str(region) '.eps']);
            close all;
        end
    end
end

if globalCorrMap
    
    corrMap = [];
    corrSig = [];
    
    for xlat = 1:size(lat, 1)
        for ylon = 1:size(lat, 2)
            if waterGrid(xlat, ylon)
                corrMap(xlat, ylon) = NaN;
                corrSig(xlat, ylon) = 0;
                continue;
            end
            
            v1Chg = squeeze(nanmean(v1(xlat, ylon, :, seasons(hottestSeason(xlat, ylon), :)), 4));

            v2Chg = squeeze(nanmean(v2(xlat, ylon, :, seasons(hottestSeason(xlat, ylon), :)), 4));

            nn = find(~isnan(v2Chg) & ~isnan(v1Chg) & ~isinf(v2Chg) & ~isinf(v1Chg));
            v1Chg = v1Chg(nn);
            v2Chg = v2Chg(nn);

            % not all models present... skip
            if length(nn) < size(v1, 3)
                corrMap(xlat, ylon) = NaN;
                corrSig(xlat, ylon) = 0;
                continue;
            end
            
            if showOutliers
                v1OutlierStdMult = 2;
                v2OutlierStdMult = 2;

                v2Outliers = find(v2Chg > nanstd(v2Chg)*v2OutlierStdMult+nanmean(v2Chg) | ...
                                     v2Chg < -nanstd(v2Chg)*v2OutlierStdMult+nanmean(v2Chg));
                v1Outliers = find(v1Chg > nanstd(v1Chg)*v1OutlierStdMult+nanmean(v1Chg) | ...
                                   v1Chg < -nanstd(v1Chg)*v1OutlierStdMult+nanmean(v1Chg));

                outliers = union(v2Outliers, v1Outliers);
                regionV2ChgNoOutliers = v2Chg;
                regionV2ChgNoOutliers(outliers) = [];
                regionV1NoOutliers = v1Chg;
                regionV1NoOutliers(outliers) = [];
            end
            
            if showOutliers
                f = fit(regionV1NoOutliers, regionV2ChgNoOutliers, 'poly1');
                c = confint(f);
            else
                f = fit(v1Chg, v2Chg, 'poly1');
                c = confint(f);
                
            end
            corrMap(xlat, ylon) = f.p1;
            corrSig(xlat, ylon) = sign(c(1,1)) == sign(c(2,1));
            
%             if showOutliers
%                 corrMap(xlat, ylon) = corr(regionTxxNoOutliers, regionBowenChgNoOutliers);
%             else
%                 corrMap(xlat, ylon) = corr(regionTxx, regionBowenChg);
%             end
        end
    end
    
    
    corrSig(1:15,:) = 0;
    corrSig(75:90,:) = 0;
    
    result = {lat, lon, corrMap};

    
    title = 'clt chg - hfls chg';
    file = 'corr-clt-chg-rad-net-warm.eps';
%     sigChg = txxAmp < 0.5;
%     sigChg(1:15,:) = 0;
%     sigChg(80:90,:) = 0;
    
    saveData = struct('data', {result}, ...
                      'plotRegion', 'world', ...
                      'plotRange', [-5 5], ...
                      'cbXTicks', -5:1:5, ...
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