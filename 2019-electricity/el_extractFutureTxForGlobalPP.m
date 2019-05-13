
dataset = 'e:/data/cmip5/output';

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
          'cesm1-bgc', 'cesm1-cam5', 'cnrm-cm5', 'csiro-mk3-6-0', 'fgoals-g2', ...
          'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'inmcm4', ...
          'ipsl-cm5a-mr', 'miroc5', 'miroc-esm', 'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

rcp = 'rcp85';

startYear = 2050;
endYear = 2080;

plantLatLon = csvread('2019-electricity/entsoe-nuke-lat-lon.csv');

plantTxTimeSeries = [];

fprintf('processing era...\n')

% era data is for 30 yrs, same as the future period
tempEra = loadDailyData('E:\data\era-interim\output\mx2t', 'startYear', 1988, 'endYear', 2018);
if nanmean(nanmean(nanmean(nanmean(nanmean(tempEra{3}))))) > 100
    tempEra{3} = tempEra{3} - 273.15;
end




for model = 1:length(models)
    modelPlantTxTimeSeries = [];
    
    
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
        txClean = [];
        txCleanNoChg = [];
        
        % construct future dates (range from 2020 - 2050)
        curDate = datenum(startYear, 1, 1, 1, 0, 0);
        txYears = [];
        txMonths = [];
        txDays = [];

        for year = 1:size(tx, 1)
            for month = 1:size(tx, 2)
                for day = 1:size(tx, 3)
                    
                    if ~isnan(tx(year, month, day))
                    
                        vec = datevec(curDate);
                        txYears(end+1) = vec(1);
                        txMonths(end+1) = vec(2);
                        txDays(end+1) = vec(3);

                        curDate = addtodate(curDate, 1, 'day');
                        txClean(end+1) = tx(year, month, day) + (txFut(month) - txHist(month));
                        txCleanNoChg(end+1) = tx(year, month, day);
                        
                    end
                end
            end
        end

        % add date/time data (these should be same length as
        % data time series
        if i == 1
            modelPlantTxTimeSeries(1, :) = txYears;
            modelPlantTxTimeSeries(2, :) = txMonths;
            modelPlantTxTimeSeries(3, :) = txDays;
        end
        
        % add current year of temps to current plant
        modelPlantTxTimeSeries(i+3, :) = txClean;
    end


    csvwrite(['2019-electricity/future-temps/entnsoe-nuke-pp-rcp85-tx-cmip5-' models{model} '-' num2str(startYear) '-' num2str(endYear) '.csv'], modelPlantTxTimeSeries);   
    
end



