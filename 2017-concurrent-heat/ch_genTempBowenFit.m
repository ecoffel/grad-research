models = {'access1-0'};%, 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
                  %'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                  %'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                  %'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc-esm', ...
                  %'mpi-esm-mr', 'mri-cgcm3'};
              
load waterGrid;
load lat;
load lon;
waterGrid = logical(waterGrid);

baseDir = 'f:/data/daily-bowen-temp';

regionNames = {'World', ...
                'Eastern U.S.', ...
                'Western Europe', ...
                'Amazon', ...
                'India', ...
                'China', ...
                'Central Africa', ...
                'Tropics'};
regionAb = {'world', ...
            'us', ...
            'europe', ...
            'amazon', ...
            'india', ...
            'china', ...
            'africa', ...
            'tropics'};
            
regions = [[[-90 90], [0 360]]; ...             % world
           [[30 48], [-97 -62] + 360]; ...     % USNE
           [[35, 60], [-10+360, 20]]; ...       % Europe
           [[-10, 10], [-70, -40]+360]; ...     % Amazon
           [[8, 28], [67, 90]]; ...             % India
           [[20, 40], [100, 125]]; ...          % China
           [[-10 10], [15, 30]]; ...            % central Africa
           [[-20 20], [0 360]]];                % Tropics
           
regionLatLonInd = {};

% loop over all regions to find lat/lon indicies
for i = 1:size(regions, 1)
    [latIndexRange, lonIndexRange] = latLonIndexRange({lat, lon, []}, regions(i, 1:2), regions(i, 3:4));
    regionLatLonInd{i} = {latIndexRange, lonIndexRange};
end

regionId = 3;

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
    for month = 8%1:length(bowenHistorical{1})
        
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
                        [f1, gof1] = fit(bowenHistorical{1}{month}{xlat}{ylon}(ind)', bowenHistorical{2}{month}{xlat}{ylon}(ind)', 'poly1');
                        [f2, gof2] = fit(bowenHistorical{1}{month}{xlat}{ylon}(ind)', bowenHistorical{2}{month}{xlat}{ylon}(ind)', 'poly2');
                        [f3, gof3] = fit(bowenHistorical{1}{month}{xlat}{ylon}(ind)', bowenHistorical{2}{month}{xlat}{ylon}(ind)', 'poly3');

                        % add fit objects to current cell
                        fitDataHistorical{month}{xlat}{ylon} = {{f1, gof1}, {f2, gof2}, {f3, gof3}};
                    end 
                end
                
                % process future data
                if length(bowenRcp85{1}{month}{xlat}{ylon}) > 0
                    
                    % find non-nan indices
                    ind = find(~isnan(bowenRcp85{1}{month}{xlat}{ylon}));
                    
                    % require at least 100 non-nan days to fit model
                    if length(ind) > 100
                        % generate fit objects for linear, quadratic, and cubic
                        [f1, gof1] = fit(bowenRcp85{1}{month}{xlat}{ylon}(ind)', bowenRcp85{2}{month}{xlat}{ylon}(ind)', 'poly1');
                        [f2, gof2] = fit(bowenRcp85{1}{month}{xlat}{ylon}(ind)', bowenRcp85{2}{month}{xlat}{ylon}(ind)', 'poly2');
                        [f3, gof3] = fit(bowenRcp85{1}{month}{xlat}{ylon}(ind)', bowenRcp85{2}{month}{xlat}{ylon}(ind)', 'poly3');

                        % add fit objects to current cell
                        fitDataRcp85{month}{xlat}{ylon} = {{f1, gof1}, {f2, gof2}, {f3, gof3}};
                    end 
                end
                
            end
        end
    end
    
    clear bowenHistorical bowenRcp85;
    
    save(['2017-concurrent-heat/bowen-temp-fit/bowenTempFitHistorical-' models{m} '.mat'], 'fitDataHistorical');
    save(['2017-concurrent-heat/bowen-temp-fit/bowenTempFitRcp85-' models{m} '.mat'], 'fitDataRcp85');
    clear bowenTempFit;
    
end

