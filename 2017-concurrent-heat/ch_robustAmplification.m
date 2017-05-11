
% should we look at changes in monthly temperature or changes in the annual
% maximum vs. the mean daily maximum
monthly = true;

load lat;
load lon;

load waterGrid;
waterGrid = logical(waterGrid);

if monthly
    models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
                      'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                      'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                      'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc-esm', ...
                      'mpi-esm-mr', 'mri-cgcm3'};



    % monthly-mean-max or monthly-max
    tempMetric = 'monthly-max';

    tasmaxBaseDir = '2017-concurrent-heat\tasmax\';
    tasmaxChg = [];

    % load temp change data for all models
    for m = 1:length(models)
        % load pre-computed monthly change data for tasmax under rcp85 in 2070-2080
        if exist([tasmaxBaseDir 'chgData-cmip5-seasonal-' tempMetric '-' models{m} '-rcp85-2070-2080.mat'], 'file')
            load([tasmaxBaseDir 'chgData-cmip5-seasonal-' tempMetric '-' models{m} '-rcp85-2070-2080.mat']);
            curTasmaxChg = chgData;

            % NaN-out all water gridcells
            for month = 1:size(curTasmaxChg, 3)
                % tasmax change
                curGrid = curTasmaxChg(:, :, month);
                curGrid(waterGrid) = NaN;
                curTasmaxChg(:, :, month) = curGrid;
            end

            tasmaxChg(:, :, m, :) = curTasmaxChg;
        end

        clear curTasmaxRcp85;
    end

    % compute amplification - difference between month that warms the most and
    % month that warms the least
    amp = nanmax(tasmaxChg, [], 4) - nanmin(tasmaxChg, [], 4);
else
    load chg-data\chgData-cmip5-ann-max-rcp85-2070-2080;
    annMax = chgData;
    
    load chg-data\chgData-cmip5-daily-max-rcp85-2070-2080;
    dailyMax = chgData;
    
    amp = annMax - dailyMax;
end

% threshold in deg C to test for model agreement, if set to -1, search for
% max threshold that still allows for specified level of model agreement
ampThresh = -1;

% percentage of models that must agree on amplification
ampAgreement = 66;

% how many models agree on change greater than threshold
ampLevel = zeros(size(lat, 1), size(lat, 2));
ampLevel(ampLevel == 0) = NaN;

for xlat = 1:size(amp, 1)
    for ylon = 1:size(amp, 2)
        data = squeeze(amp(xlat, ylon, :));
        
        % count how many models find > thresh amplification for this grid
        % cell
        if ampThresh ~= -1
            ampLevel(xlat, ylon) = length(data(data > ampThresh));
        else
            % loop over all possible amplification levels
            for curAmpLevel = 0:1:5
                % find number of models exceeding this amp level
                numModels = length(find(data(data > curAmpLevel)));
                
                % if enough models agree, set amp level for this gridcell -
                % keep resetting until we find a level that doesn't have
                % required model agreement
                if numModels > (ampAgreement / 100.0) * size(amp, 3)
                    ampLevel(xlat, ylon) = curAmpLevel;
                end
                
            end
        end
    end
end

% convert to percentage of mondels
%ampLevel = ampLevel ./ size(amp, 3) .* 100;

% don't display below 2/3 agreement
%ampCount(ampCount < 66) = NaN;

result = {lat, lon, ampLevel};

saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [0 5], ...
                  'cbXTicks', [0:5], ...
                  'plotTitle', ['Amplification, ' num2str(ampAgreement) '% model agreement'], ...
                  'fileTitle', ['ampAgreement-rcp85-' num2str(size(amp, 3)) '-cmip5-' num2str(ampAgreement) '.png'], ...
                  'plotXUnits', ['Amplification (' char(176) 'C)'], ...
                  'blockWater', true, ...
                  'magnify', '2');
plotFromDataFile(saveData);
%plotModelData({lat, lon, nanmean(amp, 3)}, 'world', 'caxis', [-4 4]);

