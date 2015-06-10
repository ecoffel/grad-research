basePeriod = 1981:1999;
futurePeriod = 2051:2071;
isRegridded = false;
% models = {'e:/data/narccap/output/crcm/ccsm/', 'e:/data/narccap/output/crcm/cgcm3/', ...
%         'e:/data/narccap/output/ecp2/gfdl/', 'e:/data/narccap/output/hrm3/gfdl/', ...
%         'e:/data/narccap/output/hrm3/hadcm3/', 'e:/data/narccap/output/mm5i/ccsm/', ...
%         'e:/data/narccap/output/mm5i/hadcm3/', 'e:/data/narccap/output/rcm3/cgcm3/', ...
%         'e:/data/narccap/output/rcm3/gfdl/', 'e:/data/narccap/output/wrfg/ccsm/', ...
%         'e:/data/narccap/output/wrfg/cgcm3/'};
%models = {'e:/data/ncep-reanalysis/output/', 'e:/data/narccap/output/ensemble-mean/'};
models = {'e:/data/narccap/output/ensemble-mean/', 'e:/data/narccap/output/ensemble-mean/'};
modelVars = {'tasmax', 'tasmax'};
modelPeriods = {basePeriod, futurePeriod};
modelLineStyles = {'b', 'r'};
%modelLineStyles = {'r', 'g', 'c', 'm', 'y', 'b', 'k'};
modelLineWidths = {2, 2};
modelLegends = '''narccap ensemble mean [1981-1999]'', ''narccap ensemble mean [2051-2071]''';
%modelLegends = '''e:/data/narccap/output/crcm/ccsm/'', ''e:/data/narccap/output/crcm/cgcm3/'',''e:/data/narccap/output/ecp2/gfdl/'', ''e:/data/narccap/output/hrm3/gfdl/'', ''e:/data/narccap/output/hrm3/hadcm3/'', ''e:/data/narccap/output/mm5i/ccsm/'', ''e:/data/narccap/output/mm5i/hadcm3/'', ''e:/data/narccap/output/rcm3/cgcm3/'', ''e:/data/narccap/output/rcm3/gfdl/'', ''e:/data/narccap/output/wrfg/ccsm/'', ''e:/data/narccap/output/wrfg/cgcm3/''';

histData = {};
histBinPos = {};

for m = 1:length(models)
    model = models{m}
    var = modelVars{m};
    period = modelPeriods{m};
    yearStart = period(1);
    yearEnd = period(end);
    
    % load ensemble mean temperatures
    if isRegridded
        eMeanDailyBase = loadDailyData([model var '/regrid'], 'yearStart', yearStart, 'yearEnd', yearEnd);
    else
        eMeanDailyBase = loadDailyData([model var], 'yearStart', yearStart, 'yearEnd', yearEnd);
    end

    lat = eMeanDailyBase{1};
    lon = eMeanDailyBase{2};
    eMeanDataBase = eMeanDailyBase{3};

    % get the coords of the lat/lon target
    [latIndexRange, lonIndexRange] = latLonIndexRange(eMeanDailyBase, [38 40], [279 281]);

    clear eMeanDailyBase;

    % reshape the data into a (1, n) matrix
    eMeanDataBase = eMeanDataBase(latIndexRange, lonIndexRange, :, :, :);
    eMeanDataBase = reshape(eMeanDataBase, ...
                        [size(eMeanDataBase,1)*size(eMeanDataBase,2)*size(eMeanDataBase,3)*size(eMeanDataBase,4)*size(eMeanDataBase,5), 1]);
    eMeanDataBase(eMeanDataBase < 260) = NaN;

    [curHistData, curHistBinPos] = hist(eMeanDataBase, 100);
    histData = {histData{:} curHistData};
    histBinPos = {histBinPos{:} curHistBinPos};
    clear eMeanDataBase lat lon;
end

corrC = corrcoef(histData{1}, histData{2});

% -------------------- plot ------------------------

figure('Color',[1 1 1]);
hold on;
for h = 1:length(histData)
    plot(histBinPos{h}-273.15, histData{h}* (1/sum(histData{h})) * 100, modelLineStyles{mod(h-1,length(modelLineStyles))+1}, 'LineWidth', modelLineWidths{h});
end
ylabel('percentage of days in period', 'FontSize', 16);
xlabel('degrees C', 'FontSize', 16);
xlim([-20 55]);
ylim([0 3]);
title('daily maximum temperatures [38-40 N, 279-281 W] ', 'FontSize', 18);
set(gcf, 'Position', get(0,'Screensize'));
if length(modelLegends) > 0
    leg = eval(['legend(' modelLegends ', ''Location'', ''best'');']);
    set(leg,'FontSize',12);
end

myaa('publish');
exportfig('narccap-ensemble-daily-max-dist.png', 'Width', 16);
close all;

