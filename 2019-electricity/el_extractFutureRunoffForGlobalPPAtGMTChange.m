
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
plantData = 'useu';

plantLatLon = csvread(['E:/data/ecoffel/data/projects/electricity/script-data/' plantData '-pp-lat-lon.csv']);

load('E:/data/ecoffel/data/projects/electricity/script-data/GMTYears.mat');

load('2019-electricity/GMTYears.mat');

plantQsTimeSeries = [];

load waterGrid;
waterGrid = logical(waterGrid);


% 1deg, 2deg, 3deg, 4deg
for g = 1:4
    fprintf('processing GMT %d...\n', g);
    
    for model = 1:length(models)
        
        fileTarget = ['E:/data/ecoffel/data/projects/electricity/gmt-anomaly-temps/' plantData '-pp-' num2str(g) 'deg-runoff-cmip5-' models{model} '.csv'];
        fileTargetRaw = ['E:/data/ecoffel/data/projects/electricity/gmt-anomaly-temps/' plantData '-pp-' num2str(g) 'deg-runoff-raw-cmip5-' models{model} '.csv'];
        
        if exist(fileTarget, 'file') && exist(fileTargetRaw, 'file')
            continue;
        end
        
        modelPlantQsTimeSeries = [];
        modelPlantQsRawTimeSeries = [];

        fprintf('loading %s/historical...\n', models{model})
        qsHist = loadMonthlyData(['E:/data/cmip5/output/' models{model} '/mon/r1i1p1/historical/mrro'], 'mrro', 'startYear', 1981, 'endYear', 2005);

        % list of years with this level of GMT warming
        if length(GMTYears{model}) < g
            continue;
        end
        
        curGMTYears = GMTYears{model}{g};
        
        % GMT doesn't occur in this model, skip without writing a CSV
        if length(curGMTYears) == 0
            continue;
        end
        
        qsFut = {};
        % load future data for current set of future years
        for year = curGMTYears
            curYearQsFut = loadMonthlyData(['E:/data/cmip5/output/' models{model} '/mon/r1i1p1/' rcp '/mrro'], 'mrro', 'startYear', year, 'endYear', year);
            
            if length(qsFut) == 0
                qsFut = curYearQsFut;
            else
                qsFut{3} = cat(3, qsFut{3}, curYearQsFut{3});
            end
        end
            
        
        curPlantQsTimeSeries = [];

        % for all plants
        for i = 1:size(plantLatLon, 1)
            ind = plantLatLon(i,1);
            lat = plantLatLon(i,2);
            lon = plantLatLon(i,3);

            if lon < 0
                lon = lon+360;
            end

            [latInd, lonInd] = latLonIndex(qsHist, [lat, lon]);
            % make 1d historical model tx time series for plant
            qsHist1d = reshape(permute(squeeze(qsHist{3}(latInd, lonInd, :, :)), [2, 1]), [numel(qsHist{3}(latInd, lonInd, :, :)), 1]);

            % bias corrected tx for all future years for this gmt anom
            qsFut1dStd = [];
            qsFut1d = [];
            qsYears = [];
            qsMonths = [];
            qsDays = [];
            
            % future qs for this plant
            curPlantQsFut = squeeze(qsFut{3}(latInd, lonInd, :, :));
            
            % loop over all future years for current GMT temp anomaly
            for y = 1:length(curGMTYears)
                
                % restart future dates fromcurrent year
                curDate = datenum(curGMTYears(y), 1, 1, 1, 0, 0);

                vec = datevec(curDate);
                while vec(1) == curGMTYears(y)
                    qsYears(end+1) = vec(1);
                    qsMonths(end+1) = vec(2);
                    qsDays(end+1) = vec(3);

                    % this day's tx value from the model
                    if size(curPlantQsFut, 2) > 1
                        curQs = curPlantQsFut(y, vec(2));
                    else
                        curQs = curPlantQsFut(vec(2));
                    end

                    if isnan(curQs)
                        if ~exist(fileTarget, 'file')
                            qsFut1dStd(end+1) = NaN;
                        end
                        qsFut1d(end+1) = NaN;
                    else
                        % only do this calc if necessary as it is time
                        % consuming
                        if ~exist(fileTarget, 'file')
                            qsFut1dStd(end+1) = (curQs - nanmean(qsHist1d)) ./ nanstd(qsHist1d);
                        end
                        qsFut1d(end+1) = curQs;
                    end

                    curDate = addtodate(curDate, 1, 'day');
                    vec = datevec(curDate);
                end
            end

            if length(curGMTYears)
                if i == 1
                    modelPlantQsTimeSeries(1, :) = qsYears;
                    modelPlantQsTimeSeries(2, :) = qsMonths;
                    modelPlantQsTimeSeries(3, :) = qsDays;
                    
                    modelPlantQsRawTimeSeries(1, :) = qsYears;
                    modelPlantQsRawTimeSeries(2, :) = qsMonths;
                    modelPlantQsRawTimeSeries(3, :) = qsDays;
                end

                % add current year of temps to current plant
                if ~exist(fileTarget, 'file')
                    modelPlantQsTimeSeries(i+3, :) = qsFut1dStd;
                end
                modelPlantQsRawTimeSeries(i+3, :) = qsFut1d;
            end
        end
        
        if ~exist(fileTarget, 'file')
            csvwrite(fileTarget, modelPlantQsTimeSeries);   
        end
        
        if ~exist(fileTargetRaw, 'file')
            csvwrite(fileTargetRaw, modelPlantQsRawTimeSeries);   
        end
        
    end

end



