addpath('2016-heat-humid-mortality/pcatool');
load nyMergedMortData

deaths = mortData{2}(:,5);
wbMin = mortData{2}(:,11);
wbMax = mortData{2}(:,12);
wbMean = mortData{2}(:,13);
tMin = mortData{2}(:,14);
tMax = mortData{2}(:,15);
tMean = mortData{2}(:,16);

% remove seasonal cycle from temp data
tempVar = mo_removeSeasonal(wbMean);

% remove linear trend and mean
deathsDetrend = detrend(deaths - nanmean(deaths));

% moving average
deathsMovAvg = tsmovavg(deathsDetrend, 's', 30, 1);

% remove moving average from detrended deaths data so that we are looking
% at death anomalies for the proper season (since summer deaths are lower
% than winter)
deathsData = deathsDetrend - deathsMovAvg;

indNotNan = find(~isnan(tempVar) & ~isnan(deathsData));
tempVar = tempVar(indNotNan);
deathsData = deathsData(indNotNan);

maxlag = 300;

xcorrSeries = xcorr(tempVar, deathsData, maxlag, 'coeff');
xcorrStd = nanstd(xcorr(tempVar, deathsData, 'coeff'));

figure('Color', [1,1,1]);
hold on;
plot(-maxlag:maxlag, xcorrSeries, 'k', 'LineWidth', 2);
plot(-maxlag:maxlag, xcorrStd .* ones(length(-maxlag:maxlag),1), '-r');
plot(-maxlag:maxlag, -xcorrStd .* ones(length(-maxlag:maxlag),1), '-r');
plot(-maxlag:maxlag, 2*xcorrStd .* ones(length(-maxlag:maxlag),1), '--r');
plot(-maxlag:maxlag, -2*xcorrStd .* ones(length(-maxlag:maxlag),1), '--r');
ylim([-0.1 0.1]);













