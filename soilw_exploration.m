clear
clc

tmaxBase = loadDailyData('e:/data/ncep-reanalysis/output/tmax/regrid/world', 'yearStart', 1980, 'yearEnd', 2010);
soilwBase = loadDailyData('e:/data/ncep-reanalysis/output/soilw10/regrid/world', 'yearStart', 1980, 'yearEnd', 2010);

% select paris lat/lon
%[latInd, lonInd] = latLonIndexRange(tmaxBase, [45 45], [9 9]);
%[latInd, lonInd] = latLonIndexRange(tmaxBase, [41 41], [269 269]);
[latInd, lonInd] = latLonIndexRange(tmaxBase, [33 33], [248 248]);

% find heat waves
tmax = nanmean(nanmean(tmaxBase{3}(latInd, lonInd, :, 6:8, :),2), 1)-273.15;
%thresh = prctile(reshape(tmax, [numel(tmax),1]), 95);
tmax = reshape(tmax, [numel(tmax), 1]);
%heatWaveInd = find(tmax > thresh);

% find 3 day heat waves
%heatWaveInd = heatWaveInd(find(diff(diff(heatWaveInd))==1));

soilw = soilwBase{3}(latInd, lonInd, :, 6:8, :);

% and monthly mean anomaly for soilw
for month = 1:size(soilw, 4)
    mm = nanmean(nanmean(soilw(:, :, :, month, :),5), 3);
    soilw(:, :, :, month, :) = (soilw(:, :, :, month, :) - mm)./mm.*100;
end

soilw = squeeze(soilw);
soilw = reshape(soilw,[numel(soilw),1]);
nn = find(~isnan(soilw) & ~isnan(tmax));
soilw = soilw(nn);
tmax = tmax(nn);

f = fit(tmax, soilw, 'poly1');

figure('Color',[1,1,1]);
hold on;
axis square;
grid on;
box on;

scatter(tmax, soilw);
plot(tmax, f(tmax), 'k', 'LineWidth', 3);
xlabel(['Temperature (' char(176) 'C)'],'FontSize',40);
ylabel('Soil moisture anomaly (%)', 'FontSize', 40);
set(gca,'FontSize',36);
ylim([-30 30]);
xlim([5 40]);