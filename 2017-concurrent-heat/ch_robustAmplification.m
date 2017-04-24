load chg-data\chgData-cmip5-ann-max-rcp85-2070-2080.mat
annMax = chgData;

load chg-data\chgData-cmip5-daily-max-rcp85-2070-2080.mat
dailyMax = chgData;

load lat;
load lon;

amp = annMax - dailyMax;

% threshold in deg C to test for model agreement
ampThresh = 1;

% how many models agree on change greater than threshold
ampCount = [];

for xlat = 1:size(amp, 1)
    for ylon = 1:size(amp, 2)
        data = squeeze(amp(xlat, ylon, :));
        
        % count how many models find > thresh amplification for this grid
        % cell
        ampCount(xlat, ylon) = length(data(data > ampThresh));
    end
end

% convert to percentage of mondels
ampCount = ampCount ./ size(amp, 3) .* 100;

% don't display below 2/3 agreement
ampCount(ampCount < 66) = NaN;

result = {lat, lon, ampCount};

saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [0 100], ...
                  'plotTitle', 'Amplification model agreement', ...
                  'fileTitle', ['ampAgreement-rcp85-27-cmip5-' num2str(ampThresh) 'C.png'], ...
                  'plotXUnits', 'Percentage of models', ...
                  'blockWater', true, ...
                  'magnify', '2');
plotFromDataFile(saveData);
%plotModelData({lat, lon, nanmean(amp, 3)}, 'world', 'caxis', [-4 4]);

