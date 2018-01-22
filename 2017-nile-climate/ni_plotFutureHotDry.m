base = 'cmip5';

% late period
load(['2017-nile-climate\output\dryFuture-' base '-rcp85-2056-2080.mat']);
dryFutureLate = dryFuture;
load(['2017-nile-climate\output\wetFuture-' base '-rcp85-2056-2080.mat']);
wetFutureLate = wetFuture;
load(['2017-nile-climate\output\hotFuture-' base '-rcp85-2056-2080.mat']);
hotFutureLate = hotFuture;
load(['2017-nile-climate\output\hotDryFuture-' base '-rcp85-2056-2080.mat']);
hotDryFutureLate = hotDryFuture;

% early period
load(['2017-nile-climate\output\dryFuture-' base '-rcp85-2031-2055.mat']);
dryFutureEarly = dryFuture;
load(['2017-nile-climate\output\wetFuture-' base '-rcp85-2031-2055.mat']);
wetFutureEarly = wetFuture;
load(['2017-nile-climate\output\hotFuture-' base '-rcp85-2031-2055.mat']);
hotFutureEarly = hotFuture;
load(['2017-nile-climate\output\hotDryFuture-' base '-rcp85-2031-2055.mat']);
hotDryFutureEarly = hotDryFuture;

drawScatter = false;
drawMaps = true;
north = false;

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
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

[latIndsNorth, lonIndsNorth] = latLonIndexRange({lat,lon,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
[latIndsSouth, lonIndsSouth] = latLonIndexRange({lat,lon,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));
latIndsNorth = latIndsNorth - latInds(1) + 1;
lonIndsNorth = lonIndsNorth - lonInds(1) + 1;
latIndsSouth = latIndsSouth - latInds(1) + 1;
lonIndsSouth = lonIndsSouth - lonInds(1) + 1;

if drawScatter
    
    if north
        curLatInds = latIndsNorth;
        curLonInds = lonIndsNorth;
    else
        curLatInds = latIndsSouth;
        curLonInds = lonIndsSouth;
    end
    
    for s = 1:size(seasons, 1)
        hotEarly = squeeze(nanmean(hotFutureEarly(:,:,seasons(s,:),:),3));
        hotEarly = hotEarly(curLatInds, curLonInds, :);
        hotEarly = squeeze(nanmean(nanmean(hotEarly,2),1));
        hotLate = squeeze(nanmean(hotFutureLate(:,:,seasons(s,:),:),3));
        hotLate = hotLate(curLatInds, curLonInds, :);
        hotLate = squeeze(nanmean(nanmean(hotLate,2),1));

        dryEarly = squeeze(nanmean(dryFutureEarly(:,:,seasons(s,:),:),3));
        dryEarly = dryEarly(curLatInds, curLonInds, :);
        dryEarly = squeeze(nanmean(nanmean(dryEarly,2),1));
        dryLate = squeeze(nanmean(dryFutureLate(:,:,seasons(s,:),:),3));
        dryLate = dryLate(curLatInds, curLonInds, :);
        dryLate = squeeze(nanmean(nanmean(dryLate,2),1));

        wetEarly = squeeze(nanmean(wetFutureEarly(:,:,seasons(s,:),:),3));
        wetEarly = wetEarly(curLatInds, curLonInds, :);
        wetEarly = squeeze(nanmean(nanmean(wetEarly,2),1));
        wetLate = squeeze(nanmean(wetFutureLate(:,:,seasons(s,:),:),3));
        wetLate = wetLate(curLatInds, curLonInds, :);
        wetLate = squeeze(nanmean(nanmean(wetLate,2),1));

        hotdryEarly = squeeze(nanmean(hotDryFutureEarly(:,:,seasons(s,:),:),3));
        hotdryEarly = hotdryEarly(curLatInds, curLonInds, :);
        hotdryEarly = squeeze(nanmean(nanmean(hotdryEarly,2),1));
        hotdryLate = squeeze(nanmean(hotDryFutureLate(:,:,seasons(s,:),:),3));
        hotdryLate = hotdryLate(curLatInds, curLonInds, :);
        hotdryLate = squeeze(nanmean(nanmean(hotdryLate,2),1));

        figure('Color', [1,1,1]);
        hold on;
        box on;
        axis square;
        grid on;

        b = boxplot([hotEarly hotLate wetEarly wetLate dryEarly dryLate hotdryEarly hotdryLate], ...
                     'colors', repmat('br', 1, 8), 'positions', [.8 1.2 1.8 2.2 2.8 3.2 3.8 4.2]);

        for bind = 1:size(b, 2)
            if mod(bind,2) ~= 0
                set(b(:,bind), {'LineWidth', 'Color'}, {2, [85/255.0, 158/255.0, 237/255.0]})
                lines = findobj(b(:, bind), 'type', 'line', 'Tag', 'Median');
                set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2); 
            else
                set(b(:, bind), {'LineWidth', 'Color'}, {2, [247, 92, 81]./255.0})
                lines = findobj(b(:, bind), 'type', 'line', 'Tag', 'Median');
                set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2); 
            end
        end

        plot([0 5], [.1 .1], '--k', 'LineWidth', 2);

        ylim([0 1]);
        xlim([0 5]);
        set(gca, 'YTick', [0 .1 .2 .3 .4 .5 .6 .7 .8 .9 1]);
        ylabel('Fraction of Years');
        set(gca, 'XTick', [1,2,3,4], 'XTickLabels', {'Hot (> 90%)', 'Wet (> 90%)', 'Dry (< 10%)', 'Hot & dry'});
        set(gca, 'FontSize', 36);
        xtickangle(45);
        title([seasonNames{s}]);
        set(gcf, 'Position', get(0,'Screensize'));
        if north
            export_fig(['hot-dry-fraction-' seasonNames{s} '-' base '-north.eps']);
        else
            export_fig(['hot-dry-fraction-' seasonNames{s} '-' base '-south.eps']);
        end
        close all;
    end
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

        result = {lat(latInds,lonInds), lon(latInds,lonInds), hotDryFutureFrac - .1};

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