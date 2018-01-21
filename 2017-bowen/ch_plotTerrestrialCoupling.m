models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

warmSeason = false;
months = [6 7 8];

baseDir = 'e:/data/projects/bowen/mrso-chg-data/';

load lat; load lon;
load waterGrid;
waterGrid = logical(waterGrid);

seasons = [[12 1 2];
           [3 4 5];
           [6 7 8];
           [9 10 11]];

% load hottest seasons for each grid cell
load('2017-bowen/hottest-season-ncep.mat');

TC = zeros(size(lat, 1), size(lat, 2), length(models));
TC(TC == 0) = NaN;

for m = 1:length(models)
    
    fprintf('loading %s...\n', models{m});
    mrsoHistorical = loadMonthlyData(['e:/data/cmip5/output/' models{m} '/mon/r1i1p1/historical/mrso/regrid/world'], 'mrso', 'startYear', 1980, 'endYear', 2004);
    hflsHistorical = loadMonthlyData(['e:/data/cmip5/output/' models{m} '/mon/r1i1p1/historical/hfls/regrid/world'], 'hfls', 'startYear', 1980, 'endYear', 2004);
    
    fprintf('calculating TC for %s...\n', models{m});
    for xlat = 15:75
        for ylon = 1:size(lat, 2)
            if waterGrid(xlat, ylon) 
                continue;
            end
            
            if warmSeason
                months = seasons(hottestSeason(xlat, ylon), :);
            end
            
            mrso = squeeze(nanmean(mrsoHistorical{3}(xlat, ylon, :, months), 4));
            hfls = squeeze(nanmean(hflsHistorical{3}(xlat, ylon, :, months), 4));
            
            % skip all zero tiles or those with nan or those all the
            % same...
            if length(find(mrso==0)) > 0 || length(find(isnan(mrso))) > 0 || length(find(mrso==median(mrso))) == length(mrso) || ...
               length(find(isnan(hfls))) > 0 || length(find(hfls == 0)) > 0
                continue;
            end
            
            mrsoStd = nanstd(mrso);
            slope = fit(mrso, hfls, 'poly1');
            slope = slope.p1;
            TC(xlat, ylon, m) = mrsoStd * slope;
 
        end
    end
    
end

TCHflsJJA = TC;
save('e:/data/projects/bowen/derived-chg/TCHflsJJA.mat', 'TCHflsJJA');