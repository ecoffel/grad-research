
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

startYear = 2050;
endYear = 2080;

plantLatLon = csvread('2019-electricity/entsoe-nuke-lat-lon.csv');

plantTxTimeSeries = [];

fprintf('loading era...\n')

load waterGrid;
waterGrid = logical(waterGrid);

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

for model = 1:length(models)
    modelPlantTxTimeSeries = [];
    
    if exist(['2019-electricity/future-temps/us-eu-pp-' rcp '-tx-cmip5-' models{model} '-' num2str(startYear) '-' num2str(endYear) '.csv'], 'file')
        %continue;
    end
        
    fprintf('loading %s/historical...\n', models{model})
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
        
        
        % make 1d future model tx time series for plant
        txFut1d = reshape(permute(squeeze(tempFut{3}(latInd, lonInd, :, :, :)), [3, 2, 1]), [numel(tempFut{3}(latInd, lonInd, :, :, :)), 1]);
        decilesFutCmip5 = [];
        % find cmip5 historical deciles for this plant
        for dec = 10:10:100
            decilesFutCmip5(end+1) = prctile(txFut1d, dec);
        end
        
        % bc is the difference between the decile thresholds in hist cmip5
        % and era
        biasCorrection = decilesHistObs - decilesHistCmip5;
        
        txFut = squeeze(tempFut{3}(latInd, lonInd, :, :, :));

        % construct future dates (range from 2020 - 2050)
        curDate = datenum(startYear, 1, 1, 1, 0, 0);
        txYears = [];
        txMonths = [];
        txDays = [];
        txHistBc = [];
        txFutBc = [];

        vec = datevec(curDate);
        while vec(1) <= endYear
            txYears(end+1) = vec(1);
            txMonths(end+1) = vec(2);
            txDays(end+1) = vec(3);
            
            % this day's tx value from the model
            curTx = txFut(vec(1)-startYear+1, vec(2), vec(3));
            
            % find which decile it falls into and apply bias correction
            decileDiff = curTx - decilesFutCmip5;
            indDec = find(abs(decileDiff) == nanmin(abs(decileDiff)));
            
            if isnan(curTx) || length(indDec) == 0
                txFutBc(end+1) = NaN;
            else
                txFutBc(end+1) = curTx + biasCorrection(indDec);
            end
            
            curDate = addtodate(curDate, 1, 'day');
            vec = datevec(curDate);
        end

        
        % add date/time data (these should be same length as
        % data time series
        if i == 1
            modelPlantTxTimeSeries(1, :) = txYears;
            modelPlantTxTimeSeries(2, :) = txMonths;
            modelPlantTxTimeSeries(3, :) = txDays;
        end
        
        % add current year of temps to current plant
        modelPlantTxTimeSeries(i+3, :) = txFutBc;
    end


    csvwrite(['2019-electricity/future-temps/us-eu-pp-' rcp '-tx-cmip5-' models{model} '-' num2str(startYear) '-' num2str(endYear) '.csv'], modelPlantTxTimeSeries);   
    
end



