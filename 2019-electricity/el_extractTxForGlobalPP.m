
dataset = 'e:/data/cmip5/output';

models = {'bcc-csm1-1-m', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'gfdl-esm2g', 'gfdl-esm2m', ...
              'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

startYear = 2020;
endYear = 2050;

plantLatLon = csvread('2019-electricity/entsoe-nuke-lat-lon.csv');

plantTxTimeSeries = [];

for y = startYear:endYear

    curPlantTxTimeSeries = [];
    
    fprintf('processing %d\n', y)
    
%     temp = loadDailyData('E:\data\era-interim\output\mx2t', 'startYear', y, 'endYear', y);
%     if nanmean(nanmean(nanmean(nanmean(nanmean(temp{3}))))) > 100
%         temp{3} = temp{3} - 273.15;
%     end
    
    temp = loadDailyData('E:\data\cpc-temp\output\tmax', 'startYear', y, 'endYear', y);
    if nanmean(nanmean(nanmean(nanmean(nanmean(temp{3}))))) > 100
        temp{3} = temp{3} - 273.15;
    end
    

    for i = 1:size(plantLatLon, 1)
        ind = plantLatLon(i,1);
        lat = plantLatLon(i,2);
        lon = plantLatLon(i,3);
        if lon < 0
            lon = lon+360;
        end

        [latEraInd, lonEraInd] = latLonIndex(temp, [lat, lon]);

        tx = squeeze(temp{3}(latEraInd, lonEraInd, :, :, :));

        curDate = datenum(y, 1, 1, 1, 0, 0);
        txClean = [];
        txYears = [];
        txMonths = [];
        txDays = [];

        for year = 1:size(tx, 1)
            for month = 1:size(tx, 2)
                for day = 1:size(tx, 3)

                    vec = datevec(curDate);
                    txYears(end+1) = vec(1);
                    txMonths(end+1) = vec(2);
                    txDays(end+1) = vec(3);
                    
                    curTx = squeeze(tx(year, month, day));
                    if ~isnan(curTx)
                        txClean(end+1) = curTx;
                    else
                        txClean(end+1) = NaN;
                    end
                    
                    curDate = addtodate(curDate, 1, 'day');
                end
            end
        end

        if i == 1
            curPlantTxTimeSeries(1, :) = txYears;
            curPlantTxTimeSeries(2, :) = txMonths;
            curPlantTxTimeSeries(3, :) = txDays;
        end

        % add current year of temps to current plant
        curPlantTxTimeSeries(i+3, :) = txClean;
    end
    
    plantTxTimeSeries = cat(2, plantTxTimeSeries, curPlantTxTimeSeries);
    
end

csvwrite('2019-electricity/entnsoe-nuke-pp-tx-cpc.csv', plantTxTimeSeries);

