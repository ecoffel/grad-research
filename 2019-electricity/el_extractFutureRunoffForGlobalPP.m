
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

% fprintf('loading gldas...\n');
% qsGldas = loadMonthlyData('E:\data\gldas\output\vic-1\Qs', 'Qs', 'startYear', 1988, 'endYear', 2018);
% qsbGldas = loadMonthlyData('E:\data\gldas\output\vic-1\Qsb', 'Qsb', 'startYear', 1988, 'endYear', 2018);
% 
% qsGldas{3} = qsGldas{3} + qsbGldas{3};
% qsGldas{2}(qsGldas{2} < 0) = 360 + qsGldas{2}(qsGldas{2} < 0);
% 
% monthLens = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
% for m = 1:12
%     qsGldas{3}(:, :, :, m) = qsGldas{3}(:, :, :, m) .* 3600 .* 24 .* monthLens(m);
% end

plantRunoffTimeSeries = [];


modelChg = [];

for model = 1:length(models)
    modelPlantTxTimeSeries = [];
        
    fprintf('processing %s/historical...\n', models{model})
    runoffHist = loadMonthlyData(['E:/data/cmip5/output/' models{model} '/mon/r1i1p1/historical/mrro'], 'mrro', 'startYear', 1981, 'endYear', 2005);
        
    fprintf('processing %s/future...\n', models{model})
    runoffFut = loadMonthlyData(['E:/data/cmip5/output/' models{model} '/mon/r1i1p1/' rcp '/mrro'], 'mrro', 'startYear', startYear, 'endYear', endYear);
  
    monthLens = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    for m = 1:12
        runoffHist{3}(:, :, :, m) = runoffHist{3}(:, :, :, m) .* 3600 .* 24 .* monthLens(m);
        runoffFut{3}(:, :, :, m) = runoffFut{3}(:, :, :, m) .* 3600 .* 24 .* monthLens(m);
    end
    
    curPlantQsTimeSeries = [];

    for i = 1:size(plantLatLon, 1)
        ind = plantLatLon(i,1);
        lat = plantLatLon(i,2);
        lon = plantLatLon(i,3);
        if lon < 0
            lon = lon+360;
        end

        [latIndCmip5, lonIndCmip5] = latLonIndex(runoffHist, [lat, lon]);
        
        cmip5MrroHist = squeeze(runoffHist{3}(latIndCmip5, lonIndCmip5, :, :));
        cmip5MrroFut = squeeze(runoffFut{3}(latIndCmip5, lonIndCmip5, :, :));

        qsHistTimeSeries = [];
        qsFutTimeSeries = [];
        
        % construct historical time series
        curDate = datenum(1981, 1, 1, 1, 0, 0);
        vec = datevec(curDate);
        while vec(1) < 2005+1
            if vec(2) == 7 || vec(2) == 8
                qsHistTimeSeries(end+1) = cmip5MrroHist(vec(1)-1981+1, vec(2));
            end
            
            curDate = addtodate(curDate, 1, 'day');
            vec = datevec(curDate);
        end
        
        
        % construct future dates (range from 2020 - 2050)
        curDate = datenum(startYear, 1, 1, 1, 0, 0);
        qsYears = [];
        qsMonths = [];
        qsDays = [];
        
        vec = datevec(curDate);
        while vec(1) < endYear+1
            if vec(2) == 7 || vec(2) == 8
                qsYears(end+1) = vec(1);
                qsMonths(end+1) = vec(2);
                qsDays(end+1) = vec(3);

                qsFutTimeSeries(end+1) = cmip5MrroFut(vec(1)-startYear+1, vec(2));
            end
            
            curDate = addtodate(curDate, 1, 'day');
            vec = datevec(curDate);
        end
        
        qsAnomTimeSeries = (qsFutTimeSeries-nanmean(qsHistTimeSeries)) ./ nanstd(qsHistTimeSeries);
        
%         for year = 1:size(cmip5MrroFut, 1)
%             for month = 1:size(cmip5MrroFut, 2)                    
%                 vec = datevec(curDate);
%                 qsYears(end+1) = vec(1);
%                 qsMonths(end+1) = vec(2);
% 
%                 curDate = addtodate(curDate, 1, 'month');
%             end
%         end

        % add date/time data (these should be same length as
        % data time series
        if i == 1
            modelPlantTxTimeSeries(1, :) = qsYears;
            modelPlantTxTimeSeries(2, :) = qsMonths;
            modelPlantTxTimeSeries(3, :) = qsDays;
        end
        
        % add current year of temps to current plant
        modelPlantTxTimeSeries(i+3, :) = qsAnomTimeSeries;
    end


    modelChg = [modelChg; nanmean(modelPlantTxTimeSeries(3:end,:),2)];
    
    csvwrite(['2019-electricity/future-temps/us-eu-pp-rcp85-runoff-anom-cmip5-' models{model} '-' num2str(startYear) '-' num2str(endYear) '.csv'], modelPlantTxTimeSeries);   
    
end


