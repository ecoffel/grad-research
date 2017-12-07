
hotFuture = hotFuture-.1;
dryFuture = dryFuture-.1;
hotDryFuture = hotDryFuture-.1;

% find model agreement on direction of change
for xlat = 1:size(hotFuture, 1)
    for ylon = 1:size(hotFuture, 2)
        for month = 1:12
            % find median model
            med = nanmedian(squeeze(hotDryFuture(xlat, ylon, month, :)));
            % and calculate whether more than 75% of models have same
            % sign as median
            hotDryFutureSig(xlat, ylon, month) = length(find(sign(squeeze(hotDryFuture(xlat, ylon, month, :))) == sign(med))) >= .75*length(models);

            % for hot months...
            med = nanmedian(squeeze(hotFuture(xlat, ylon, month, :)));
            hotFutureSig(xlat, ylon, month) = length(find(sign(squeeze(hotFuture(xlat, ylon, month, :))) == sign(med))) >= .75*length(models);

            % and dry months...
            med = nanmedian(squeeze(dryFuture(xlat, ylon, month, :)));
            dryFutureSig(xlat, ylon, month) = length(find(sign(squeeze(dryFuture(xlat, ylon, month, :))) == sign(med))) >= .75*length(models);
        end
    end
end

for s = 1:size(seasons,1)
    hotFutureFrac = squeeze(nanmedian(nanmean(hotFuture(:, :, seasons(s,:), :),3),4));
    dryFutureFrac = squeeze(nanmedian(nanmean(dryFuture(:, :, seasons(s,:), :),3),4));
    hotDryFutureFrac = squeeze(nanmedian(nanmean(hotDryFuture(:, :, seasons(s,:), :),3),4));

    %plotModelData({lat(latInds,lonInds),lon(latInds,lonInds),hotFutureFrac},'nile','caxis',[-.5 .5], 'colormap', brewermap([],'RdBu'));
    %plotModelData({lat(latInds,lonInds),lon(latInds,lonInds),dryFutureFrac},'nile','caxis',[-.5 .5], 'colormap', brewermap([],'RdBu'));
    %plotModelData({lat(latInds,lonInds),lon(latInds,lonInds),hotDryFutureFrac},'nile','caxis',[-.5 .5], 'colormap', brewermap([],'RdBu'));
    
    result = {lat(latInds,lonInds), lon(latInds,lonInds), dryFutureFrac};

    saveData = struct('data', {result}, ...
                      'plotRegion', 'nile', ...
                      'plotRange', [-.1 .1], ...
                      'cbXTicks', -.1:.1:.1, ...
                      'plotTitle', ['Dry months'], ...
                      'fileTitle', ['dry-months.png'], ...
                      'plotXUnits', ['Percent difference'], ...
                      'blockWater', true, ...
                      'colormap', brewermap([], 'RdBu'), ...
                      'plotCountries', true, ...
                      'boxCoords', {[[13 32], [29, 34];
                                     [2 13], [25 42]]});
    plotFromDataFile(saveData);
end