makeCounts = false;
plotModels = false;

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

[regionInds, regions, regionNames] = ni_getRegions();

region = 'nile';

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

if makeCounts
    heatTmaxHist = [];
    heatMrsoHist = [];
    dryTmaxHist = [];
    dryMrsoHist = [];

    heatTmaxFut = [];
    heatMrsoFut = [];
    dryTmaxFut = [];
    dryMrsoFut = [];

    for m = 1:length(models)
        curInds = regionInds(region);
        fprintf('loading %s mrso...\n', models{m});
        mrsoHist = loadMonthlyData(['e:/data/cmip5/output/' models{m} '/mon/r1i1p1/historical/mrso/regrid/world'], 'mrso', 'startYear', 1980, 'endYear', 2004);
        mrsoHist = mrsoHist{3}(curInds{1}, curInds{2}, :, :);
        mrsoHistMean = nanmean(nanmean(mrsoHist, 4), 3);
        mrsoHist = mrsoHist - mrsoHistMean;
        mrsoHist = mrsoHist ./ mrsoHistMean;

        fprintf('loading %s tasmax...\n', models{m});
        tasmaxHist = loadDailyData(['e:/data/cmip5/output/' models{m} '/r1i1p1/historical/tasmax/regrid/world'], 'startYear', 1980, 'endYear', 2004);
        if nanmean(nanmean(nanmean(nanmean(nanmean(tasmaxHist{3}))))) > 100
            tasmaxHist{3} = tasmaxHist{3} - 273.15;
        end
        tasmaxHist = tasmaxHist{3}(curInds{1}, curInds{2}, :, :, :);
        tasmaxHistMean = nanmean(nanmean(nanmean(tasmaxHist, 5), 4), 3);
        tasmaxHist = squeeze(nanmax(tasmaxHist, [], 5));
        tasmaxHist = tasmaxHist - tasmaxHistMean;

        for xlat = 1:size(tasmaxHist, 1)
            for ylon = 1:size(tasmaxHist, 2)
                for year = 1:size(tasmaxHist, 3)
                    curTasmax = squeeze(tasmaxHist(xlat, ylon, year, :));
                    if length(find(isnan(curTasmax))) > 0 || length(find(curTasmax == nanmedian(curTasmax))) > 1
                        heatTmaxHist(xlat, ylon, year) = NaN;
                        heatMrsoHist(xlat, ylon, year) = NaN;
                    else
                        curTasmaxMonth = find(curTasmax == max(curTasmax));
                        heatTmaxHist(xlat, ylon, year) = curTasmax(curTasmaxMonth(1));
                        heatMrsoHist(xlat, ylon, year) = mrsoHist(xlat, ylon, year, curTasmaxMonth(1));
                    end

                    curMrso = squeeze(mrsoHist(xlat, ylon, year, :));
                    if length(find(isnan(curMrso))) > 0 || length(find(curMrso == nanmedian(curMrso))) > 1
                        dryTmaxHist(xlat, ylon, year) = NaN;
                        dryMrsoHist(xlat, ylon, year) = NaN;
                    else
                        curMinMrsoMonth = find(curMrso == min(curMrso));
                        dryTmaxHist(xlat, ylon, year) = tasmaxHist(xlat, ylon, year, curMinMrsoMonth(1));
                        dryMrsoHist(xlat, ylon, year) = curMrso(curMinMrsoMonth(1));
                    end
                end
            end
        end

        fprintf('loading %s mrso future...\n', models{m});
        mrsoFut = loadMonthlyData(['e:/data/cmip5/output/' models{m} '/mon/r1i1p1/rcp85/mrso/regrid/world'], 'mrso', 'startYear', 2056, 'endYear', 2080);
        mrsoFut = mrsoFut{3}(curInds{1}, curInds{2}, :, :);
        mrsoFut = mrsoFut - mrsoHistMean;
        mrsoFut = mrsoFut ./ mrsoHistMean;

        fprintf('loading %s tasmax future...\n', models{m});
        tasmaxFut = loadDailyData(['e:/data/cmip5/output/' models{m} '/r1i1p1/rcp85/tasmax/regrid/world'], 'startYear', 2056, 'endYear', 2080);
        if nanmean(nanmean(nanmean(nanmean(nanmean(tasmaxFut{3}))))) > 100
            tasmaxFut{3} = tasmaxFut{3} - 273.15;
        end
        tasmaxFut = tasmaxFut{3}(curInds{1}, curInds{2}, :, :, :);
        tasmaxFut = squeeze(nanmax(tasmaxFut, [], 5));
        tasmaxFut = tasmaxFut - tasmaxHistMean;

        for xlat = 1:size(tasmaxFut, 1)
            for ylon = 1:size(tasmaxFut, 2)
                for year = 1:size(tasmaxFut, 3)
                    curTasmax = squeeze(tasmaxFut(xlat, ylon, year, :));
                    if length(find(isnan(curTasmax))) > 0 || length(find(curTasmax == nanmedian(curTasmax))) > 1
                        heatTmaxFut(xlat, ylon, year) = NaN;
                        heatMrsoFut(xlat, ylon, year) = NaN;
                    else
                        curTasmaxMonth = find(curTasmax == max(curTasmax));
                        heatTmaxFut(xlat, ylon, year) = curTasmax(curTasmaxMonth(1));
                        heatMrsoFut(xlat, ylon, year) = mrsoFut(xlat, ylon, year, curTasmaxMonth(1));
                    end


                    curMrso = squeeze(mrsoFut(xlat, ylon, year, :));
                    if length(find(isnan(curMrso))) > 0 || length(find(curMrso == nanmedian(curMrso))) > 1
                        dryTmaxFut(xlat, ylon, year) = NaN;
                        dryMrsoFut(xlat, ylon, year) = NaN;
                    else
                        curMinMrsoMonth = find(curMrso == min(curMrso));
                        dryTmaxFut(xlat, ylon, year) = tasmaxFut(xlat, ylon, year, curMinMrsoMonth(1));
                        dryMrsoFut(xlat, ylon, year) = curMrso(curMinMrsoMonth(1));
                    end
                end
            end
        end

        hth(m, :) = squeeze(nanmean(nanmean(heatTmaxHist)));
        hmh(m, :) = squeeze(nanmean(nanmean(heatMrsoHist)));
        dth(m, :) = squeeze(nanmean(nanmean(dryTmaxHist)));
        dmh(m, :) = squeeze(nanmean(nanmean(dryMrsoHist)));

        htf(m, :) = squeeze(nanmean(nanmean(heatTmaxFut)));
        hmf(m, :) = squeeze(nanmean(nanmean(heatMrsoFut)));
        dtf(m, :) = squeeze(nanmean(nanmean(dryTmaxFut)));
        dmf(m, :) = squeeze(nanmean(nanmean(dryMrsoFut)));

        counts = {hth(m,:), hmh(m,:), dth(m,:), dmh(m,:), htf(m,:), hmf(m,:), dtf(m,:), dmf(m,:)};
        save(['counts-' models{m} '-' region '.mat'], 'counts');

    end
