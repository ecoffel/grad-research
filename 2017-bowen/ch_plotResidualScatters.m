load lat;
load lon;
load waterGrid;
waterGrid = logical(waterGrid);

showOutliers = true;
plotModels = false;

var1 = 'rsdsNetChg';
var1Months = [6 7 8];
v1XStr = ['JJA hfss change (W/m^2)'];
v1XLim = [-20 40];
v1XTick = -20:10:40;
v1AbsoluteStr = '-absolute';
v1Subset = '';
v1FileStr = [var1 v1AbsoluteStr '-JJA'];

var2 = 'efChg';
var2Months = [6 7 8];
v2XStr = ['JJA EF change (Fraction)'];
v2XLim = [-.3 .3];
v2XTick = -.3:.1:.3;
v2AbsoluteStr = '-absolute';
v2Subset = '';
v2FileStr = [var2 v2AbsoluteStr '-JJA'];

resid = 1;
saveScatter = false;
selRegions = [10];

load e:/data/projects/bowen/derived-chg/txxTxWarmChg.mat;
ampVar = txxTxWarmChg;

load(['e:/data/projects/bowen/derived-chg/' var1 v1Subset v1AbsoluteStr '']);
eval(['v1 = ' var1 ';']);

load(['e:/data/projects/bowen/derived-chg/' var2 v2AbsoluteStr '']);
eval(['v2 = ' var2 ';']);

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
           [[-10, 7], [-75, -62]+360]; ...      % Amazon
           [[-10 10], [15, 30]]; ...            % central africa
           [[15 30], [-4 29]]; ...              % north africa
           [[22 40], [105 122]]];               % china

seasons = [[12 1 2];
           [3 4 5];
           [6 7 8];
           [9 10 11]];

% load hottest seasons for each grid cell
load('2017-bowen/hottest-season-ncep.mat');

    % loop over regions
    for region = selRegions%[2 4 7 10]
        % select lat lon coords for region
        [latInds, lonInds] = latLonIndexRange({lat, lon, []}, regions(region, [1 2]), regions(region, [3 4]));

        % select amp for region for all models
        regionAmp = squeeze(nanmean(nanmean(ampVar(latInds, lonInds, :))));

        v1Chg = squeeze(nanmean(nanmean(nanmean(v1(latInds, lonInds, :, var1Months), 4), 2), 1));
        v2Chg = squeeze(nanmean(nanmean(nanmean(v2(latInds, lonInds, :, var2Months), 4), 2), 1));
        
        nn = find(~isnan(v2Chg) & ~isnan(v1Chg) & ~isnan(regionAmp));
        regionAmp = regionAmp(nn);
        v1Chg = v1Chg(nn);
        v2Chg = v2Chg(nn);
        
        if showOutliers
            ampOutlierStdMult = 2;
            v1OutlierStdMult = 2;

            v1Outliers = find(v1Chg > nanstd(v1Chg)*v1OutlierStdMult+nanmean(v1Chg) | ...
                                 v1Chg < -nanstd(v1Chg)*v1OutlierStdMult+nanmean(v1Chg));
            ampOutliers = find(regionAmp > nanstd(regionAmp)*ampOutlierStdMult+nanmean(regionAmp) | ...
                               regionAmp < -nanstd(regionAmp)*ampOutlierStdMult+nanmean(regionAmp));

            outliers = union(v1Outliers, ampOutliers);
            v1Chg(outliers) = [];
            v2Chg(outliers) = [];
            regionAmp(outliers) = [];
        end

 
        if showOutliers
            [f,gof,out] = fit(v1Chg, regionAmp, 'poly1');
            scatter(v1Chg,regionAmp)
            legStr = sprintf('R^2 = %.2f\n', gof.rsquare);
            
            
        end
        
        if resid == 1
            residuals = out.residuals;
            scatter(v2Chg,residuals)
            close all;
            [f,gof,out] = fit(v2Chg, residuals, 'poly2');
            
            yLabelStr = ['TXx - warm Tx | SH change (' char(176) 'C)'];
            yLim = [-1 1];
            yTick = -1:.5:1;
            fileTitle = ['txx-warm-amp-' v1FileStr '-resid-hfss-ef-scatter-' num2str(region) '.eps']; 
            
            xLab = v2XStr;
            xLim = v2XLim;
            xTic = v2XTick;
        else
            yLabelStr = ['TXx - warm Tx (' char(176) 'C)'];
            yLim = [-2 3];
            yTick = -2:3;
            fileTitle = ['txx-warm-amp-' v1FileStr '-scatter-' num2str(region) '.eps']; 
            
            xLab = v1XStr;
            xLim = v1XLim;
            xTic = v1XTick;
        end
        
        titleStr = regionNames{region};
        
        plotScatter(v1Chg, regionAmp, v1ChgNoOutliers, f, xLab, xTic, xLim, yLabelStr, yTick, yLim, titleStr, legStr, fileTitle);
    end



function fig = plotScatter(x, y, fitX, fitObj, xLabel, xTicks, xLim, yLabel, yTicks, yLim, titleText, legText, fileTitle)

    figure('Color', [1,1,1]);
    hold on;
    box on;
    axis square;
    grid on;


    % loop over all models
    for m = 1:length(x)
        t = text(x(m), y(m), num2str(m), 'HorizontalAlignment', 'center', 'Color', 'k');
        t.FontSize = 18;
    end

    pAll = plot([min(fitX) max(fitX)], [fitObj(min(fitX)) fitObj(max(fitX))], '--', 'Color', 'b', 'LineWidth', 2);

    set(gca, 'FontSize', 40);

    xlabel(xLabel);
    xlim(xLim);
    set(gca, 'XTick', xTicks);
    
    ylabel(yLabel);
    ylim(yLim);
    set(gca, 'YTick', yTicks);

    title(titleText);
    legend([pAll], {[legText]});
    set(gcf, 'Position', get(0,'Screensize'));

    tempVar = 'txx';

    export_fig([fileTitle '.eps']); 
    close all;
end

