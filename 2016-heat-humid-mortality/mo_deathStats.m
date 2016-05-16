load nyMergedMortData

dow = mortData{2}(:,4);
deaths = mortData{2}(:,5);
wbMin = mortData{2}(:,11);
wbMax = mortData{2}(:,12);
wbMean = mortData{2}(:,13);
tMin = mortData{2}(:,14);
tMax = mortData{2}(:,15);
tMean = mortData{2}(:,16);

% calculate month of year for each day
date = datenum('1987-01-01','yyyy-mm-dd');
moy = [];
for d = 1:length(deaths)
    moy(d,1) = month(date);
    date = addtodate(date, 1, 'day');
end

% find mean death anomalies for days of the week
dowMeans = [];
for d = 1:7
    ind = find(dow == d);
    dowMeans(d) = nanmean(deaths(ind));
end

moyMeans = [];
for m = 1:12
    ind = find(moy == m);
    moyMeans(m) = nanmean(deaths(ind));
end

monthsDeaths = [];
monthsDeathsStd = [];
monthsWbMean = [];
monthsTMean = [];
for m = 1:12
    ind = find(moy == m);
    monthsDeaths(m) = nanmean(deaths(ind));
    monthsDeathsStd(m) = nanstd(deaths(ind));
    monthsWbMean(m) = nanmean(wbMean(ind));
    monthsTMean(m) = nanmean(tMean(ind));
end

months = 1:12;

figure('Color', [1, 1, 1]);
subplot(1,2,1);
hold on;
[ax, l1, l2] = plotyy(months, monthsDeaths, months, monthsTMean);
%errorbar(ax(1), monthsDeaths, monthsDeathsStd ./ 2);
set(ax, {'ycolor'}, {'k'; 'k'});
set(l1, 'Color', 'r', 'LineWidth', 2);
set(l2, 'Color', 'k', 'LineWidth', 2);
set(ax, 'FontSize', 20);
xlabel('Month', 'FontSize', 24);
ylabel(ax(1), 'Mean daily deaths', 'FontSize', 24);
ylabel(ax(2), 'Daily mean temperature', 'FontSize', 24);
legend('Deaths', 'Mean temperature');
title('Monthly mortality', 'FontSize', 30);
