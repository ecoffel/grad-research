
% should we look at changes in monthly temperature or changes in the annual
% maximum vs. the mean daily maximum
monthly = false;

showAllModels = true;

load lat;
load lon;

load waterGrid;
waterGrid = logical(waterGrid);

modelSubset = 'clouds';

rcp = 'rcp85';
timePeriod = '2060-2080';
% 
modelsAll = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
          
modelsClouds = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};


if strcmp(modelSubset, 'clouds')
    models = modelsClouds;
elseif strcmp(modelSubset, 'all')
    models = modelsAll;
end
            
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

% first change variable
chg1 = [];
% second change variable - subtracted from frst
chg2 = [];

for m = 1:length(models)
    
    % load and process change 1
    load(['e:/data/projects/bowen/temp-chg-data/chgData-cmip5-ann-max-' models{m} '-' rcp '-' timePeriod '.mat']);
    curChg = chgData;

    % NaN-out all water gridcells
    for month = 1:size(curChg, 3)
        % tasmax change
        curGrid = curChg(:, :, month);
        curGrid(waterGrid) = NaN;
        curChg(:, :, month) = curGrid;
    end

    chg1(:, :, m, :) = curChg;

    clear curChg chgData;

    load(['e:/data/projects/bowen/temp-chg-data/chgData-cmip5-warm-season-tx-' models{m} '-' rcp '-' timePeriod '.mat']);
    curChg = chgData;

    % NaN-out all water gridcells
    for month = 1:size(curChg, 3)
        % tasmax change
        curGrid = curChg(:, :, month);
        curGrid(waterGrid) = NaN;
        curChg(:, :, month) = curGrid;
    end

    chg2(:, :, m, :) = curChg;

    clear curChg chgData;
end

ampSig = [];

for xlat = 1:size(chg1, 1)
    for ylon = 1:size(chg1, 2)
        if waterGrid(xlat, ylon)
            ampSig(xlat, ylon) = NaN;
            continue;
        end
        %if nanmedian(squeeze(chg1(xlat, ylon, :))) > nanmedian(squeeze(chg2(xlat, ylon, :)))
            ampSig(xlat, ylon) = kstest2(squeeze(chg1(xlat, ylon, :)), squeeze(chg2(xlat, ylon, :)));
        %end
    end
end

%     result = {lat, lon, ampLevel};
% 
%     saveData = struct('data', {result}, ...
%                       'plotRegion', 'world', ...
%                       'plotRange', [ampLevels(1) ampLevels(end)], ...
%                       'cbXTicks', ampLevels, ...
%                       'plotTitle', ['Amplification'], ...
%                       'fileTitle', ['ampAgreement-' rcp '-' num2str(size(amp, 3)) '-cmip5-' chgMetric '-' modelSubset '-' timePeriod '.eps'], ...
%                       'plotXUnits', ['Amplification (' char(176) 'C)'], ...
%                       'blockWater', true, ...
%                       'colormap', brewermap([],'*RdBu'), ...
%                       'statData', ampAgree, ...
%                       'boxCoords', {regions([2,4,7,10], :)});
%     plotFromDataFile(saveData);
% end
% %plotModelData({lat, lon, nanmean(amp, 3)}, 'world', 'caxis', [-4 4]);
% 
