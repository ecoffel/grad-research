load nyMergedMortData

deaths = mortData{2}(:,5);
wbMean = mortData{2}(:,16);
tMean = mortData{2}(:,13);

indNotNan = find(~isnan(wbMean) & ~isnan(tMean));

% remove linear trend and mean
deathsDetrend = detrend(detrend(deaths(indNotNan), 'constant'));
wbMeanDetrend = wbMean(indNotNan) - nanmean(wbMean(indNotNan));%detrend(wbMean(indNotNan), 'constant');
tMeanDetrend = tMean(indNotNan) - nanmean(tMean(indNotNan));%detrend(tMean(indNotNan), 'constant');

% find mean death anomalies for days of the week
dow = mortData{2}(indNotNan,4);
dowMeans = [];
for d = 1:7
    ind = find(dow == d);
    dowMeans(d) = nanmean(deathsDetrend(ind));
end

% adjust for day of the week by subtracting off mean anomaly
for i = 1:7
    ind = find(dow == d);
    deathsDetrend(ind) = deathsDetrend(ind) - dowMeans(i); 
end

% let's only look at days where the temp and wb are above the mean
t50ind = find(tMeanDetrend > 0);
wb50ind = find(wbMeanDetrend > 0);

% days with T & WB above 60th %
ind = intersect(t50ind, wb50ind);

wbMean = wbMean(ind);
tMean = tMean(ind);
deathsDetrend = deathsDetrend(ind);

figure;
hold on;
plot(wbMeanDetrend, 'g');
plot(tMeanDetrend, 'b');
%plot(deathsDetrend, 'r');

