% generate mean annual changes for each model at a given temp percentile
% for each gridbox

season = 'all';
basePeriod = 'past';

% add in base models and add to the base loading loop

baseDataset = 'cmip5';
baseVar = 'tasmax';

% baseModels = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
%               'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
%               'ec-earth', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
%               'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'ipsl-cm5b-lr', 'miroc5', 'miroc-esm', ...
%               'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
 baseModels = {'access1-0'};
baseRcps = {'historical'};
baseEnsemble = 'r1i1p1';

futureDataset = 'cmip5';
futureVar = 'tasmax';

% futureModels = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
%               'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
%               'ec-earth', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
%               'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'ipsl-cm5b-lr', 'miroc5', 'miroc-esm', ...
%               'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
 futureModels = {'access1-0'};
futureRcps = {'rcp85'};
futureEnsemble = 'r1i1p1';

baseRegrid = true;
futureRegrid = true;

region = 'world';
basePeriodYears = 1981:2004;
%basePeriodYears = 1980:1990;
futurePeriodYears = 2060:2080;
%futurePeriodYears = 2050:2060;

baseDir = 'e:/data';
yearStep = 1;

if strcmp(season, 'summer')
    months = [6 7 8];
elseif strcmp(season, 'winter')
    months = [12 1 2];
elseif strcmp(season, 'all')
    months = 1:12;
end

load lat;
load lon;

% look at change above this base period temperature percentile
thresh = [1 10:10:90 99];

numDays = 372;

baseData = [];
futureData = [];

load waterGrid;
waterGrid = logical(waterGrid);

% mean temps (above thresh) in the base period
baseThresh = [];
futureThresh = [];
chgData = [];

['loading base: ' baseDataset]
for m = 1:length(baseModels)
    curModel = baseModels{m};

    ['loading base model ' curModel '...']

    for y = basePeriodYears(1):yearStep:basePeriodYears(end)
        ['year ' num2str(y) '...']

        baseDaily = loadDailyData([baseDir '/' baseDataset '/output/' curModel '/' baseEnsemble '/' baseRcps{1} '/' baseVar '/regrid/' region], 'yearStart', y, 'yearEnd', (y+yearStep)-1);

        if baseDaily{3}(1,1,1,1,1) > 100
            baseDaily{3} = baseDaily{3} - 273.15;
        end

        baseDaily3d = reshape(baseDaily{3}, [size(baseDaily{3}, 1), size(baseDaily{3}, 2), ...
                                             size(baseDaily{3}, 3)*size(baseDaily{3}, 4)*size(baseDaily{3}, 5)]);

        for d = 1:size(baseDaily3d, 3)
            curGrid = baseDaily3d(:, :, d);
            curGrid(waterGrid) = NaN;
            baseDaily3d(:, :, d) = curGrid;
        end
        
        for t = 1:length(thresh)
            for xlat = 1:size(baseDaily3d, 1)
                for ylon = 1:size(baseDaily3d, 2)
                    
                    if isnan(baseDaily3d(xlat, ylon, 1))
                        continue;
                    end
                        
                    baseData(xlat, ylon, m, y-basePeriodYears(1)+1, t) = prctile(squeeze(baseDaily3d(xlat, ylon, :)), thresh(t));
                end
            end
        end
        
        clear baseDaily baseDaily3d;
    end

%     for t = 1:length(thresh)
%         curThresh = thresh(t);
%         for x = 1:size(baseData, 1)
%             for y = 1:size(baseData, 2)
%                 curGridCell = squeeze(reshape(baseData(x, y, :, :), [size(baseData, 3)*size(baseData, 4), 1]));
%                 baseThresh(x, y, m, t) = prctile(curGridCell, curThresh);
%             end
%         end
%     end
    
%    clear baseData;
end

% ------------ load future data -------------    

['loading future: ' futureDataset]
for m = 1:length(futureModels)
        curModel = futureModels{m};

    ['loading future model ' curModel '...']
    
    for y = futurePeriodYears(1):yearStep:futurePeriodYears(end)
        ['year ' num2str(y) '...']

        futureDaily = loadDailyData([baseDir '/' futureDataset '/output/' curModel '/' futureEnsemble '/' futureRcps{1} '/' futureVar '/regrid/' region], 'yearStart', y, 'yearEnd', (y+yearStep)-1);

        if futureDaily{3}(1,1,1,1,1) > 100
            futureDaily{3} = futureDaily{3} - 273.15;
        end

        futureDaily3d = reshape(futureDaily{3}, [size(futureDaily{3}, 1), size(futureDaily{3}, 2), ...
                                                 size(futureDaily{3}, 3)*size(futureDaily{3}, 4)*size(futureDaily{3}, 5)]);
        
        
        for d = 1:size(futureDaily3d, 3)
            curGrid = futureDaily3d(:, :, d);
            curGrid(waterGrid) = NaN;
            futureDaily3d(:, :, d) = curGrid;
        end
        
        for t = 1:length(thresh)
            for xlat = 1:size(futureDaily3d, 1)
                for ylon = 1:size(futureDaily3d, 2)
                    
                    if isnan(futureDaily3d(xlat, ylon, 1))
                        continue;
                    end
                    
                    futureData(xlat, ylon, m, y-futurePeriodYears(1)+1, t) = prctile(squeeze(futureDaily3d(xlat, ylon, :)), thresh(t));
                end
            end
        end

        clear futureDaily futureDaily3d;
    end
    
%     for t = 1:length(thresh)
%         curThresh = thresh(t);
%         for x = 1:size(futureData, 1)
%             for y = 1:size(futureData, 2)
%                 for year = 1:size(futureData, 4)
%                     curGridCell = squeeze(reshape(futureData(x, y, :, year), [size(futureData, 3), 1]));
%                     futureThresh(x, y, year, m) = prctile(curGridCell, curThresh);
%                     chgData(x, y, year, m, t) = futureThresh(x, y, year, m) - baseThresh(x, y, m, t);
%                 end
%             end
%         end
%     end

    %clear futureData;
end



% save(['chgData-cmip5-' futureRcps{1} '.mat'], 'chgData');
for t = 1:size(chgData, 3)
    for y = 1:size(chgData,4)
    curGrid = chgData(:, :, t,y);
    curGrid(waterGrid) = NaN;
    chgData(:, :, t,y) = curGrid;
    end
end
