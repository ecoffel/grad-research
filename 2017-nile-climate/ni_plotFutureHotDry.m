base = 'cmip5';

rcp = 'rcp45';

% late period
load(['2017-nile-climate\output\dryFuture-annual-' base '-' rcp '-2056-2080.mat']);
dryFutureLate = dryFuture;
load(['2017-nile-climate\output\wetFuture-annual-' base '-' rcp '-2056-2080.mat']);
wetFutureLate = wetFuture;
load(['2017-nile-climate\output\hotFuture-annual-' base '-' rcp '-2056-2080.mat']);
hotFutureLate = hotFuture;
load(['2017-nile-climate\output\hotDryFuture-annual-' base '-' rcp '-2056-2080.mat']);
hotDryFutureLate = hotDryFuture;

% early period
load(['2017-nile-climate\output\dryFuture-annual-' base '-' rcp '-2031-2055.mat']);
dryFutureEarly = dryFuture;
load(['2017-nile-climate\output\wetFuture-annual-' base '-' rcp '-2031-2055.mat']);
wetFutureEarly = wetFuture;
load(['2017-nile-climate\output\hotFuture-annual-' base '-' rcp '-2031-2055.mat']);
hotFutureEarly = hotFuture;
load(['2017-nile-climate\output\hotDryFuture-annual-' base '-' rcp '-2031-2055.mat']);
hotDryFutureEarly = hotDryFuture;

drawScatter = true;
drawMaps = false;
north = true;
annual = true;

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

seasons = [[12 1 2];
           [3 4 5];
           [6 7 8];
           [9 10 11]];
seasonNames = {'DJF', 'MAM', 'JJA', 'SON'};

load lat;
load lon;

regionBounds = [[2 32]; [25, 44]];
[latInds, lonInds] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));

regionBoundsSouth = [[2 13]; [25, 42]];
regionBoundsNorth = [[13 32]; [29, 34]];

regionBoundsBlue = [[9 14]; [34, 37.5]];
regionBoundsWhite = [[9 14]; [30, 34]];

