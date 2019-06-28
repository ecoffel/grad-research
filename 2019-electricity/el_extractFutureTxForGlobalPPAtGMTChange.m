
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

useGlobalPlants = true;

if useGlobalPlants
    plantLatLon = csvread('2019-electricity/global-pp-lat-lon-all-cap.csv');
else
    plantLatLon = csvread('2019-electricity/entsoe-nuke-lat-lon.csv');
end


load('2019-electricity/GMTYears.mat');

plantTxTimeSeries = [];

fprintf('loading historical data...\n')

load waterGrid;
waterGrid = logical(waterGrid);

if ~exist('tempNcep')
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

% 1deg, 2deg, 3deg, 4deg
for g = 1:4
    fprintf('processing GMT %d...\n', g);
    
    for model = 1:length(models)
        
        if useGlobalPlants
            fileTarget = ['2019-electricity/gmt-anomaly-temps/global-pp-' num2str(g) 'deg-tx-cmip5-' models{model} '-all-cap.csv'];
        else
            fileTarget = ['2019-electricity/gmt-anomaly-temps/us-eu-pp-' num2str(g) 'deg-tx-cmip5-' models{model} '.csv'];
        end
        
        if exist(fileTarget, 'file')
            continue;
        end
        
        modelPlantTxTimeSeries = [];

        fprintf('loading %s/historical...\n', models{model})
        tempHist = loadDailyData(['E:/data/cmip5/output/' models{model} '/r1i1p1/historical/tasmax/regrid/world'], 'startYear', 1981, 'endYear', 2005);
        if nanmean(nanmean(nanmean(nanmean(nanmean(tempHist{3}))))) > 100
            tempHist{3} = tempHist{3} - 273.15;
        end

        % list of years with this level of GMT warming
        if length(GMTYears{model}) < g
            continue;
        end
        
        curGMTYears = GMTYears{model}{g};
        
        tempFut = {};
        % load future data for current set of future years
        for year = curGMTYears
            curYearTempFut = loadDailyData(['E:/data/cmip5/output/' models{model} '/r1i1p1/' rcp '/tasmax/regrid/world'], 'startYear', year, 'endYear', year);
            if nanmean(nanmean(nanmean(nanmean(nanmean(curYearTempFut{3}))))) > 100
                curYearTempFut{3} = curYearTempFut{3} - 273.15;
            end
            
            if length(tempFut) == 0
                tempFut = curYearTempFut;
            else
                tempFut{3} = cat(3, tempFut{3}, curYearTempFut{3});
            end
        end
            
        
        curPlantTxTimeSeries = [];

        % for all plants
        for i = 1:size(plantLatLon, 1)
            ind = plantLatLon(i,1);
            lat = plantLatLon(i,2);
            lon = plantLatLon(i,3);

            if lon < 0
                lon = lon+360;
            end

            % load historical obs and model data for this plant
            [latIndObs, lonIndObs] = latLonIndex(tempEra, [lat, lon]);
            txObs = reshape(permute(squeeze(tempObsData(latIndObs, lonIndObs, :, :, :)), [3, 2, 1]), [numel(tempObsData(latIndObs, lonIndObs, :, :, :)), 1]);
            decilesHistObs = [];
            % find era deciles for this plant
            for dec = 10:10:100
                decilesHistObs(end+1) = prctile(txObs, dec);
            end

            [latInd, lonInd] = latLonIndex(tempHist, [lat, lon]);
            % make 1d historical model tx time series for plant
            txHist = reshape(permute(squeeze(tempHist{3}(latIndObs, lonIndObs, :, :, :)), [3, 2, 1]), [numel(tempHist{3}(latIndObs, lonIndObs, :, :, :)), 1]);
            decilesHistCmip5 = [];
            % find cmip5 historical deciles for this plant
            for dec = 10:10:100
                decilesHistCmip5(end+1) = prctile(txHist, dec);
            end
        
            % bias corrected tx for all future years for this gmt anom
            txFutBc = [];
            txYears = [];
            txMonths = [];
            txDays = [];
            
            % loop over all future years for current GMT temp anomaly
            for y = 1:length(curGMTYears)
                % make 1d future model tx time series for plant
                txFut1d = reshape(permute(squeeze(tempFut{3}(latInd, lonInd, y, :, :)), [3, 2, 1]), [numel(tempFut{3}(latInd, lonInd, y, :, :)), 1]);
                decilesFutCmip5 = [];
                % find cmip5 historical deciles for this plant
                for dec = 10:10:100
                    decilesFutCmip5(end+1) = prctile(txFut1d, dec);
                end

                % bc is the difference between the decile thresholds in hist cmip5
                % and era
                biasCorrection = decilesHistObs - decilesHistCmip5;

                txFut = squeeze(tempFut{3}(latInd, lonInd, :, :, :));

                % restart future dates fromcurrent year
                curDate = datenum(curGMTYears(y), 1, 1, 1, 0, 0);

                vec = datevec(curDate);
                while vec(1) == curGMTYears(y)
                    txYears(end+1) = vec(1);
                    txMonths(end+1) = vec(2);
                    txDays(end+1) = vec(3);

                    % this day's tx value from the model
                    if length(size(txFut)) == 3
                        curTx = txFut(y, vec(2), vec(3));
                    else
                        curTx = txFut(vec(2), vec(3));
                    end

                    % find which decile it falls into and apply bias correction
                    decileDiff = curTx - decilesFutCmip5;
                    indDec = find(abs(decileDiff) == nanmin(abs(decileDiff)));

                    if isnan(curTx) || length(indDec) == 0
                        txFutBc(end+1) = NaN;
                    else
                        txFutBc(end+1) = curTx + biasCorrection(indDec(1));
                    end

                    curDate = addtodate(curDate, 1, 'day');
                    vec = datevec(curDate);
                end
            end

            if length(curGMTYears)
                if i == 1
                    modelPlantTxTimeSeries(1, :) = txYears;
                    modelPlantTxTimeSeries(2, :) = txMonths;
                    modelPlantTxTimeSeries(3, :) = txDays;
                end

                % add current year of temps to current plant
                modelPlantTxTimeSeries(i+3, :) = txFutBc;
            end
        end
        
        csvwrite(fileTarget, modelPlantTxTimeSeries);   
        
    end

end