end

figure('Color', [1,1,1]);
hold on;
axis square
grid on;
box on;

for m = 1:length(models)
    load(['counts-' models{m} '-' region '.mat']);
    hth(m,:) = counts{1};
    hmh(m,:) = counts{2};
    htf(m,:) = counts{5};
    hmf(m,:) = counts{6};
end

tchg = nanmean(htf, 2)-nanmean(hth, 2);
mchg = (nanmean(hmf, 2)-nanmean(hmh, 2)) .* 100;

indNoOutliers = [];

for m = 1:length(models)
    color = 'k';
    if tchg(m) > nanmean(tchg)+2*nanstd(tchg) || tchg(m) < nanmean(tchg)-2*nanstd(tchg) || ...
       mchg(m) > nanmean(mchg)+2*nanstd(mchg) || mchg(m) < nanmean(mchg)-2*nanstd(mchg) 
        color = 'r';
    else
        indNoOutliers(end+1) = m;
    end
    
    t = text(tchg(m), mchg(m), num2str(m), 'HorizontalAlignment', 'center', 'Color', color);
    t.FontSize = 18;
end

f = fit(tchg(indNoOutliers), mchg(indNoOutliers), 'poly1');
cint = confint(f);
if sign(cint(1,1)) == sign(cint(2,1))
    plot([min(tchg(indNoOutliers)) max(tchg(indNoOutliers))], [f(min(tchg(indNoOutliers))) f(max(tchg(indNoOutliers)))], '--b', 'LineWidth', 2);
end

xlim([0 10]);
set(gca, 'XTick', 0:2:10);
ylim([-15 15]);
set(gca, 'YTick', -15:5:15);
xlabel(['Temperature change (' char(176) 'C)']);
ylabel(['Soil moisture change (%)']);
set(gca, 'FontSize', 36);
set(gcf, 'Position', get(0,'Screensize'));
export_fig(['hot-day-mrso-chg-' region '.eps']);










