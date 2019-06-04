
dataset = 'e:/data/cmip5/output';

models = {'bcc-csm1-1-m', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'gfdl-esm2g', 'gfdl-esm2m', ...
              'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

rcp = 'rcp85';

startYear = 2020;
endYear = 2050;

plantLatLon = csvread('2019-electricity/entsoe-nuke-lat-lon.csv');

fprintf('loading gldas...\n');
qsGldas = loadMonthlyData('E:\data\gldas\output\vic-1\Qs', 'Qs', 'startYear', startYear, 'endYear', endYear);
qsbGldas = loadMonthlyData('E:\data\gldas\output\vic-1\Qsb', 'Qsb', 'startYear', startYear, 'endYear', endYear);

qsGldas{3} = qsGldas{3} + qsbGldas{3};
qsGldas{2}(qsGldas{2} < 0) = 360 + qsGldas{2}(qsGldas{2} < 0);

monthLens = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
for m = 1:12
    qsGldas{3}(:, :, :, m) = qsGldas{3}(:, :, :, m) .* 3600 .* 24 .* monthLens(m);
end

plantRunoffTimeSeries = [];

for model = 1:length(models)
    modelPlantTxTimeSeries = [];
        
    fprintf('processing %s/historical...\n', models{model})
    runoffHist = loadMonthData(['E:/data/cmip5/output/' models{model} '/mon/r1i1p1/historical/mrro'], 'startYear', 1981, 'endYear', 2005);
    if nanmean(nanmean(nanmean(nanmean(nanmean(runoffHist{3}))))) > 100
        runoffHist{3} = runoffHist{3} - 273.15;
    end
        
    fprintf('processing %s/future...\n', models{model})

    runoffFut = loadDailyData(['E:/data/cmip5/output/' models{model} '/mon/r1i1p1/' rcp '/mrro'], 'startYear', startYear, 'endYear', endYear);
    if nanmean(nanmean(nanmean(nanmean(nanmean(runoffFut{3}))))) > 100
        runoffFut{3} = runoffFut{3} - 273.15;
    end       

    curPlantTxTimeSeries = [];

    for i = 1:size(plantLatLon, 1)
        ind = plantLatLon(i,1);
        lat = plantLatLon(i,2);
        lon = plantLatLon(i,3);
        if lon < 0
            lon = lon+360;
        end

        [latInd, lonInd] = latLonIndex(qsGldas, [lat, lon]);
        
        cmip5MrroHist = squeeze(nanmean(nanmean(runoffHist{3}(latInd, lonInd, :, :, :), 5), 3));
        cmip5MrroFut = squeeze(nanmean(nanmean(runoffFut{3}(latInd, lonInd, :, :, :), 5), 3));

        qs = squeeze(qsGldas{3}(latInd, lonInd, :, :, :));
        txClean = [];
        txCleanNoChg = [];
        
        % construct future dates (range from 2020 - 2050)
        curDate = datenum(startYear, 1, 1, 1, 0, 0);
        txYears = [];
        txMonths = [];
        txDays = [];

        for year = 1:size(qs, 1)
            for month = 1:size(qs, 2)
                for day = 1:size(qs, 3)
                    
                    if ~isnan(qs(year, month, day))
                    
                        vec = datevec(curDate);
                        txYears(end+1) = vec(1);
                        txMonths(end+1) = vec(2);
                        txDays(end+1) = vec(3);

                        curDate = addtodate(curDate, 1, 'day');
                        txClean(end+1) = qs(year, month, day) + (cmip5MrroFut(month) - cmip5MrroHist(month));
                        txCleanNoChg(end+1) = qs(year, month, day);
                        
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


    csvwrite(['2019-electricity/future-temps/entnsoe-nuke-pp-rcp85-runoff-cmip5-' models{model} '-' num2str(startYear) '-' num2str(endYear) '.csv'], modelPlantTxTimeSeries);   
    
end



