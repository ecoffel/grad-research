
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

plantData = 'world'

decades = [2020:2029;
           2030:2039;
           2040:2049;
           2050:2059;
           2060:2069;
           2070:2079;
           2080:2089];
% startYear = 2020;
% endYear = 2050;

plantLatLon = csvread(['E:/data/ecoffel/data/projects/electricity/script-data/' plantData '-pp-lat-lon.csv']);

plantTxTimeSeries = [];



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
    
    fprintf('loading %s/historical...\n', models{model})
    tempHist = loadDailyData(['E:/data/cmip5/output/' models{model} '/r1i1p1/historical/tasmax/regrid/world'], 'startYear', 1981, 'endYear', 2005);
    if nanmean(nanmean(nanmean(nanmean(nanmean(tempHist{3}))))) > 100
        tempHist{3} = tempHist{3} - 273.15;
    end
        
    for d = 1:size(decades, 1)

        startYear = decades(d, 1);
        endYear = decades(d, end);
        
        modelPlantTxTimeSeries = [];

        if exist(['e:/data/ecoffel/data/projects/electricity/future-temps/' plantData '-pp-' rcp '-txx-cmip5-' models{model} '-' num2str(startYear) '-' num2str(endYear) '.csv'], 'file')
            %continue;
        end

        fprintf('processing %s/%d...\n', models{model}, startYear)
        tempFut = loadDailyData(['E:/data/cmip5/output/' models{model} '/r1i1p1/' rcp '/tasmax/regrid/world'], 'startYear', startYear, 'endYear', endYear);
        if nanmean(nanmean(nanmean(nanmean(nanmean(tempFut{3}))))) > 100
            tempFut{3} = tempFut{3} - 273.15;
        end       

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

            
            
            [latIndObs, lonIndObs] = latLonIndex(tempEra, [lat, lon]);
            txObs = reshape(permute(squeeze(tempObsData(latIndObs, lonIndObs, :, :, :)), [3, 2, 1]), [numel(tempObsData(latIndObs, lonIndObs, :, :, :)), 1]);
            % find era 95th % deciles for this plant (only correcting txx)
            decilesHistObs = prctile(txObs, 95);

            [latInd, lonInd] = latLonIndex(tempHist, [lat, lon]);
            % make 1d historical model tx time series for plant
            txHist = reshape(permute(squeeze(tempHist{3}(latIndObs, lonIndObs, :, :, :)), [3, 2, 1]), [numel(tempHist{3}(latIndObs, lonIndObs, :, :, :)), 1]);
            % find cmip5 historical deciles for this plant (again only
            % 95th)
            decilesHistCmip5 = prctile(txHist, 95);

            
            % bc is the difference between the decile thresholds in hist cmip5
            % and era
            biasCorrection = decilesHistObs - decilesHistCmip5;
            
            txxFutBc = [];
            % find txx values
            for year = 1:size(tempFut{3}, 3)
                txx = nanmax(nanmax(tempFut{3}(latInd, lonInd, year, :, :)));
                
                txxFutBc(end+1) = txx + biasCorrection;
            end

            % add current year of temps to current plant
            modelPlantTxTimeSeries(i, :) = txxFutBc;
        end

        csvwrite(['e:/data/ecoffel/data/projects/electricity/future-temps/' plantData '-pp-' rcp '-txx-cmip5-' models{model} '-' num2str(startYear) '-' num2str(endYear) '.csv'], modelPlantTxTimeSeries);   
    end
    
end



