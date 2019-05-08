
dataset = 'e:/data/cmip5/output';

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', ...
          'canesm2', 'cnrm-cm5', 'csiro-mk3-6-0', 'fgoals-g2', 'gfdl-esm2g', ...
          'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
          'miroc5', 'mri-cgcm3', 'noresm1-m'};

rcp = 'rcp85';

startYear = 2050;
endYear = 2080;

plantLatLon = csvread('2019-electricity/entsoe-nuke-lat-lon.csv');

plantTxTimeSeries = [];

fprintf('processing era...\n')

% era data is for 30 yrs, same as the future period
tempEra = loadDailyData('E:\data\era-interim\output\mx2t\regrid\world', 'startYear', 1988, 'endYear', 2018);
if nanmean(nanmean(nanmean(nanmean(nanmean(tempEra{3}))))) > 100
    tempEra{3} = tempEra{3} - 273.15;
end


% construct future dates (range from 2020 - 2050)
curDate = datenum(startYear, 1, 1, 1, 0, 0);
txYears = [];
txMonths = [];
txDays = [];

for year = 1:size(tempEra{3}, 3)
    for month = 1:size(tempEra{3}, 4)
        for day = 1:size(tempEra{3}, 5)
            vec = datevec(curDate);
            txYears(end+1) = vec(1);
            txMonths(end+1) = vec(2);
            txDays(end+1) = vec(3);

            curDate = addtodate(curDate, 1, 'day');
        end
    end
end

for model = 1:length(models)
    modelPlantTxTimeSeries = [];
    
    % add date/time data (these should be same length as
    % data time series
    modelPlantTxTimeSeries(1, :) = txYears;
    modelPlantTxTimeSeries(2, :) = txMonths;
    modelPlantTxTimeSeries(3, :) = txDays;

    
%     if exist(['2019-electricity/entnsoe-nuke-pp-rcp85-tx-cmip5-' models{model} '-2020-2050.csv'], 'file')
%         %continue;
%     end
    
    fprintf('processing %s/historical...\n', models{model})
    tempHist = loadDailyData(['E:/data/cmip5/output/' models{model} '/r1i1p1/historical/tasmax/regrid/world'], 'startYear', 1981, 'endYear', 2005);
    if nanmean(nanmean(nanmean(nanmean(nanmean(tempHist{3}))))) > 100
        tempHist{3} = tempHist{3} - 273.15;
    end
        
    fprintf('processing %s/future...\n', models{model})

    tempFut = loadDailyData(['E:/data/cmip5/output/' models{model} '/r1i1p1/' rcp '/tasmax/regrid/world'], 'startYear', startYear, 'endYear', endYear);
    if nanmean(nanmean(nanmean(nanmean(nanmean(tempFut{3}))))) > 100
        tempFut{3} = tempFut{3} - 273.15;
    end       

    curPlantTxTimeSeries = [];

    for i = 1:size(plantLatLon, 1)
        ind = plantLatLon(i,1);
        lat = plantLatLon(i,2);
        lon = plantLatLon(i,3);
        if lon < 0
            lon = lon+360;
        end

        [latInd, lonInd] = latLonIndex(tempFut, [lat, lon]);
        
        txHist = squeeze(nanmean(nanmean(tempHist{3}(latInd, lonInd, :, :, :), 5), 3));
        txFut = squeeze(nanmean(nanmean(tempFut{3}(latInd, lonInd, :, :, :), 5), 3));

        tx = squeeze(tempEra{3}(latInd, lonInd, :, :, :));
        for month = 1:12
            tx(:, month, :) = tx(:, month, :) + (txFut(month) - txHist(month));
        end

        txClean = reshape(permute(tx, [3, 2, 1]), [numel(tx), 1]);

        % add current year of temps to current plant
        modelPlantTxTimeSeries(i+3, :) = txClean;
    end


    csvwrite(['2019-electricity/future-temps/entnsoe-nuke-pp-rcp85-tx-cmip5-' models{model} '-2050-2080.csv'], modelPlantTxTimeSeries);   
    
end



