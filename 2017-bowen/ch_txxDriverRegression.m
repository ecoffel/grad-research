load lat;
load lon;
load waterGrid;
waterGrid = logical(waterGrid);

showOutliers = true;
plotModels = false;
useTxxSeasonalAmp = true;
useTxChg = false;

vars = {'cltChg', 'efChg', 'hussHumChg', 'rsdsNetChg', 'mrsoChg', 'prChg', ...
        'heatFluxChg', 'hflsChg', 'hfssChg', 'netRadChg', ...
        'rldsChg', 'rldsNetChg', 'rlusChg', 'rsdsChg', ...
        'rsusChg', 'cltHistorical', 'prHistorical', 'hfssHistorical', 'hflsHistorical', 'efHistorical', 'TCHfssJJA'};
    
%vars = {'prHistorical', 'hfssHistorical', 'efHistorical', 'cltHistorical', 'TCHfssJJA'};

varMonths = {};
varsAddition = {};

for v = 1:length(vars)-1
    varMonths{v} = [6 7 8];
    varsAddition{v} = '-absolute';
end

varMonths{end+1} = [1];
varsAddition{end+1} = '';

N = 2;

selRegions = 10;

% txx amp
if useTxxSeasonalAmp
    load e:/data/projects/bowen/derived-chg/txxTxWarmChg.mat;
    ampVar = txxTxWarmChg;
elseif useTxChg
    load e:/data/projects/bowen/derived-chg/txChgWarm.mat;
    ampVar = txChgWarm;
else
    load e:/data/projects/bowen/derived-chg/txxAmp.mat;
    ampVar = amp;
end

for v = 1:length(vars)
    load(['e:/data/projects/bowen/derived-chg/' vars{v} varsAddition{v}]);
    eval(['v' num2str(v) '=' vars{v} ';']);
end

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

regionNames = {'World', ...
                'Eastern U.S.', ...
                'Southeast U.S.', ...
                'Central Europe', ...
                'Mediterranean', ...
                'Northern SA', ...
                'Amazon', ...
                'Central Africa', ...
                'North Africa', ...
                'China'};
regionAb = {'world', ...
            'us-east', ...
            'us-se', ...
            'europe', ...
            'med', ...
            'sa-n', ...
            'amazon', ...
            'africa-cent', ...
            'n-africa', ...
            'china'};
            
regions = [[[-90 90], [0 360]]; ...             % world
           [[30 42], [-91 -75] + 360]; ...     % eastern us
           [[30 41], [-95 -75] + 360]; ...      % southeast us
           [[45, 55], [10, 35]]; ...            % Europe
           [[35 50], [-10+360 45]]; ...        % Med
           [[5 20], [-90 -45]+360]; ...         % Northern SA
           [[-10, 7], [-75, -62]+360]; ...      % Amazon
           [[-10 10], [15, 30]]; ...            % central africa
           [[15 30], [-4 29]]; ...              % north africa
           [[22 40], [105 122]]];               % china

if plotModels
    modelLeg = {};
    figure('Color', [1,1,1]);
    hold on;
    axis off;   
    for m = 1:length(models)
        plot(0, 0, 'k');
        modelLeg{m} = [num2str(m) ' ' models{m}];
    end
    set(gca, 'FontSize', 20);
    legend(modelLeg)
    export_fig model-list.eps;
end

seasons = [[12 1 2];
           [3 4 5];
           [6 7 8];
           [9 10 11]];

% load hottest seasons for each grid cell
load('2017-bowen/hottest-season-ncep.mat');

    % loop over regions
    for region = selRegions%[2 4 7 10]
        % select lat lon coords for region
        [latInds, lonInds] = latLonIndexRange({lat, lon, []}, regions(region, [1 2]), regions(region, [3 4]));

        % select amp for region for all models
        regionAmp = squeeze(nanmean(nanmean(ampVar(latInds, lonInds, :))));

        
        combos = combnk(vars, N);
        adjR2 = [];
        bestModel = [];
        bestCombo = 0;
        
        for c = 1:length(combos)
