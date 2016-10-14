x4Dir = 'E:\data\ncep-reanalysis\output\wb\x4\1979101-20151231';
x1Dir = 'E:\data\ncep-reanalysis\output\wb\regrid\world\1981101-20101231';

years = 1981:2000;
months = 1:12;

% northeast india
lat = [26 26];
lon = [83 83];

% mean difference between wb measures for each month
monthlyDiff = zeros(12, 1);

wbX4full = [];
wbX1full = [];

for y = years
    for m = months
        % load 4x NCEP wet bulb data
        load([x4Dir '\wb_' num2str(y) '_' sprintf('%02d', m) '_01.mat']);
        eval(['wbX4 = wb_' num2str(y) '_' sprintf('%02d', m) '_01;']);

        load([x1Dir '\wb_' num2str(y) '_' sprintf('%02d', m) '_01.mat']);
        eval(['wbX1 = wb_' num2str(y) '_' sprintf('%02d', m) '_01;']);

        [latIndX4, lonIndX4] = latLonIndexRange(wbX4, lat, lon);
        [latIndX1, lonIndX1] = latLonIndexRange(wbX1, lat, lon);

        wbX4 = squeeze(wbX4{3}(latIndX4, lonIndX4, :));
        wbX1 = squeeze(wbX1{3}(latIndX1, lonIndX1, :));
        
        wbX4max = [];
        for i = 1:length(wbX4)/4
            wbX4max(end + 1) = nanmax(wbX4((i-1)*4+1:i*4));
        end
        
        wbX1full = [wbX1full; wbX1];
        wbX4full = [wbX4full; wbX4max'];
        
        monthlyDiff(m) = monthlyDiff(m) + nanmean(wbX1' - wbX4max);
    end
end

[sortedWbX1, ind] = sort(wbX1full, 'descend');
sortedWbX4 = wbX4full(ind);

percentiles = 5:5:100;
percentileDiff = [];
percentileStd = [];
threshPast = 0;
for p = percentiles
    thresh = prctile(sortedWbX1, p);
    threshInd = find(sortedWbX1 < thresh & sortedWbX1 > threshPast);
    
    percentileDiff(end+1) = nanmean(sortedWbX1(threshInd) - sortedWbX4(threshInd));
    percentileStd(end+1) = nanstd(sortedWbX1(threshInd) - sortedWbX4(threshInd));
    
    threshPast = thresh;
end

monthlyDiff = monthlyDiff ./ length(years);

figure('Color', [1,1,1]);
hold on;
% plot(1:size(wbX4{3}, 3), squeeze(wbX4{3}(latIndX4, lonIndX4, :)), 'b');
% plot(1:4:4*size(wbX1{3}, 3), squeeze(wbX1{3}(latIndX1, lonIndX1, :)), 'r');
%plot(monthlyDiff, 'k', 'LineWidth', 2);
errorbar(percentiles, percentileDiff, percentileStd, 'k', 'LineWidth', 2);
xlabel('Percentile', 'FontSize', 28);
ylabel('Mean difference', 'FontSize', 28);
xlim([0 105]);
ylim([-2.5 2.5]);
title('Wet bulb temperature bias', 'FontSize', 30);
set(gca, 'FontSize', 24);
