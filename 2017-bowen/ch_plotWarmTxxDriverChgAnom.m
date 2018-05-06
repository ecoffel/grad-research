txxWarmAnom = false;
warmSeasonAnom = true;

percentChg = false;
excludeWinter = false;
var = 'ef';

prcStr = '';
if percentChg
    prcStr = '-percent';
end

if txxWarmAnom
    load(['E:\data\projects\bowen\derived-chg\' var 'ChgWarmTxxAnom' prcStr '.mat']);
    eval(['chg = ' var 'ChgWarmTxxAnom;']);
    fileName = ['pr-chg-txx-warm-anom' prcStr '.eps'];
    plotTitle = 'PR change in TXx month vs. warm season';
elseif warmSeasonAnom
    if excludeWinter
        load(['E:\data\projects\bowen\derived-chg\' var 'ChgWarmAnom' prcStr '-nowint.mat']);
    else
        load(['E:\data\projects\bowen\derived-chg\' var 'ChgWarmAnom' prcStr '.mat']);
    end
    eval(['chg = ' var 'ChgWarmAnom;']);
    fileName = ['ef-chg-warm-anom' prcStr '.eps'];
    plotTitle = 'EF change in warm season vs. annual mean';
end

load lat;
load lon;

if strcmp(var, 'pr') && ~percentChg
    chg = chg .* 3600 .* 24;
end

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



if percentChg
    saveData = struct('data', {result}, ...
                          'plotRegion', 'world', ...
                          'plotRange', [-20 20], ...
                          'cbXTicks', -20:5:20, ...
                          'plotTitle', plotTitle, ...
                          'fileTitle', fileName, ...
                          'plotXUnits', ['%'], ...
                          'blockWater', true, ...
                          'colormap', brewermap([], '*RdBu'), ...
                          'boxCoords', {regions([2,4,7,10], :)});
    plotFromDataFile(saveData);
else
    saveData = struct('data', {result}, ...
                          'plotRegion', 'world', ...
                          'plotRange', [-.05 .05], ...
                          'cbXTicks', -.05:.025:.05, ...
                          'plotTitle', plotTitle, ...
                          'fileTitle', fileName, ...
                          'plotXUnits', ['Fraction'], ...
                          'blockWater', true, ...
                          'colormap', brewermap([], 'BrBG'), ...
                          'boxCoords', {regions([2,4,7,10], :)});
    plotFromDataFile(saveData);
end