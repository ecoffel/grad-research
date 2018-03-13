% late period
load(['2017-nile-climate\output\dryFuture-cmip5-rcp85-2056-2080.mat']);
dryFutureLate = dryFuture;
load(['2017-nile-climate\output\wetFuture-cmip5-rcp85-2056-2080.mat']);
wetFutureLate = wetFuture;
load(['2017-nile-climate\output\hotFuture-cmip5-rcp85-2056-2080.mat']);
hotFutureLate = hotFuture;
load(['2017-nile-climate\output\hotDryFuture-cmip5-rcp85-2056-2080.mat']);
hotDryFutureLate = hotDryFuture;

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

rcp = 'rcp85';
timePeriodBase = [1980 2004];
timePeriodFuture = [2056 2080];

annual = true;
north = false;

load lat;
load lon;

[regionInds, regions, regionNames] = ni_getRegions();

seasonNames = {'DJF', 'MAM', 'JJA', 'SON'};
seasons = [[12 1 2]; 
           [3 4 5];
           [6 7 8];
           [9 10 11]];

    if annual
        months = 1:12;
    else
        months = seasons(s,:);
    end
    
    curInds = regionInds('nile');
    latIndsRegion = curInds{1};
    lonIndsRegion = curInds{2};
    
    if north
        curInds = regionInds('nile-north');
    else
        curInds = regionInds('nile-south');
    end
    latInds = curInds{1};
    lonInds = curInds{2};
    
    dryFutureLate = 100 .* squeeze(nanmean(nanmean(nanmean(dryFutureLate(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, months, :), 3), 2), 1));
    wetFutureLate = 100 .* squeeze(nanmean(nanmean(nanmean(wetFutureLate(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, months, :), 3), 2), 1));
    hotFutureLate = 100 .* squeeze(nanmean(nanmean(nanmean(hotFutureLate(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, months, :), 3), 2), 1));
    hotDryFutureLate = 100 .* squeeze(nanmean(nanmean(nanmean(hotDryFutureLate(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, months, :), 3), 2), 1));
    
    % prchg vs prstd chg
    figure('Color', [1,1,1]);
    hold on;
    box on;
    grid on;
    axis square;

    for m = 1:size(hotDryFutureLate, 1)
        %prSig(s, m) = kstest2(squeeze(prFut(:, m)), squeeze(prHist(:, m)));

        %if prSig(s, m)
         %   plot(prChg(m), prStd(m), 'o', 'MarkerSize', 25, 'Color', [85/255.0, 158/255.0, 237/255.0], 'LineWidth', 2);
        %end
        t = text(hotFutureLate(m), hotDryFutureLate(m), num2str(m), 'HorizontalAlignment', 'center', 'Color', 'k');
        t.FontSize = 18;
    end

    [f, gof] = fit(hotFutureLate, hotDryFutureLate, 'poly1');
    cint = confint(f);
    if sign(cint(1,1)) == sign(cint(2,1))
        p = plot([min(hotFutureLate) max(hotFutureLate)], [f(min(hotFutureLate)) f(max(hotFutureLate))], '--b', 'LineWidth', 2);
    end

    xlim([0 100]);
    set(gca, 'XTick', [0 25 50 75 100]);
    ylim([0 40]);
    legend([p], {sprintf('R^2 = %.2f', gof.rsquare)});
    xlabel('Hot seasons (%)');
    ylabel('Hot & dry seasons (%)');
    set(gca, 'FontSize', 40);
    set(gcf, 'Position', get(0,'Screensize'));
    export_fig hot-contrib.eps;
    
    
    figure('Color', [1,1,1]);
    hold on;
    box on;
    grid on;
    axis square;

    for m = 1:size(hotDryFutureLate, 1)
        t = text(dryFutureLate(m), hotDryFutureLate(m), num2str(m), 'HorizontalAlignment', 'center', 'Color', 'k');
        t.FontSize = 18;
    end

    [f, gof] = fit(dryFutureLate, hotDryFutureLate, 'poly1');
    cint = confint(f);
    if sign(cint(1,1)) == sign(cint(2,1))
        p = plot([min(dryFutureLate) max(dryFutureLate)], [f(min(dryFutureLate)) f(max(dryFutureLate))], '--b', 'LineWidth', 2);
    end

    xlim([0 100]);
    set(gca, 'XTick', [0 25 50 75 100]);
    ylim([0 40]);
    legend([p], {sprintf('R^2 = %.2f', gof.rsquare)});
    xlabel('Dry seasons (%)');
    ylabel('Hot & dry seasons (%)');
    set(gca, 'FontSize', 40);
    set(gcf, 'Position', get(0,'Screensize'));
    export_fig dry-contrib.eps;
