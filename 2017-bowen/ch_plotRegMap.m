load lat;
load lon;
load waterGrid;
waterGrid = logical(waterGrid);

showOutliers = true;
plotModels = false;
useTXxChg = false;
useTxChg = false;
useTxWarmAnom = true;

var1 = 'efHistorical';
var1Addition = '-absolute';

var2 = 'hflsChg';
var2Addition = '-absolute';

var3 = 'efChg';
var3Addition = '-absolute';

selRegions = 10;

% txx amp
if useTXxChg
    load e:/data/projects/bowen/derived-chg/txxChg.mat;
    ampVar = txxChg;
elseif useTxChg
    load e:/data/projects/bowen/derived-chg/txChgWarm.mat;
    ampVar = txChgWarm;
elseif useTxWarmAnom
    load e:/data/projects/bowen/derived-chg/warmTxAnom.mat;
    ampVar = warmTxAnom;
end

load(['e:/data/projects/bowen/derived-chg/' var1 var1Addition]);
eval(['v1=' var1 ';']);

load(['e:/data/projects/bowen/derived-chg/' var2 var2Addition]);
eval(['v2=' var2 ';']);

load(['e:/data/projects/bowen/derived-chg/' var3 var3Addition]);
eval(['v3=' var3 ';']);


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

adjR2 = [];

for xlat = 1:size(ampVar,1)
    for ylon = 1:size(ampVar, 2)
       
        if waterGrid(xlat, ylon)
            adjR2(xlat, ylon) = NaN;
            continue;
        end
        
        curV1 = squeeze(nanmean(v1(xlat, ylon, :, seasons(hottestSeason(xlat,ylon),:)), 4));
        curV2 = squeeze(nanmean(v2(xlat, ylon, :, seasons(hottestSeason(xlat,ylon),:)), 4));
        curV3 = squeeze(nanmean(v3(xlat, ylon, :, seasons(hottestSeason(xlat,ylon),:)), 4));
        curAmp = squeeze(ampVar(xlat, ylon, :));
        
        nn = union(union(union(find(isnan(curV3)), find(isnan(curV2))), find(isnan(curV1))), find(isnan(curAmp)));
        
        curV1(nn) = [];
        curV2(nn) = [];
        curV3(nn) = [];
        curAmp(nn) = [];
        
        %if length(find(sign(curAmp) == sign(nanmedian(curAmp)))) >= .75*length(curAmp) && nanmedian(curAmp) >= .5
            mdl = fitlm([curV1],curAmp);
            adjR2(xlat, ylon) = mdl.Rsquared.Adjusted;
        %else
        %    adjR2(xlat, ylon) = NaN;
        %end
    end
end

result = {lat, lon, adjR2};
plotModelData(result,'world','caxis',[0 1]);
% saveData = struct('data', {result}, ...
%                   'plotRegion', 'world', ...
%                   'plotRange', [0 .75], ...
%                   'cbXTicks', 0:.25:.75, ...
%                   'plotTitle', ['Warm season Tx change explained by ef'], ...
%                   'fileTitle', ['regress-tx-rlus.eps'], ...
%                   'plotXUnits', ['R^2'], ...
%                   'blockWater', true, ...
%                   'colormap', brewermap([],'Blues'), ...
%                   'boxCoords', {regions([2,4,7,10], :)});
% plotFromDataFile(saveData);