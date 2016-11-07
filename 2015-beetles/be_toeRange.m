rcps = {'rcp45', 'rcp85'};
kvals = {'077', 'mean', '221'};
models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'csiro-mk3-6-0', ...
              'ec-earth', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'ipsl-cm5b-lr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

lat = [];
lon = [];

cnt = 1;

% compute internal variability --------------------------------------------
rangeInternal = [];
ratioInternal = [];

% for each RCP and K-value, find the mean range across CSIRO ensemble members
for r = 1:length(rcps)
    rcp = rcps{r};
    for k = 1:length(kvals)
        kval = kvals{k};

        load(['toe-ci-lower-ensemble-' rcp '-' kval]);
        ensembleLow = saveData;

        load(['toe-ci-upper-ensemble-' rcp '-' kval]);
        ensembleHigh = saveData;

        curEnsRange = ensembleHigh.data{3} - ensembleLow.data{3};

        % select land region to look at
        curEnsRange = curEnsRange(2:end-4,8:end-1);
        
        rangeInternal(:, :, cnt) = abs(curEnsRange);
        
        if length(lat) == 0
            lat = ensembleLow.data{1}(2:end-4,8:end-1);
            lon = ensembleLow.data{2}(2:end-4,8:end-1);
        end
        
        cnt = cnt + 1;
    end
end

rangeInternal = round(nanmean(rangeInternal, 3));

load('toe-model-range-lower-model-range');
lowerRange = saveData;
load('toe-model-range-upper-model-range');
upperRange = saveData;
mmRangeResults = upperRange.data{3} - lowerRange.data{3};
mmRangeResults = mmRangeResults(2:end-4, 8:end-1);
mmRangeResults(mmRangeResults == 0) = NaN;

ratioInternal = rangeInternal ./ mmRangeResults;
ratioInternal(isinf(ratioInternal)) = NaN;

plotTitle = ['Internal variability'];

result = {lat, lon, ratioInternal .* 100};

saveData = struct('data', {result}, ...
                  'plotRegion', 'usne', ...
                  'plotRange', [0 50], ...
                  'plotTitle', plotTitle, ...
                  'fileTitle', 'internal-var.pdf', ...
                  'plotXUnits', 'Percent', ...
                  'blockWater', true, ...
                  'plotStates', true, ...
                  'plotCountries', false, ...
                  'colormap', 'summer');

plotFromDataFile(saveData);

ratioInternalMean = num2str(nanmean(nanmean(ratioInternal)) .* 100);

['Internal variability = ' ratioInternalMean '%']

% compute K-value uncertainty ---------------------------------------------

rangeK = [];
ratioK = [];

% for each RCP and and model, find the mean range across k-values
for r = 1:length(rcps)
    rcp = rcps{r};
    
    for m = 1:length(models)
        load(['toe-model-range-' models{m} '-' rcp '-077']);
        kLow = saveData;
        load(['toe-model-range-' models{m} '-' rcp '-221']);
        kHigh = saveData;

        % higher K = more buffering = higher TOE
        curKRange = kHigh.data{3} - kLow.data{3};

        rangeK(:, :, m, r) = curKRange;
    end
end

rangeK = rangeK(2:end-4,8:end-1, :, :);
rangeK = round(nanmean(nanmean(rangeK, 4), 3));

load('toe-model-range-lower-model-range');
lowerRange = saveData;
load('toe-model-range-upper-model-range');
upperRange = saveData;
mmRangeResults = abs(upperRange.data{3} - lowerRange.data{3});
mmRangeResults = mmRangeResults(2:end-4, 8:end-1);
mmRangeResults(mmRangeResults == 0) = NaN;

ratioK = rangeK ./ mmRangeResults;
ratioK(isinf(ratioK)) = NaN;

plotTitle = ['K-value uncertainty'];

result = {lat, lon, ratioK .* 100};

saveData = struct('data', {result}, ...
                  'plotRegion', 'usne', ...
                  'plotRange', [0 50], ...
                  'plotTitle', plotTitle, ...
                  'fileTitle', 'k-variability.pdf', ...
                  'plotXUnits', 'Percent', ...
                  'blockWater', true, ...
                  'plotStates', true, ...
                  'plotCountries', false, ...
                  'colormap', 'summer');

plotFromDataFile(saveData);

ratioKMean = num2str(nanmean(nanmean(ratioK)) .* 100);
rangeKMean = num2str(nanmean(nanmean(rangeK)));

['K-value uncertainty = ' ratioKMean '%']
['K-value range = ' rangeKMean]


% compute RCP uncertainty -------------------------------------------------

rangeRCP = [];
ratioRCP = [];

% for each K-value and and model, find the mean range across RCPs
for k = 1:length(kvals)
    kval = kvals{k};
    
    for m = 1:length(models)
        load(['toe-model-range-' models{m} '-rcp45-' kval]);
        rcpLow = saveData;
        load(['toe-model-range-' models{m} '-rcp85-' kval]);
        rcpHigh = saveData;

        % RCP85 = LOWER time of emergence, so low-high here
        curRCPRange = rcpLow.data{3} - rcpHigh.data{3};

        rangeRCP(:, :, m, k) = curRCPRange;
    end
