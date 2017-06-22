
% should we look at changes in monthly temperature or changes in the annual
% maximum vs. the mean daily maximum
monthly = false;

load lat;
load lon;

load waterGrid;
waterGrid = logical(waterGrid);

% ann-max: change in annual maximum minus change in mean daily maximum
% ann-min: change in annual minimum minus change in mean daily minimum
% ann-max-min: change in annual max minus change in annual min
% daily-max-min: change in daily max minus change in daily min
chgMetric = 'ann-min';


models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
                  'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                  'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                  'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc-esm', ...
                  'mpi-esm-mr', 'mri-cgcm3'};


% if monthly
%     % monthly-mean-max or monthly-max
%     tempMetric = 'monthly-mean-max';
% 
%     tasmaxBaseDir = '2017-concurrent-heat\tasmax\';
%     dailyChg = [];
% 
%     % load temp change data for all models
%     for m = 1:length(models)
%         % load pre-computed monthly change data for tasmax under rcp85 in 2070-2080
%         if exist([tasmaxBaseDir 'chgData-cmip5-seasonal-' tempMetric '-' models{m} '-rcp85-2060-2080.mat'], 'file')
%             load([tasmaxBaseDir 'chgData-cmip5-seasonal-' tempMetric '-' models{m} '-rcp85-2060-2080.mat']);
%             curDailyChg = chgData;
% 
%             % NaN-out all water gridcells
%             for month = 1:size(curDailyChg, 3)
%                 % tasmax change
%                 curGrid = curDailyChg(:, :, month);
%                 curGrid(waterGrid) = NaN;
%                 curDailyChg(:, :, month) = curGrid;
%             end
% 
%             dailyChg(:, :, m, :) = curDailyChg;
%         end
% 
%         clear curTasmaxRcp85;
%     end
% 
%     % compute amplification - difference between month that warms the most and
%     % month that warms the least
%     amp = nanmax(dailyChg, [], 4) - nanmean(dailyChg, 4);
% else

% first change variable
chg1 = [];
% second change variable - subtracted from frst
chg2 = [];

for m = 1:length(models)
    
    % load and process change 1
    if strcmp(chgMetric, 'ann-max')
        load(['2017-concurrent-heat/tasmax/chgData-cmip5-ann-max-' models{m} '-rcp85-2060-2080.mat']);
        curChg = chgData;
    elseif strcmp(chgMetric, 'ann-min')
        load(['2017-concurrent-heat/tasmax/chgData-cmip5-ann-min-' models{m} '-rcp85-2060-2080.mat']);
        curChg = chgData;
    elseif strcmp(chgMetric, 'ann-max-min')
        load(['2017-concurrent-heat/tasmax/chgData-cmip5-ann-max-' models{m} '-rcp85-2060-2080.mat']);
        curChg = chgData;
    elseif strcmp(chgMetric, 'daily-max-min')
        load(['2017-concurrent-heat/tasmax/chgData-cmip5-daily-max-' models{m} '-rcp85-2060-2080.mat']);
        curChg = chgData;
    end

    % NaN-out all water gridcells
    for month = 1:size(curChg, 3)
        % tasmax change
        curGrid = curChg(:, :, month);
        curGrid(waterGrid) = NaN;
        curChg(:, :, month) = curGrid;
    end

    chg1(:, :, m, :) = curChg;


    clear curChg chgData;

    % load and process change 2
    if strcmp(chgMetric, 'ann-max')
        load(['2017-concurrent-heat/tasmax/chgData-cmip5-daily-max-' models{m} '-rcp85-2060-2080.mat']);
        curChg = chgData;
    elseif strcmp(chgMetric, 'ann-min')
        load(['2017-concurrent-heat/tasmax/chgData-cmip5-daily-min-' models{m} '-rcp85-2060-2080.mat']);
        curChg = chgData;
    elseif strcmp(chgMetric, 'ann-max-min')
        load(['2017-concurrent-heat/tasmax/chgData-cmip5-ann-min-' models{m} '-rcp85-2060-2080.mat']);
        curChg = chgData;
    elseif strcmp(chgMetric, 'daily-max-min')
        load(['2017-concurrent-heat/tasmax/chgData-cmip5-daily-min-' models{m} '-rcp85-2060-2080.mat']);
        curChg = chgData;
    end

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

amp = chg1 - chg2;
% end

% threshold in deg C to test for model agreement, if set to -1, search for
% max threshold that still allows for specified level of model agreement
ampThresh = -1;

% percentage of models that must agree on amplification
ampAgreement = 66;

% levels of amplification to search for model agreement on
%ampLevels = 0:5;
%if ~monthly

if strcmp(chgMetric, 'ann-max') || strcmp(chgMetric, 'ann-min') || strcmp(chgMetric, 'daily-max-min')
    ampLevels = -3:0.5:3;
elseif strcmp(chgMetric, 'ann-max-min')
    ampLevels = -10:2:10;
end
%end

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
            for curAmpLevel = ampLevels
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
                  'plotRange', [ampLevels(1) ampLevels(end)], ...
                  'cbXTicks', ampLevels, ...
                  'plotTitle', ['Amplification, ' num2str(ampAgreement) '% model agreement'], ...
                  'fileTitle', ['ampAgreement-rcp85-' num2str(size(amp, 3)) '-cmip5-' num2str(ampAgreement) '-' chgMetric '.png'], ...
                  'plotXUnits', ['Amplification (' char(176) 'C)'], ...
                  'blockWater', true, ...
                  'magnify', '2');
plotFromDataFile(saveData);
%plotModelData({lat, lon, nanmean(amp, 3)}, 'world', 'caxis', [-4 4]);

