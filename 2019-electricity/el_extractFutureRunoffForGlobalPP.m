
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

for model = 1:length(models)
    
%     fprintf('loading %s/historical...\n', models{model})
%     qsHist = loadMonthlyData(['E:/data/cmip5/output/' models{model} '/mon/r1i1p1/historical/mrro/'], 'mrro', 'startYear', 1981, 'endYear', 2005);
        
    for d = 1:size(decades, 1)
        
        startYear = decades(d, 1);
        endYear = decades(d, end);
        
        modelPlantQsTimeSeries = [];

        if exist(['e:/data/ecoffel/data/projects/electricity/future-temps/' plantData '-pp-' rcp '-runoff-cmip5-' models{model} '-' num2str(startYear) '-' num2str(endYear) '.csv'], 'file')
            continue;
        end

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
            % make 1d historical model tx time series for plant
%             qsHist1d = reshape(permute(squeeze(qsHist{3}(latInd, lonInd, :, :)), [2, 1]), [numel(qsHist{3}(latInd, lonInd, :, :)), 1]);

            % compute historical STD
%             qsHistMean = nanmean(qsHist1d);
%             qsHistStd = nanstd(qsHist1d);

            curQsFut = squeeze(qsFut{3}(latInd, lonInd, :, :, :));

            % construct future dates
            curDate = datenum(startYear, 1, 1, 1, 0, 0);
            qsYears = [];
            qsMonths = [];
            qsDays = [];
            qsFutData = [];

            vec = datevec(curDate);
            while vec(1) <= endYear
                qsYears(end+1) = vec(1);
                qsMonths(end+1) = vec(2);
                qsDays(end+1) = vec(3);

                % this day's tx value from the model
                curDayQsFut = curQsFut(vec(1)-startYear+1, vec(2));

                qsFutData(end+1) = curDayQsFut;

                curDate = addtodate(curDate, 1, 'day');
                vec = datevec(curDate);
            end


            % add date/time data (these should be same length as
            % data time series
            if i == 1
                modelPlantQsTimeSeries(1, :) = qsYears;
                modelPlantQsTimeSeries(2, :) = qsMonths;
                modelPlantQsTimeSeries(3, :) = qsDays;
            end

            % add current year of temps to current plant
    %         modelPlantQsTimeSeries(i+3, :) = (qsFutData-qsHistMean) ./ qsHistStd;
            modelPlantQsTimeSeries(i+3, :) = qsFutData;
        end


        csvwrite(['e:/data/ecoffel/data/projects/electricity/future-temps/' plantData '-pp-' rcp '-runoff-cmip5-' models{model} '-' num2str(startYear) '-' num2str(endYear) '.csv'], modelPlantQsTimeSeries);   
    end
end



