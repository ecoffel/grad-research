
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

heatThresholds = [34 35];

baseDir = 'e:/data/';
yearStep = 1;
ssps = 1:5;

rcp = 'rcp85';

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

colors = {[0 0 0], [.2 0 0], [.4 0 0], [.6 0 0], [.8 0 0], [.9 0 0], [1 0 0]};
lStr = '';

figure('Color', [1,1,1]);
hold on;

for h = 1:length(heatThresholds)
    heatThreshold = heatThresholds(h);
    
    if h > 1
        lStr = [lStr ', ' num2str(heatThreshold) 'C'];
    else
        lStr = [num2str(heatThreshold) 'C'];
    end
    
    % try to load future file
    if exist(['futureCount-' num2str(heatThreshold) '.mat'], 'file')

        % load future counts
        load(['futureCount-' num2str(heatThreshold) '.mat']);

        % load grid
        load('E:\data\cmip5\output\gfdl-cm3\r1i1p1\historical\wb\regrid\world\1980101-20051231\wb_1980_01_01.mat');

        lat = wb_1980_01_01{1};
        lon = wb_1980_01_01{2};

        popBins = [1 10 100 500 1000 5000 1e4 5e4 1e5 5e5 1e6 5e6 1e7 5e7 1e8];% 5e8 1e9 5e9 1e10];
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

        subplot(2, 1, h);
        
        semilogx(popBins, popVals, 'Color', colors{h}, 'LineWidth', 2);
        hold on;
        xlabel('People exposed annually', 'FontSize', 30);
        ylabel('Probability', 'FontSize', 30);
        ylim([0 100]);
        legend([num2str(heatThresholds(h)) 'C']);
        %title(['Exposure to ' num2str(heatThreshold) 'C wet-bulb'], 'FontSize', 30);
        set(gca,'FontSize', 28);
        
    end
end

set(gcf, 'Position', get(0,'Screensize'));
set(gcf, 'Color', [1,1,1]);
%l = legend(lStr);
%set(l, 'FontSize', 24);
%export_fig(['heatExposureProbability-' num2str(heatThreshold) '.png']);