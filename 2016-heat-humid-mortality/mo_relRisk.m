load nyMergedMortData
addpath('2016-heat-humid-mortality/pcatool');

dow = mortData{2}(:,4);
deaths = mortData{2}(:,5);
wbMin = mortData{2}(:,11);
wbMax = mortData{2}(:,12);
wbMean = mortData{2}(:,13);
tMin = mortData{2}(:,14);
tMax = mortData{2}(:,15);
tMean = mortData{2}(:,16);

% detrend death data
deathsDetrend = detrend(deaths - nanmean(deaths));

% find mean death anomalies for days of the week
dowMeans = [];
for d = 1:7
    ind = find(dow == d);
    dowMeans(d) = nanmean(deathsDetrend(ind));
end

% correct mean day of week death anomalies
for d = 1:length(deaths)
    deaths(d) = deaths(d) + dowMeans(dow(d));
end

movAvgLag = 30;

% remove 30 day moving average (seasonal effect)
deathsMovAvg = tsmovavg(deathsDetrend, 's', movAvgLag, 1);
deathsData = deathsDetrend-deathsMovAvg;
deathsData = deathsData(movAvgLag:end);

% adjust length of wbMean array
wbMean = wbMean(movAvgLag:end);

% find wb 4 day lag
wbMeanLag = mo_laggedTemp(wbMean, 4);
deathsData = deathsData(5:end);


bins = -16:2:16;




