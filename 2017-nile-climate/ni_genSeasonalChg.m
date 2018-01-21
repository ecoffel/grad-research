
    models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
                  'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                  'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                  'hadgem2-es', 'ipsl-cm5a-mr', 'inmcm4', 'miroc5', 'miroc-esm', ...
                  'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

    rcp = 'rcp85';
    var = 'pr';
    monthly = true;
    timePeriodBase = [1980 2004];
    timePeriodFuture = [2056 2080];

for model = 1:length(models)
    monthlyBase = {};
    monthlyFuture = {};
    monthlyChg = [];

    fprintf('loading base %s...\n', models{model});
    if monthly
        varBase = loadMonthlyData(['E:\data\cmip5\output\' models{model} '\mon\r1i1p1\historical\' var '\regrid\world'], var, 'startYear', timePeriodBase(1), 'endYear', timePeriodBase(end));
    else
        varBase = loadDailyData(['E:\data\cmip5\output\' models{model} '\r1i1p1\historical\' var '\regrid\world'], 'startYear', timePeriodBase(1), 'endYear', timePeriodBase(end));
        varBase = dailyToMonthly(varBase);
    end
    
    fprintf('loading future %s...\n', models{model});
    if monthly
        varFuture = loadMonthlyData(['E:\data\cmip5\output\' models{model} '\mon\r1i1p1\' rcp '\' var '\regrid\world'], 'pr', 'startYear', timePeriodFuture(1), 'endYear', timePeriodFuture(end));
    else
        varFuture = loadDailyData(['E:\data\cmip5\output\' models{model} '\r1i1p1\' rcp '\' var '\regrid\world'], 'startYear', timePeriodFuture(1), 'endYear', timePeriodFuture(end));
        varFuture = dailyToMonthly(varFuture);
    end
    
    
    switch var
        case 'pr'
            varBase{3} = varBase{3} .* 3600 .* 24;
            varFuture{3} = varFuture{3} .* 3600 .* 24;
        case 'tasmax'
            if nanmean(nanmean(nanmean(nanmean(varBase{3})))) > 100
                varBase{3} = varBase{3} - 273.15;
            end
            if nanmean(nanmean(nanmean(nanmean(varFuture{3})))) > 100
                varFuture{3} = varFuture{3} - 273.15;
            end
    end
    
    lat = varBase{1};
    lon = varBase{2};
    
    % whole nile region
    regionBounds = [[2 32]; [25, 44]];
    [latInds, lonInds] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));
    
    for month = 1:12
        regionPBase = squeeze(nanmean(varBase{3}(latInds, lonInds, :, month), 4));
        monthlyBase{month} = regionPBase;
        
        regionPFuture = squeeze(nanmean(varFuture{3}(latInds, lonInds, :, month), 4));
        monthlyFuture{month} = regionPFuture;
        
        monthlyChg(:, :, month) = nanmean(monthlyFuture{month}, 3) - nanmean(monthlyBase{month}, 3);
    end
    
    save(['2017-nile-climate/output/' var '-monthly-chg-cmip5-' rcp '-' num2str(timePeriodFuture(1)) '-' num2str(timePeriodFuture(end)) '-' models{model} '.mat'], 'monthlyChg');
end
