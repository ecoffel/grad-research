
season = 'all';
basePeriod = 'past';
baseDataset = 'ncep';

baseModels = {''};
baseVar = 'wb';

baseRegrid = true;

region = 'world';
chgType = 'multi-model';

plotRegion = 'world';
plotTitle = ['CMIP5 annual maximum wet-bulb'];

basePeriodYears = 1985:2004;
testPeriodYears = 2070:2080;

% compare the annual mean temperatures or the mean extreme temperatures
exportFormat = 'png';

blockWater = true;
baseBiasCorrect = false;

heatThreshold = 34;

baseDir = 'e:/data/';
yearStep = 1;
ssps = 1:5;

if ~baseBiasCorrect
    baseBcStr = '';
else
    baseBcStr = '-bc';
end

if strcmp(season, 'summer')
    findMax = true;
    months = [6 7 8];
    maxMinStr = 'maximum';
elseif strcmp(season, 'winter')
    findMax = true;
    months = [12 1 2];
    maxMinStr = 'maximum';
elseif strcmp(season, 'all')
    findMax = true;
    months = 1:12;
    maxMinStr = 'maximum';
end

plotRange = [0 100];

if strcmp(basePeriod, 'past')
    basePeriod = basePeriodYears;
    baseRcp = 'historical/';
end

lat = [];
lon = [];
baseData = {};

baseDatasetStr = ['ncep'];
baseDataDir = 'ncep-reanalysis/output';
baseEnsemble = '';
baseRcp = '';

% try to load future file
if exist(['futureCount-' num2str(heatThreshold) '.mat'], 'file')
    
    % load future counts
    load(['futureCount-' num2str(heatThreshold) '.mat']);
    
    % load grid
    load('E:\data\cmip5\output\gfdl-cm3\r1i1p1\historical\wb\regrid\world\1980101-20051231\wb_1980_01_01.mat');
    
    lat = wb_1980_01_01{1};
    lon = wb_1980_01_01{2};
    
    popBins = [100 500 1000 5000 1e4 5e4 1e5 5e5 1e6 5e6 1e7 5e7 1e8 5e8 1e9 5e9 1e10];
    popVals = zeros(length(popBins), 1);
    popExposure = [];
    
    % loop through all scenarios and count pop for each
    for c = 1:size(futureCount, 3)
        for s = 1:length(ssps)
            popExposure(c, s) = hh_countPop({lat, lon, futureCount(:, :, c)}, region, [testPeriodYears(1)], ssps(s), true);
            
            for p = 1:length(popBins)
                if popExposure(c, s) < popBins(p)
                    popVals(p) = popVals(p)+1;
                    break;
                end
            end
        end
    end
    
    popVals = popVals ./ sum(popVals) .* 100;
    
    %figure('Color', [1,1,1]);
    %hold on;
    semilogx(popBins, popVals, 'k', 'LineWidth', 2);
    xlabel('People exposed annually', 'FontSize', 24);
    ylabel('Probability', 'FontSize', 24);
    title(['Exposure to ' num2str(heatThreshold) 'C wet-bulb'], 'FontSize', 30);
    set(gca,'FontSize', 20);
    set(gcf, 'Position', get(0,'Screensize'));
    set(gcf, 'Color', [1,1,1]);
    export_fig(['heatExposureProbability-' num2str(heatThreshold) '.png']);
    
    
%     fileTitle = ['heatProbability-' num2str(heatThreshold) '-' num2str(lowPercentile) '-' num2str(testPeriodYears(1)) '-' num2str(testPeriodYears(2))];
%     plotTitle = ['Annual probability of ' num2str(heatThreshold) 'C wet-bulb, ' num2str(lowPercentile) 'p'];
% 
%     result = {lat, lon, lowGrid};
%     saveData = struct('data', {result}, ...
%                       'plotRegion', 'world', ...
%                       'plotRange', [0 100], ...
%                       'plotTitle', plotTitle, ...
%                       'fileTitle', [fileTitle '.' exportFormat], ...
%                       'plotXUnits', 'Percent', ...
%                       'plotCountries', false, ...
%                       'plotStates', false, ...
%                       'blockWater', true);
% 
%     plotFromDataFile(saveData);
% 
%     fileTitle = ['heatProbability-' num2str(heatThreshold) '-' num2str(highPercentile) '-' num2str(testPeriodYears(1)) '-' num2str(testPeriodYears(2))];
%     plotTitle = ['Annual probability of ' num2str(heatThreshold) 'C wet-bulb, ' num2str(highPercentile) 'p'];
% 
%     result = {lat, lon, highGrid};
%     saveData = struct('data', {result}, ...
%                       'plotRegion', 'world', ...
%                       'plotRange', [0 100], ...
%                       'plotTitle', plotTitle, ...
%                       'fileTitle', [fileTitle '.' exportFormat], ...
%                       'plotXUnits', 'Percent', ...
%                       'plotCountries', false, ...
%                       'plotStates', false, ...
%                       'blockWater', true);
%     plotFromDataFile(saveData); 
end