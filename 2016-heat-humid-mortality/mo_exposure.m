load nyMergedMortData

deaths = mortData{2}(:,5);
wbMax = mortData{2}(:,14);
wbMean = mortData{2}(:,16);
tMax = mortData{2}(:,11);
tMean = mortData{2}(:,13);

indNotNan = find(~isnan(wbMean) & ~isnan(tMean));

deaths = deaths(indNotNan);
wbMean = wbMean(indNotNan);
wbMax = wbMax(indNotNan);
tMean = tMean(indNotNan);
tMax = tMax(indNotNan);

% remove linear trend and mean
deathsDetrend = detrend(detrend(deaths, 'constant'));

% temperature anomalies
wbMeanAnom = wbMean - nanmean(wbMean);
wbMaxAnom = wbMax - nanmean(wbMax);
tMeanAnom = tMean - nanmean(tMean);
tMaxAnom = tMax - nanmean(tMax);

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

% deaths at given temp/wb level

tempBins = -30:5:50;
tempDeathsHist = zeros(length(tempBins), 1);
tempHist = zeros(length(tempBins), 1);

wbBins = -25:5:35;
wbDeathsHist = zeros(length(wbBins), 1);
wbHist = zeros(length(wbBins), 1);

for d = 1:length(deaths)
    curTMean = tMean(d);
    curWbMean = wbMean(d);
    
    ind = find(curTMean > tempBins);
    tempDeathsHist(ind(end)) = tempDeathsHist(ind(end)) + deaths(d);
    
    ind = find(curWbMean > wbBins);
    wbDeathsHist(ind(end)) = wbDeathsHist(ind(end)) + deaths(d);
end

wbDeathsHist = wbDeathsHist ./ sum(wbDeathsHist);
tempDeathsHist = tempDeathsHist ./ sum(tempDeathsHist);

for i = 1:length(wbMean)
    ind = find(tMean(i) > tempBins);
    tempHist(ind(end)) = tempHist(ind(end)) + 1;
    
    ind = find(wbMean(i) > wbBins);
    wbHist(ind(end)) = wbHist(ind(end)) + 1;
end

wbHist = wbHist ./ sum(wbHist);
tempHist = tempHist ./ sum(tempHist);

% lagged mean temp / wb indicies
tempLag = mo_laggedTemp(tMean, 0:3, ones(length(0:3),1) ./ 4.0);
wbLag = mo_laggedTemp(wbMean, 0:4, ones(length(0:4),1) ./ 5.0);








