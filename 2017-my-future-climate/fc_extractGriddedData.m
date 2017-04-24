% find relationship between global temperature and gridcell characteristics
% for each GCM

baseDir = 'f:/data/cmip5/output/';
models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'ec-earth', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'ipsl-cm5b-lr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

timePeriod = 1981:2004;          
rcp = 'historical';
ensemble = 'r1i1p1';
var = 'tasmax';

latBounds = [30 55];
lonBounds = [-100 -62]+360;

for m = 1:length(models)
    curModel = models{m};

    % parameters to calculate for each model
    globalMeanTemp = [];
    monthlyMax = [];
    monthlyMin = [];
    monthlyMean = [];
    daysAbove90 = [];
    daysAbove100 = [];
    daysBelow32 = [];
    
    ['loading ' curModel ' base']
    for y = timePeriod(1):1:timePeriod(end)
        
        curYearIndex = y-timePeriod(1)+1;
        
        ['year ' num2str(y) '...']
        baseDaily = loadDailyData([baseDir curModel '/' ensemble '/' rcp '/' var '/regrid/world/'], 'yearStart', y, 'yearEnd', (y+1)-1);
        
        % K->C if necessary
        if baseDaily{3}(1,1,1,1,1) > 100
            baseDaily{3} = baseDaily{3} - 273.15;
        end
        
        % global mean temp for this year
        globalMeanTemp(curYearIndex) = nanmean(nanmean(nanmean(nanmean(nanmean(baseDaily{3})))));
        
        [latInd, lonInd] = latLonIndexRange(baseDaily, latBounds, lonBounds);
        
        % x, y, month, year
        monthlyMean(:, :, :, curYearIndex) = nanmean(squeeze(baseDaily{3}(latInd, lonInd, :, :, :)), 4);
        monthlyMin(:, :, :, curYearIndex) = nanmin(squeeze(baseDaily{3}(latInd, lonInd, :, :, :)), [], 4);
        monthlyMax(:, :, :, curYearIndex) = nanmax(squeeze(baseDaily{3}(latInd, lonInd, :, :, :)), [], 4);
        
        % calc days above 90, 100, and below 32 here
        
        clear baseDaily baseExtTmp;
    end
    
    % save global temperature
    dlmwrite(['2017-my-future-climate/data/global-' curModel '-' rcp '.txt'], globalMeanTemp, 'precision', 3);
    
    if ~exist(['2017-my-future-climate/data/' curModel])
        mkdir(['2017-my-future-climate/data/' curModel]);
    end
    
    if ~exist(['2017-my-future-climate/data/' curModel '/' rcp])
        mkdir(['2017-my-future-climate/data/' curModel '/' rcp]);
    end
    
    % save monthly parameters for each x/y grid point
    for xlat = 1:size(monthlyMean, 1)
        for ylon = 1:size(monthlyMean, 2)
            for month = 1:size(monthlyMean, 3)
                % monthly mean
                dlmwrite(['2017-my-future-climate/data/' curModel '/' rcp '/monthlyMean-' num2str(xlat) '-' num2str(ylon) '.txt'], monthlyMean(xlat, ylon, month, :), '-append', 'precision', 3);
                
                % monthly min
                dlmwrite(['2017-my-future-climate/data/' curModel '/' rcp '/monthlyMin-' num2str(xlat) '-' num2str(ylon) '.txt'], monthlyMin(xlat, ylon, month, :), '-append', 'precision', 3);
                
                % monthly max
                dlmwrite(['2017-my-future-climate/data/' curModel '/' rcp '/monthlyMax-' num2str(xlat) '-' num2str(ylon) '.txt'], monthlyMax(xlat, ylon, month, :), '-append', 'precision', 3);
            end
        end
    end
    
end



