models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
          'cmcc-cm', 'cmcc-cms'};
 
 %'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc-esm', ...
  %        'mpi-esm-mr', 'mri-cgcm3'};
                 
%                 'cnrm-cm5', 'csiro-mk3-6-0', ...
 %         'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc'};
               
              
                %  };
              
load waterGrid;
load lat;
load lon;
waterGrid = logical(waterGrid);

baseDir = '2017-concurrent-heat/daily-bowen-temp';

for m = 1:length(models)
    ['processing ' models{m} '...']
    
    % load historical data for this model
    load([baseDir '/dailyBowenTemp-historical-' models{m} '-1985-2004.mat']);
    bowenHistorical = dailyBowenTemp;
    clear dailyBowenTemp;
    
    % load rcp85 data for this model
    load([baseDir '/dailyBowenTemp-rcp85-' models{m} '-2060-2080.mat']);
    bowenRcp85 = dailyBowenTemp;
    clear dailyBowenTemp;
    
    % cells which contain fit data for each gridbox
    fitDataHistorical = {};
    fitDataRcp85 = {};
    
    
    % loop over months
    for month = 1:length(bowenHistorical{1})
        
        ['processing month ' num2str(month) '...']
        
        % expand fit cell array if needed
        if length(fitDataHistorical) < month
            fitDataHistorical{month} = {};
            fitDataRcp85{month} = {};
        end
        
        % all x coords
        for xlat = 1:length(bowenHistorical{1}{month})
            
            % expand fit cell array if needed
            if length(fitDataHistorical{month}) < xlat
                fitDataHistorical{month}{xlat} = {};
                fitDataRcp85{month}{xlat} = {};
            end
            
            % all y coords
            for ylon = 1:length(bowenHistorical{1}{month}{xlat})
                
                % expand fit cell array if needed
                if length(fitDataHistorical{month}{xlat}) < ylon
                    fitDataHistorical{month}{xlat}{ylon} = {};
                    fitDataRcp85{month}{xlat}{ylon} = {};
                end
                
                % value will be empty list if water grid cell or no data -
                % leave cell set to {}
                
                % otherwise, compute fit for historical data
                if length(bowenHistorical{1}{month}{xlat}{ylon}) > 0
                    
                    % find non-nan indices
                    ind = find(~isnan(bowenHistorical{1}{month}{xlat}{ylon}));
                    
                    % require at least 100 non-nan days to fit model
                    if length(ind) > 100
                        % generate fit objects for linear, quadratic, and cubic
                        f = fitlm(bowenHistorical{1}{month}{xlat}{ylon}(ind)', bowenHistorical{2}{month}{xlat}{ylon}(ind)', 'poly2');

                        % add fit objects to current cell
                        fitDataHistorical{month}{xlat}{ylon} = f;
                    end 
                end
                
                % process future data
                if length(bowenRcp85{1}{month}{xlat}{ylon}) > 0
                    
                    % find non-nan indices
                    ind = find(~isnan(bowenRcp85{1}{month}{xlat}{ylon}));
                    
                    % require at least 100 non-nan days to fit model
                    if length(ind) > 100
                        % generate fit objects for linear, quadratic, and cubic
                        f = fitlm(bowenRcp85{1}{month}{xlat}{ylon}(ind)', bowenRcp85{2}{month}{xlat}{ylon}(ind)', 'poly2');

                        % add fit objects to current cell
                        fitDataRcp85{month}{xlat}{ylon} = f;
                    end 
                end
                
            end
        end
    end
    
    clear bowenHistorical bowenRcp85;
    
    bowenTempFit = {fitDataHistorical, fitDataRcp85};
    save(['2017-concurrent-heat/bowen-temp-fit/bowenTempFit-' models{m} '.mat'], 'bowenTempFit', '-v7.3');
    clear bowenTempFit;
    
end

