
dataset = 'e:/data/cmip5/output';

% models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
%           'cesm1-bgc', 'cesm1-cam5', 'cnrm-cm5', 'csiro-mk3-6-0', 'fgoals-g2', ...
%           'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'inmcm4', ...
%           'ipsl-cm5a-mr', 'miroc5', 'miroc-esm', 'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

models = {'bcc-csm1-1-m', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'gfdl-esm2g', 'gfdl-esm2m', ...
              'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
      
      
rcp = 'rcp85';

% world, useu, entsoe-nuke
plantData = 'world';

plantLatLon = csvread(['E:/data/ecoffel/data/projects/electricity/script-data/' plantData '-pp-lat-lon.csv']);

decades = [2020:2029;
           2030:2039;
           2040:2049;
           2050:2059;
           2060:2069;
           2070:2079;
           2080:2089];
       
plantQsTimeSeries = [];

load waterGrid;
waterGrid = logical(waterGrid);

if ~exist('tempObsData')
    fprintf('loading historical temps...\n');
    
    % load historical era...
    tempEra = loadDailyData('E:\data\era-interim\output\mx2t\regrid\world', 'startYear', 1981, 'endYear', 2005);
    if nanmean(nanmean(nanmean(nanmean(nanmean(tempEra{3}))))) > 100
        tempEra{3} = tempEra{3} - 273.15;
    end

    tempCpc = loadDailyData('E:\data\cpc-temp\output\tmax\regrid\world', 'startYear', 1981, 'endYear', 2005);
    if nanmean(nanmean(nanmean(nanmean(nanmean(tempCpc{3}))))) > 100
        tempCpc{3} = tempCpc{3} - 273.15;
    end

    tempNcep = loadDailyData('E:\data\ncep-reanalysis\output\tmax\regrid\world', 'startYear', 1981, 'endYear', 2005);
    if nanmean(nanmean(nanmean(nanmean(nanmean(tempNcep{3}))))) > 100
        tempNcep{3} = tempNcep{3} - 273.15;
    end


    tempObsData = (tempEra{3}+tempCpc{3}+tempNcep{3}) ./ 3;
end

for model = 1:length(models)
        
    for d = 1:size(decades, 1)
        
        startYear = decades(d, 1);
        endYear = decades(d, end);
        
        if exist(['e:/data/ecoffel/data/projects/electricity/future-temps/' plantData '-pp-' rcp '-runoff-at-txx-cmip5-' models{model} '-' num2str(startYear) '-' num2str(endYear) '.csv'], 'file')
            continue;
        end
                
        fprintf('loading temps for %s/%d...\n', models{model}, startYear)
        tempFut = loadDailyData(['E:/data/cmip5/output/' models{model} '/r1i1p1/' rcp '/tasmax/regrid/world'], 'startYear', startYear, 'endYear', endYear);
        if nanmean(nanmean(nanmean(nanmean(nanmean(tempFut{3}))))) > 100
            tempFut{3} = tempFut{3} - 273.15;
        end
        
        modelPlantQsTimeSeries = [];

        fprintf('processing %s/future...\n', models{model})
        qsFut = loadMonthlyData(['E:/data/cmip5/output/' models{model} '/mon/r1i1p1/' rcp '/mrro/'], 'mrro', 'startYear', startYear, 'endYear', endYear);

        curPlantTxTimeSeries = [];

        for i = 1:size(plantLatLon, 1)
            
            if mod(i, 1000) == 0
                fprintf('plant %d\n', i);
            end
            
            ind = plantLatLon(i,1);
            lat = plantLatLon(i,2);
            lon = plantLatLon(i,3);

            if lon < 0
                lon = lon+360;
            end

            [latInd, lonInd] = latLonIndex(qsFut, [lat, lon]);
            [latIndTemp, lonIndTemp] = latLonIndex(tempFut, [lat, lon]);

            qsFutData = [];
            
            % find months when txx occurs for each year in decade for
            % current plant
            txxMonths = [];
            for year = 1:size(tempFut{3}, 3)
                curTxx = -1;
                curTxxMonth = -1;
                
                for month = 1:12
                    mx = nanmax(squeeze(tempFut{3}(latIndTemp, lonIndTemp, year, month, :)));
                    if curTxx == -1 || mx > curTxx
                        curTxx = mx;
                        curTxxMonth = month;
                    end
                end
                txxMonths(end+1) = curTxxMonth;
                qsFutData(end+1) = nanmean(squeeze(qsFut{3}(latInd, lonInd, year, curTxxMonth, :)));
            end

            modelPlantQsTimeSeries(i, :) = qsFutData;
        end


        csvwrite(['e:/data/ecoffel/data/projects/electricity/future-temps/' plantData '-pp-' rcp '-runoff-at-txx-cmip5-' models{model} '-' num2str(startYear) '-' num2str(endYear) '.csv'], modelPlantQsTimeSeries);   
    end
end






