load lat;
load lon;
load waterGrid;
waterGrid = logical(waterGrid);

showOutliers = true;

var1 = 'mrsos';
var1Months = [6 7 8];
v1XStr = 'JJA pr change (%)';
v1XLim = [-50 50];
v1XTick = -50:25:50; %[-25 0 25 50 75 100];
v1FileStr = [var1 '-JJA'];

var2 = 'hfss';
var2Months = [6 7 8];
v2YStr = 'JJA hfss change (%)';
v2YLim = [-25 125];
v2YTick = -25:25:125;
v2FileStr = [var2 '-JJA'];

regionIds = [2];

scatterPlots = true;
saveScatter = true;
globalCorrMap = false;
plotModels = false;


% load selected variables
load(['e:/data/projects/bowen/derived-chg/' var1 '-chg-all']);
eval(['v1 = ' var1 'Chg;']);

load(['e:/data/projects/bowen/derived-chg/' var2 '-chg-all']);
eval(['v2 = ' var2 'Chg;']);
v2(v2>1000 | v2<-1000) = NaN;

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
                'North Africa'};
regionAb = {'world', ...
            'us-east', ...
            'us-se', ...
            'europe', ...
            'med', ...
            'sa-n', ...
            'amazon', ...
            'africa-cent', ...
            'n-africa'};
            
regions = [[[-90 90], [0 360]]; ...             % world
           [[30 42], [-91 -75] + 360]; ...     % eastern us
           [[30 41], [-95 -75] + 360]; ...      % southeast us
           [[45, 55], [10, 35]]; ...            % Europe
           [[35 50], [-10+360 45]]; ...        % Med
           [[5 20], [-90 -45]+360]; ...         % Northern SA
           [[-10, 1], [-75, -53]+360]; ...      % Amazon
           [[-10 10], [15, 30]]; ...            % central africa
           [[15 30], [-4 29]]];                 % north africa

       
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

        % select txx/bowen for region for all models
        v1Chg = squeeze(nanmean(nanmean(nanmean(v1(latInds, lonInds, :, var1Months), 4), 2), 1));

        % and bowen
        v2Chg = squeeze(nanmean(nanmean(nanmean(v2(latInds, lonInds, :, var2Months), 4), 2), 1));

        nn = find(~isnan(v2Chg) & ~isnan(v1Chg));
        v1Chg = v1Chg(nn);
        v2Chg = v2Chg(nn);

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

        figure('Color', [1,1,1]);
        hold on;
        box on;
        axis square;
        grid on;

        % loop over all models
        for m = 1:length(v1Chg)
            %plot(regionTxx(m), regionBowenChg(m), 'o', 'MarkerSize', 2 + abs(20*regionBowenTxCorr(m)), 'LineWidth', 2);
            if showOutliers && length(find(v1Outliers == m)) > 0
                t = text(v1Chg(m), v2Chg(m), num2str(m), 'HorizontalAlignment', 'center', 'Color', 'r');
            elseif showOutliers && length(find(v2Outliers == m)) > 0
                t = text(v1Chg(m), v2Chg(m), num2str(m), 'HorizontalAlignment', 'center', 'Color', [67, 186, 86]./255.0);
            elseif showOutliers && length(find(v2Outliers == m)) > 0 && length(find(v1Outliers == m)) > 0
                t = text(v1Chg(m), v2Chg(m), num2str(m), 'HorizontalAlignment', 'center', 'Color', 'm');
            else
                t = text(v1Chg(m), v2Chg(m), num2str(m), 'HorizontalAlignment', 'center', 'Color', 'k');
            end
            t.FontSize = 18;
        end

        if showOutliers
            f = fit(regionV1NoOutliers, regionV2ChgNoOutliers, 'poly1');
            pNoOutliers = plot([min(regionV1NoOutliers) max(regionV1NoOutliers)], [f(min(regionV1NoOutliers)) f(max(regionV1NoOutliers))], '--b', 'LineWidth', 2);
            cNoOutliers = confint(f);
            cOutlierSigStr = 'Not sig';
            if sign(cNoOutliers(1,1)) == sign(cNoOutliers(2,1))
                cOutlierSigStr = 'Sig';
            end
        end

        f = fit(v1Chg, v2Chg, 'poly1');
        pAll = plot([min(v1Chg) max(v1Chg)], [f(min(v1Chg)) f(max(v1Chg))], '--', 'Color', [.6 .6 .6], 'LineWidth', 2);
        cAll = confint(f);
        cAllSigStr = 'Not sig';
        if sign(cAll(1,1)) == sign(cAll(2,1))
            cAllSigStr = 'Sig';
        end

        set(gca, 'FontSize', 40);
        
        ylabel(v2YStr);
        ylim(v2YLim);
        set(gca, 'YTick', v2YTick);
        
        xlabel(v1XStr);
        xlim(v1XLim);
        set(gca, 'XTick', v1XTick);

        title([regionNames{region}]);
        legend([pAll pNoOutliers], {['All: (' cAllSigStr ')'], ['No outliers: (' cOutlierSigStr ')']});
        set(gcf, 'Position', get(0,'Screensize'));
        
        if saveScatter
            export_fig([v1FileStr '-' v2FileStr '-scatter-' num2str(region) '.eps']);
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
            
            % select txx/bowen for region for all models
            v1Chg = squeeze(txxAmp(xlat, ylon, :));

            % and bowen
            v2Chg = squeeze(bowenChg(xlat, ylon, :));

            nn = find(~isnan(v2Chg) & ~isnan(v1Chg));
            v1Chg = v1Chg(nn);
            v2Chg = v2Chg(nn);

            if length(nn) < 10
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
    else
        title = ['TXx chg - Bowen chg corr'];
        file = [tempVar '-bowen-chg-corr.eps'];
    end
    
%     sigChg = txxAmp < 0.5;
%     sigChg(1:15,:) = 0;
%     sigChg(80:90,:) = 0;
    
    saveData = struct('data', {result}, ...
                      'plotRegion', 'world', ...
                      'plotRange', [-20 20], ...
                      'cbXTicks', -20:5:20, ...
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