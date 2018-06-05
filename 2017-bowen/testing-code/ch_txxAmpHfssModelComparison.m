% loads into amp
load e:/data/projects/bowen/derived-chg/txxAmp.mat;

% loads into hfssChg
load e:/data/projects/bowen/derived-chg/hfssChg-absolute;

% loads into hflsChg
load e:/data/projects/bowen/derived-chg/hflsChg-absolute;

useHfss = false;

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

load lat;
load lon;
load waterGrid;
waterGrid = logical(waterGrid);

load 2017-bowen/hottest-season-ncep.mat;
seasons = [[12 1 2];
           [3 4 5];
           [6 7 8];
           [9 10 11]];

hfssChgWarm = zeros(size(lat,1), size(lat, 2), size(amp, 3));
hfssChgWarm(hfssChgWarm == 0) = NaN;

hflsChgWarm = zeros(size(lat,1), size(lat, 2), size(amp, 3));
hflsChgWarm(hfssChgWarm == 0) = NaN;
for xlat = 15:75
    for ylon = 1:size(lat, 2)
        if waterGrid(xlat, ylon)
            hfssChgWarm(xlat, ylon, :) = NaN;
            hflsChgWarm(xlat, ylon, :) = NaN;
            continue;
        end
        
        hfssChgWarm(xlat, ylon, :) = nanmean(hfssChg(xlat, ylon, :, seasons(hottestSeason(xlat, ylon), 1)), 4);
        hflsChgWarm(xlat, ylon, :) = nanmean(hflsChg(xlat, ylon, :, seasons(hottestSeason(xlat, ylon), 1)), 4);
    end
end

f = figure('Color', [1,1,1]);
hold on;
axis square;
grid on;
box on;

% all models
for model = 1:size(amp, 3)
    curAmp = amp(:, :, model);
    curAmp = reshape(curAmp, [numel(curAmp), 1]);
    
    if useHfss
        curFlux = hfssChgWarm(:, :, model);
    else
        curFlux = hflsChgWarm(:, :, model);
    end
    
    curFlux = reshape(curFlux, [numel(curFlux), 1]);
    
    nn = find(~isnan(curAmp) & ~isnan(curFlux));
    curFlux = curFlux(nn);
    curAmp = curAmp(nn);
    
%     ampInd = find(curAmp > 1);
%     curFlux = curFlux(ampInd);
%     curAmp = curAmp(ampInd);
    
    f = fit(curFlux, curAmp, 'poly1');
    c = confint(f);
    if sign(c(1,1)) == sign(c(2,1))
        plot([min(curFlux) max(curFlux)], f([min(curFlux) max(curFlux)]), 'LineWidth', 1);
        
        if sign(c(1,1)) < 0
            fprintf('model: %s\n', models{model});
        end
    else
        plot([min(curFlux) max(curFlux)], f([min(curFlux) max(curFlux)]), '--', 'LineWidth', 1);
    end
    
    if useHfss
        xlabel('SH change (W/m^2)');
    else
        xlabel('LH change (W/m^2)');
    end
    ylabel(['TXx amplification (' char(176) 'C)']);
    xlim([-100 100]);
    ylim([-6 6]);
    set(gca, 'FontSize', 40)
    
end