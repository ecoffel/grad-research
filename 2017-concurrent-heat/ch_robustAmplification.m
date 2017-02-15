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

ampCount(ampCount < 10) = NaN;

plotModelData({lat, lon, ampCount}, 'world', 'caxis', [10, 27]);

plotModelData({lat, lon, nanmean(amp, 3)}, 'world', 'caxis', [-4 4]);

