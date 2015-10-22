
for s = 1:length(seasons)
    plotTitle = ['NCEP/CMIP5 ' seasons{s} ' precip dist'];
    fileTitle = ['precipDist-cmip5-ncep' '-' baseVar '-' seasons{s} '-' fileTimeStr '.' exportformat];
    
    baseNcepSeasonalLinear = reshape(ncepBaseSeasonal(:,:,:,s), [size(ncepBaseSeasonal(:,:,:,s), 1)*size(ncepBaseSeasonal(:,:,:,s), 2)*size(ncepBaseSeasonal(:,:,:,s), 3), 1]);
    baseCmip5SeasonalLinear = reshape(cmip5BaseSeasonal(:,:,:,s), [size(cmip5BaseSeasonal(:,:,:,s), 1)*size(cmip5BaseSeasonal(:,:,:,s), 2)*size(cmip5BaseSeasonal(:,:,:,s), 3), 1]);
    
    bins = 0:5:50;
    ncepBaseCount = histc(baseNcepSeasonalLinear, bins);
    cmip5BaseCount = histc(baseCmip5SeasonalLinear, bins);
    
    
    groupCount = [];
    for i = 1:length(ncepBaseCount)
        groupCount = [groupCount; [ncepBaseCount(i) cmip5BaseCount(i)]];
    end
    
    if length(futureSeasonal) > 0
        futureSeasonalLinear = reshape(futureSeasonal(:,:,:,s), [size(futureSeasonal(:,:,:,s), 1)*size(futureSeasonal(:,:,:,s), 2)*size(futureSeasonal(:,:,:,s), 3), 1]);
        futureCount = histc(futureSeasonalLinear, bins);
    end

    figure('Color', [1,1,1]);
    hold on;
    bar(bins(2:end)', groupCount(2:end, :));
    ylim([0 200]);
    title(plotTitle, 'FontSize', 28);
    set(gca, 'FontSize', 24);
    xlabel('mm/day');
    ylabel('occurences');
    set(gcf, 'Position', get(0,'Screensize'));
    tightfig;
    eval(['export_fig ' fileTitle ';']);
    
end

