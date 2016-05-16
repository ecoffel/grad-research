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

% movAvgLag = 1;

% detrend death data and remove 30 day moving average
deathsDetrend = deaths - nanmean(deaths);%detrend(deaths - nanmean(deaths));
%deathsMovAvg = tsmovavg(deathsDetrend, 's', movAvgLag, 1);
deathsData = deathsDetrend;%-deathsMovAvg;

% deathsData = deathsData(movAvgLag:end);
% wbMean = wbMean(movAvgLag:end);
% wbMin = wbMin(movAvgLag:end);
% tMean = tMean(movAvgLag:end);
% tMin = tMin(movAvgLag:end);

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

indNotNan = find(~isnan(wbMeanSel) & ~isnan(tMeanSel));

wbMeanVar = wbMeanSel(indNotNan);
wbMinVar = wbMinSel(indNotNan);
tMeanVar = tMeanSel(indNotNan);
tMinVar = tMinSel(indNotNan);
deathsVar = deathsSel(indNotNan);

% take the 4 day lag of temp variables
wbMeanLag = mo_laggedTemp(wbMeanVar, 5);
wbMean = wbMeanVar;
wbMinLag = mo_laggedTemp(wbMinVar, 5);

tMinLag = mo_laggedTemp(tMinVar, 5);
tMean = tMeanVar;
tMeanLag = mo_laggedTemp(tMeanVar, 5);

% take the 1st PC of detrended death data
[eof, pc, err] = calEeof(deathsVar, 5, 1, 10, 1);

% adjust lengths to so that time series match
deathsVar = pc(1,:);
wbMeanLag = wbMeanLag(4:end);
wbMinLag = wbMinLag(4:end);

tMeanLag = tMeanLag(4:end);
tMinLag = tMinLag(4:end);

wbMean = wbMean(9:end);
tMean = tMean(9:end);
dow = dow(9:end);

testingLength = 92;

modelPred = [];
modelCi = [];
modelR2 = [];

for i = 1:testingLength:length(deathsVar)
    
    if i+testingLength <= length(deathsVar)
        test = i:i+testingLength;
    else
        test = i:length(deathsVar);
    end
    
    trainTmp = ones(length(deathsVar), 1);
    trainTmp(test) = 0;
    train = find(trainTmp);

    Xtrain = [dow(train) wbMean(train) tMean(train) wbMeanLag(train) wbMinLag(train) tMeanLag(train) tMinLag(train)];
    mdl = fitlm(Xtrain, deathsVar(train));
    modelR2(end+1) = mdl.Rsquared.Ordinary;
    
    Xtest = [dow(test) wbMean(test) tMean(test) wbMeanLag(test) wbMinLag(test) tMeanLag(test) tMinLag(test)];

    [ypred, yci] = predict(mdl, Xtest);
    
%     figure('Color', [1, 1, 1]);
%     hold on;
%     plot(wbMeanLag(test),'b');
%     plot(wbMean(test),'g');
%     plot(deathsVar(test),'r');
%     plot(ypred,'k','LineWidth',2);
%     plot(yci(:,1), ':k', 'LineWidth', 1);
%     plot(yci(:,2), ':k', 'LineWidth', 1);
%     legend('wb 5 day lag', 'wb', 'deaths', 'modeled deaths');
    
    modelPred(test) = ypred;
    modelCi(test, :) = yci;
end

figure('Color', [1, 1, 1]);

ax1 = subplot(1,2,1);
hold on;
plot(wbMeanLag, 'b', 'LineWidth', 2);
plot(wbMean, 'g', 'LineWidth', 2);
plot(deathsVar, 'r', 'LineWidth', 2);
plot(modelPred,'k','LineWidth', 3);
%plot(modelCi(:,1), ':k', 'LineWidth', 1);
%plot(modelCi(:,2), ':k', 'LineWidth', 1);
xlabel('Days', 'FontSize', 24);
ylabel('Daily death anomaly', 'FontSize', 24);
set(ax1, 'xlim', [828 920]);
%set(ax1, 'xlim', [0 92]);
set(gca, 'FontSize', 20);
title('Summer 1996', 'FontSize', 26);
%title('Summer 1987', 'FontSize', 26);
legend('Wet-bulb 5 day lag', 'Wet-bulb', 'Deaths', 'Modeled deaths');

ax2 = subplot(1,2,2);
hold on;
plot(wbMeanLag, 'b', 'LineWidth', 2);
plot(wbMean, 'g', 'LineWidth', 2);
plot(deathsVar, 'r', 'LineWidth', 2);
plot(modelPred,'k','LineWidth', 3);
%plot(modelCi(:,1), ':k', 'LineWidth', 1);
%plot(modelCi(:,2), ':k', 'LineWidth', 1);
set(ax2, 'xlim', [1012 1104]);
%set(ax2, 'xlim', [276 368]);
xlabel('Days', 'FontSize', 24);
ylabel('Daily death anomaly', 'FontSize', 24);
set(gca, 'FontSize', 20);
title('Summer 1999', 'FontSize', 26);
legend('Wet-bulb 5 day lag', 'Wet-bulb', 'Deaths', 'Modeled deaths');

s = suptitle('Mortality model');
set(s, 'FontSize', 30);

