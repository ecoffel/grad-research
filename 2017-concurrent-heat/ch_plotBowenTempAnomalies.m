
% mean bowen ratio at each temperature bin
bowenTempRelHistorical = [];
bowenTempRelRcp85 = [];

% number of data points in each temperatuer bin
bowenTempCntHistorical = [];
bowenTempCntRcp85 = [];

% all models with bowen-temp relationships
models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
                  'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                  'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                  'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc-esm', ...
                  'mpi-esm-mr', 'mri-cgcm3'};


load lat;
load lon;
              
% loop over all models and load bowen-temp relationship files
for model = 1:length(models)
    load(['2017-concurrent-heat\bowen-temp\bowenTemp-' models{model} '-historical-1985-2004.mat']);
    
    % calculate mean at each bin and store current model
    curBowenTempRel = bowenTemp{1} ./ bowenTemp{2};
    
    % save number of temperature points in each bin
    curBowenTempCnt = bowenTemp{2};
    
    % save current data
    bowenTempRelHistorical(:, :, :, model) = curBowenTempRel;
    bowenTempCntHistorical(:, :, :, model) = curBowenTempCnt;
    
    % load future data
    load(['2017-concurrent-heat\bowen-temp\bowenTemp-' models{model} '-rcp85-2060-2080.mat']);
    
    % calculate mean at each bin and store current model
    curBowenTempRel = bowenTemp{1} ./ bowenTemp{2};
    
    % save number of temperature points in each bin
    curBowenTempCnt = bowenTemp{2};
    
    bowenTempRelRcp85(:, :, :, model) = curBowenTempRel;
    bowenTempCntRcp85(:, :, :, model) = curBowenTempCnt;
end
              
% temperature bins in bowen-temp relationship files
binsHistorical = -50:5:60;
binsRcp85 = 0:5:50;

regionNames = {'World', ...
                'Eastern U.S.', ...
                'Western Europe', ...
                'Amazon', ...
                'India', ...
                'China', ...
                'Tropics'};
regionAb = {'world', ...
            'us', ...
            'europe', ...
            'amazon', ...
            'india', ...
            'china', ...
            'tropics'};
            
regions = [[[-90 90], [0 360]]; ...             % world
           [[30 55], [-100 -62] + 360]; ...     % USNE
           [[35, 60], [-10+360, 20]]; ...       % Europe
           [[-10, 10], [-70, -40]+360]; ...     % Amazon
           [[8, 28], [67, 90]]; ...             % India
           [[20, 40], [100, 125]]; ...          % China
           [[-20 20], [0 360]]];                % Tropics
           
regionLatLonInd = {};

% loop over all regions to find lat/lon indicies
for i = 1:size(regions, 1)
    [latIndexRange, lonIndexRange] = latLonIndexRange({lat, lon, []}, regions(i, 1:2), regions(i, 3:4));
    regionLatLonInd{i} = {latIndexRange, lonIndexRange};
end
