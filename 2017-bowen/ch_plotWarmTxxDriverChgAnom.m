var = 'hfss';

load(['E:\data\projects\bowen\derived-chg\' var 'ChgWarmTxxAnom.mat']);
eval(['chg = ' var 'ChgWarmTxxAnom;']);

load lat;
load lon;

%chg = chg .* 3600 .* 24;

regions = [[[-90 90], [0 360]]; ...             % world
           [[30 42], [-91 -75] + 360]; ...     % eastern us
           [[30 41], [-95 -75] + 360]; ...      % southeast us
           [[45, 55], [10, 35]]; ...            % Europe
           [[35 50], [-10+360 45]]; ...        % Med
           [[5 20], [-90 -45]+360]; ...         % Northern SA
           [[-10, 7], [-75, -62]+360]; ...      % Amazon
           [[-10 10], [15, 30]]; ...            % central africa
           [[15 30], [-4 29]]; ...              % north africa
           [[22 40], [105 122]]; ...               % china
           [[-24 -8], [14 40]]];                      % south africa

result = {lat, lon, nanmedian(chg,3)};
       
saveData = struct('data', {result}, ...
                      'plotRegion', 'world', ...
                      'plotRange', [-5 5], ...
                      'cbXTicks', -5:1:5, ...
                      'plotTitle', 'SH change in TXx month vs. warm season', ...
                      'fileTitle', 'hfss-chg-txx-warm-anom.eps', ...
                      'plotXUnits', ['W/m^2'], ...
                      'blockWater', true, ...
                      'colormap', brewermap([], '*RdBu'), ...
                      'boxCoords', {regions([2,4,7,10], :)});
plotFromDataFile(saveData);