%             if ~strcmp(combos{c,1}, 'hfssChg')
%                 continue;
%             end
            
            regionAmpCur = regionAmp;
            
            curVars = {};
            curVarInd = [];
            
            curVars = {};
            
            fprintf('processing (');
            for n = 1:N
                curVars{n} = combos{c,n};
                curVarInd(n) = find(strcmp(vars, combos{c,n}));
                fprintf('%s,', combos{c,n});
                curVars{n} = combos{c,n};
            end
            fprintf(')...\n');
            
            nn = find(isnan(regionAmpCur));
            for v = curVarInd
                eval(['v' num2str(v) 'Chg = squeeze(nanmean(nanmean(nanmean(v' num2str(v) '(latInds, lonInds, :, varMonths{' num2str(v) '}), 4), 2), 1));']);     
                eval(['nn = union(nn, find(isnan(v' num2str(v) 'Chg)));']);
            end

            outliers = find(regionAmpCur > nanstd(regionAmpCur)*2+nanmean(regionAmpCur) | ...
                            regionAmpCur < -nanstd(regionAmpCur)*2+nanmean(regionAmpCur));

            regionAmpCur(nn) = [];
            for v = curVarInd
                eval(['v' num2str(v) 'Chg(nn) = [];']);

                eval(['v' num2str(v) 'Outliers = find(v' num2str(v) 'Chg > nanstd(v' num2str(v) 'Chg)*2+nanmean(v' num2str(v) 'Chg) | ' ...
                                     'v' num2str(v) 'Chg < -nanstd(v' num2str(v) 'Chg)*2+nanmean(v' num2str(v) 'Chg));']);
                eval(['outliers = union(outliers, v' num2str(v) 'Outliers);']);
            end

            X = [];

            regionAmpCur(outliers) = [];
            regionAmpCur = (regionAmpCur - nanmean(regionAmpCur)) ./ nanstd(regionAmpCur);
            for v = curVarInd
                eval(['v' num2str(v) 'Chg(outliers) = [];']);
                eval(['v' num2str(v) 'Chg = (v' num2str(v) 'Chg - nanmean(v' num2str(v) 'Chg)) ./ nanstd(v' num2str(v) 'Chg);']);
                eval(['X = [X v' num2str(v) 'Chg];']);
            end
    
            mdl = stepwiselm(X,regionAmpCur,'constant','Upper','linear','PEnter',0.05,'PredictorVars',curVars);
            %mdl = fitlm(X,regionAmpCur,'PredictorVars',curVars);
            if length(adjR2) == 0 || mdl.Rsquared.Adjusted > max(adjR2)
                bestModel = mdl;
                bestCombo = c;
            end
            adjR2(c) = mdl.Rsquared.Adjusted;

        end
%         
%         fprintf('max r2 = %.2f\n', max(adjR2));
%         combos{find(adjR2==max(adjR2)),:}
%         
    end

sortedR2 = sort(adjR2);
for i = 0:9
    ind = find(adjR2 == sortedR2(end-i));
    fprintf('(');
    for n = 1:N
        fprintf('%s, ', combos{ind(1),n});
    end
    fprintf(') = %.2f\n',adjR2(ind(1)));
end
    

yticklabels = bestModel.CoefficientNames(2:end);
coefs = bestModel.Coefficients.Estimate;
coefCIs = bestModel.coefCI;
pvals = bestModel.Coefficients.pValue;

figure('Color', [1,1,1]);
hold on; 
grid on;
box on;
axis square;

for n = 1:length(coefs)-1
    e = errorbar(coefs(1+n), n, coefs(1+n)-coefCIs(1+n,1), coefs(1+n)-coefCIs(1+n,2), 'horizontal');
    set(e, 'LineWidth', 2, 'Color', 'k');
    if pvals(1+n) > .05
        p = plot(coefs(1+n), n, 'ok', 'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', 'w');
    else
        p = plot(coefs(1+n), n, 'ok', 'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', 'k');
    end
    l = plot(0,0,'w');
end

xlim([-2.5 2.5]);
ylim([.5 (length(coefs)-1)+1]);
set(gca, 'YTick', 1:length(coefs)-1, 'YTickLabels', yticklabels);
set(gca, 'FontSize', 36)
xlabel('Normalized coefficient');
title(regionNames{selRegions});
legend([l], {['Adj. R^2 = ' sprintf('%.2f', max(adjR2))]});
set(gcf, 'Position', get(0,'Screensize'));
export_fig(['regress-' num2str(N) '-' num2str(selRegions) '.eps']);
%ytickangle(90);