[latIndsNorth, lonIndsNorth] = latLonIndexRange({lat,lon,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
[latIndsSouth, lonIndsSouth] = latLonIndexRange({lat,lon,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));

[latIndsBlue, lonIndsBlue] = latLonIndexRange({lat,lon,[]}, regionBoundsBlue(1,:), regionBoundsBlue(2,:));
[latIndsWhite, lonIndsWhite] = latLonIndexRange({lat,lon,[]}, regionBoundsWhite(1,:), regionBoundsWhite(2,:));
latIndsNorth = latIndsNorth - latInds(1) + 1;
lonIndsNorth = lonIndsNorth - lonInds(1) + 1;
latIndsSouth = latIndsSouth - latInds(1) + 1;
lonIndsSouth = lonIndsSouth - lonInds(1) + 1;
latIndsBlue = latIndsBlue - latInds(1) + 1;
lonIndsBlue = lonIndsBlue - lonInds(1) + 1;
latIndsWhite = latIndsWhite - latInds(1) + 1;
lonIndsWhite = lonIndsWhite - lonInds(1) + 1;

if drawScatter
    
    curLatInds = latIndsBlue;
    curLonInds = lonIndsBlue;

    hotEarly = squeeze(hotFutureEarly);
    hotEarly = hotEarly(curLatInds, curLonInds, :);
    hotEarly = squeeze(nanmean(nanmean(hotEarly,2),1));
    hotLate = squeeze(hotFutureLate);
    hotLate = hotLate(curLatInds, curLonInds, :);
    hotLate = squeeze(nanmean(nanmean(hotLate,2),1));

    dryEarly = squeeze(dryFutureEarly);
    dryEarly = dryEarly(curLatInds, curLonInds, :);
    dryEarly = squeeze(nanmean(nanmean(dryEarly,2),1));
    dryLate = squeeze(dryFutureLate);
    dryLate = dryLate(curLatInds, curLonInds, :);

    wetEarly = squeeze(wetFutureEarly);
    wetEarly = wetEarly(curLatInds, curLonInds, :);
    wetEarly = squeeze(nanmean(nanmean(wetEarly,2),1));
    wetLate = squeeze(wetFutureLate);
    wetLate = wetLate(curLatInds, curLonInds, :);
%         dryLateSig = [];
%         wetLateSig = [];
%         for m = 1:size(dryLate, 3)
%             dd = reshape(dryLate(:,:,m), [numel(dryLate(:,:,m)), 1]) - .1;
%             ww = reshape(wetLate(:,:,m), [numel(wetLate(:,:,m)), 1]) - .1;
%             dryLateSig(m) = kstest2(dd, zeros(size(dd)));
%             wetLateSig(m) = kstest2(ww, zeros(size(ww)));
%         end

    dryLate = squeeze(nanmean(nanmean(dryLate,2),1));
    wetLate = squeeze(nanmean(nanmean(wetLate,2),1));

    hotdryEarly = squeeze(hotDryFutureEarly);
    hotdryEarly = hotdryEarly(curLatInds, curLonInds, :);
    hotdryEarly = squeeze(nanmean(nanmean(hotdryEarly,2),1));
    hotdryLate = squeeze(hotDryFutureLate);
    hotdryLate = hotdryLate(curLatInds, curLonInds, :);
    hotdryLate = squeeze(nanmean(nanmean(hotdryLate,2),1));

    figure('Color', [1,1,1]);
    hold on;
    box on;
    axis square;
    grid on;

    for m = 1:length(dryLate)
        t = text(dryLate(m)*100, hotdryLate(m)*100, num2str(m), 'HorizontalAlignment', 'center', 'Color', 'k');
        t.FontSize = 18;
    end

    plot([0 100], [10 10], '--k');
    plot([10 10], [0 100], '--k');

    xlim([0 50]);
    xlabel('Dry years (%)');
    set(gca, 'XTick', 0:10:50);
    set(gca, 'YTick', 0:10:80);
    ylim([0 80]);
    ylabel('Wet years (%)');
    set(gca,'FontSize', 36);

    set(gcf, 'Position', get(0,'Screensize'));

    if north
        export_fig(['wet-dry-chg-annual-' base '-' rcp '-north.eps']);
    else
        export_fig(['wet-dry-chg-annual-' base '-' rcp '-south.eps']);
    end
    close all;
end












if drawMaps
    % hotFuture = hotFuture-.1;
    % dryFuture = dryFuture-.1;
    % hotDryFuture = hotDryFuture-.1;
    % 
    % find model agreement on direction of change
    for xlat = 1:size(hotFutureLate, 1)
        for ylon = 1:size(hotFutureLate, 2)
            for month = 1:12
                % find median model
                med = nanmedian(squeeze(hotDryFutureLate(xlat, ylon, month, :)));
                % and calculate whether more than 75% of models have same
                % sign as median
                hotDryFutureSig(xlat, ylon, month) = length(find(sign(squeeze(hotDryFutureLate(xlat, ylon, month, :))) == sign(med))) >= .75*length(models);

                % for hot months...
                med = nanmedian(squeeze(hotFutureLate(xlat, ylon, month, :)));
                hotFutureSig(xlat, ylon, month) = length(find(sign(squeeze(hotFutureLate(xlat, ylon, month, :))) == sign(med))) >= .75*length(models);

                % and dry months...
                med = nanmedian(squeeze(dryFutureLate(xlat, ylon, month, :)));
                dryFutureSig(xlat, ylon, month) = length(find(sign(squeeze(dryFutureLate(xlat, ylon, month, :))) == sign(med))) >= .75*length(models);
            end
        end
    end

    for s = 1:size(seasons,1)
        hotFutureFrac = squeeze(nanmedian(nanmean(hotFutureLate(:, :, seasons(s,:), :),3),4));
        dryFutureFrac = squeeze(nanmedian(nanmean(dryFutureLate(:, :, seasons(s,:), :),3),4));
        hotDryFutureFrac = squeeze(nanmedian(nanmean(hotDryFutureLate(:, :, :, :),3),4));

        sig = [];

        for xlat = 1:size(dryFutureLate,1)
            for ylon = 1:size(dryFutureLate,2)
                sig(xlat, ylon) = length(find(sign(nanmean(hotDryFutureLate(xlat, ylon, :, :),3)-.1) == sign(hotDryFutureFrac(xlat, ylon)-.1)));
            end
        end
    %     
    %     hdchg=squeeze(nanmean(nanmean(nanmean(dryFutureLate(latIndsSouth,lonIndsSouth,seasons(s,:),:),3),2),1))-.1
    %     length(find(sign(hdchg)==sign(median(hdchg))))
    %     
        %plotModelData({lat(latInds,lonInds),lon(latInds,lonInds),hotFutureFrac},'nile','caxis',[-.5 .5], 'colormap', brewermap([],'RdBu'));
        %plotModelData({lat(latInds,lonInds),lon(latInds,lonInds),dryFutureFrac},'nile','caxis',[-.5 .5], 'colormap', brewermap([],'RdBu'));
        %plotModelData({lat(latInds,lonInds),lon(latInds,lonInds),hotDryFutureFrac},'nile','caxis',[-.5 .5], 'colormap', brewermap([],'RdBu'));

        result = {lat(latInds,lonInds), lon(latInds,lonInds), hotDryFutureFrac};

        saveData = struct('data', {result}, ...
                          'plotRegion', 'nile', ...
                          'plotRange', [0 .2], ...
                          'cbXTicks', 0:.05:.2, ...
                          'plotTitle', [''], ...
                          'fileTitle', ['hot-dry-years-annual.eps'], ...
                          'plotXUnits', ['Fraction'], ...
                          'blockWater', true, ...
                          'colormap', brewermap([], '*RdBu'), ...
                          'plotCountries', true, ...
                          'statData', sig <= .67*length(models), ...
                          'boxCoords', {[[13 32], [29, 34];
                                         [2 13], [25 42]]});
        plotFromDataFile(saveData);
    end
end