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

movAvgLag = 30;

% detrend death data and remove 30 day moving average
deathsDetrend = detrend(deaths - nanmean(deaths));
deathsMovAvg = tsmovavg(deathsDetrend, 's', movAvgLag, 1);
deathsData = deathsDetrend-deathsMovAvg;

deathsData = deathsData(movAvgLag:end);
wbMean = wbMean(movAvgLag:end);
wbMin = wbMin(movAvgLag:end);
tMean = tMean(movAvgLag:end);
tMin = tMin(movAvgLag:end);

% calculate month of year for each day
date = datenum('1987-01-01','yyyy-mm-dd');
moy = [];
for d = 1:length(deaths)
    moy(d,1) = month(date);
    date = addtodate(date, 1, 'day');
end

% select june to september
indSummer = find(moy >= 6 & moy <= 8);
indWinter = find(moy >= 12 | moy < 3);
indAll = 1:length(moy);

indSelect = indSummer;

wbMeanSel = wbMean(indSelect);
wbMinSel = wbMin(indSelect);
tMeanSel = tMean(indSelect);
tMinSel = tMin(indSelect);
deathsSel = deathsData(indSelect);
dow = dow(indSelect);
moy = moy(indSelect);

wbMeanVar = wbMeanSel;
wbMinVar = wbMinSel;
tMeanVar = tMeanSel;
tMinVar = tMinSel;
deathsVar = deathsSel;

% take the 4 day lag of temp variables
wbMeanVar = mo_laggedTemp(wbMeanVar, 4);
wbMinVar = mo_laggedTemp(wbMinVar, 4);

tMinVar = mo_laggedTemp(tMinVar, 4);
tMeanVar = mo_laggedTemp(tMeanVar, 4);

% take the 1st PC of detrended death data
[eof, pc, err] = calEeof(deathsVar, 5, 1, 10, 1);

% adjust lengths to so that time series match
deathsVar = pc(1,:);
wbMeanVar = wbMeanVar(5:end);
wbMinVar = wbMinVar(5:end);

tMeanVar = tMeanVar(5:end);
tMinVar = tMinVar(5:end);

train = 1:length(deathsVar)-201;
test = length(deathsVar)-200:length(deathsVar);

Xtrain = [wbMeanVar(train) wbMinVar(train) tMeanVar(train) tMinVar(train)];
mdl = fitlm(Xtrain, deathsVar(train));

Xtest = [wbMeanVar(test) wbMinVar(test) tMeanVar(test) tMinVar(test)];

pred = predict(mdl, Xtest);

hold on;
plot(wbMeanVar(test),'b');
plot(tMinVar(test),'g');
plot(deathsVar(test),'r');
plot(pred,'k','LineWidth',2);
legend('wb', 'deaths');