end

rangeRCP = rangeRCP(2:end-4,8:end-1, :, :);
rangeRCP = round(nanmean(nanmean(rangeRCP, 4), 3));

load('toe-model-range-lower-model-range');
lowerRange = saveData;
load('toe-model-range-upper-model-range');
upperRange = saveData;
mmRangeResults = abs(upperRange.data{3} - lowerRange.data{3});
mmRangeResults = mmRangeResults(2:end-4, 8:end-1);
mmRangeResults(mmRangeResults == 0) = NaN;

ratioRCP = rangeRCP ./ mmRangeResults;
ratioRCP(isinf(ratioRCP)) = NaN;

plotTitle = ['RCP-value uncertainty'];

result = {lat, lon, ratioRCP .* 100};

saveData = struct('data', {result}, ...
                  'plotRegion', 'usne', ...
                  'plotRange', [0 50], ...
                  'plotTitle', plotTitle, ...
                  'fileTitle', 'rcp-variability.pdf', ...
                  'plotXUnits', 'Percent', ...
                  'blockWater', true, ...
                  'plotStates', true, ...
                  'plotCountries', false, ...
                  'colormap', 'summer');

plotFromDataFile(saveData);

ratioRCPMean = num2str(nanmean(nanmean(ratioRCP)) .* 100);
rangeRCPMean = num2str(nanmean(nanmean(rangeRCP)));

['RCP uncertainty = ' ratioRCPMean '%']
['RCP range = ' rangeRCPMean]


% compute model uncertainty -----------------------------------------------

rangeModel = [];
ratioModel = [];

% for each K-value and RCP, find the mean range across models
for k = 1:length(kvals)
    kval = kvals{k};
    
    for r = 1:length(rcps)
        rcp = rcps{r};
    
        curModelRange = [];
        
        for m = 1:length(models)
            load(['toe-model-range-' models{m} '-' rcp '-' kval]);
            curModelRange(:, :, m) = saveData.data{3};
        end
        
        % search for highest and lowest models
        minModel = -1;
        minModelInd = -1;

        maxModel = -1;
        maxModelInd = -1;

        for m = 1:size(curModelRange, 3)
            rank = nanmean(nanmean(curModelRange(:, :, m)));

            if minModel == -1 || rank < minModel
                minModel = rank;
                minModelInd = m;
            end

            if maxModel == -1 || rank > maxModel
                maxModel = rank;
                maxModelInd = m;
            end
        end

        resultLow = curModelRange(:,:,minModelInd);
        resultHigh = curModelRange(:,:,maxModelInd);
        
        rangeModel(:, :, k, r) = resultHigh - resultLow;
        
    end
end

rangeModel = rangeModel(2:end-4,8:end-1, :, :);
rangeModel = round(nanmean(nanmean(rangeModel, 4), 3));

load('toe-model-range-lower-model-range');
lowerRange = saveData;
load('toe-model-range-upper-model-range');
upperRange = saveData;
mmRangeResults = abs(upperRange.data{3} - lowerRange.data{3});
mmRangeResults = mmRangeResults(2:end-4, 8:end-1);
mmRangeResults(mmRangeResults == 0) = NaN;

ratioModel = rangeModel ./ mmRangeResults;
ratioModel(isinf(ratioModel)) = NaN;

plotTitle = ['Model uncertainty'];

result = {lat, lon, ratioModel .* 100};

saveData = struct('data', {result}, ...
                  'plotRegion', 'usne', ...
                  'plotRange', [0 100], ...
                  'plotTitle', plotTitle, ...
                  'fileTitle', 'model-variability.pdf', ...
                  'plotXUnits', 'Percent', ...
                  'blockWater', true, ...
                  'plotStates', true, ...
                  'plotCountries', false, ...
                  'colormap', 'summer');

plotFromDataFile(saveData);

ratioModelMean = num2str(nanmean(nanmean(ratioModel)) .* 100);
rangeModelMean = num2str(nanmean(nanmean(rangeModel)));

['Model uncertainty = ' ratioModelMean '%']
['Model range = ' rangeModelMean]


['Full range = ' num2str(nanmean(nanmean(mmRangeResults)))]

ratioInternal = nanmean(nanmean(ratioInternal));
ratioModel = nanmean(nanmean(ratioModel));
ratioRCP = nanmean(nanmean(ratioRCP));
ratioK = nanmean(nanmean(ratioK));

m = (ratioInternal + ratioModel + ratioRCP + ratioK) / 100.0;
ratios = [ratioInternal/m, ratioModel/m, ratioRCP/m, ratioK/m,; 0 0 0 0];

x = colormap('summer');
b = bar(ratios,'stacked')
xlim([0.5 1.5])
set(b(1),'FaceColor',x(2,:))
set(b(2),'FaceColor',x(20,:))
set(b(3),'FaceColor',x(40,:))
set(b(4),'FaceColor',x(64,:))
set(gca,'FontSize',24);
xlabel('Variability', 'FontSize',26)
set(gca,'xtick',[])
ylabel('Percent','FontSize',26);
legend('Internal', 'Model','RCP','K-Value');
set(gcf,'Color',[1,1,1]);
