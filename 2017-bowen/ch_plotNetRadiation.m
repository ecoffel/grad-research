load lat;
load lon;
load waterGrid;
waterGrid = logical(waterGrid);

regions = [[[-90 90], [0 360]]; ...             % world
           [[30 42], [-91 -75] + 360]; ...     % eastern us
           [[30 41], [-95 -75] + 360]; ...      % southeast us
           [[45, 55], [10, 35]]; ...            % Europe
           [[35 50], [-10+360 45]]; ...        % Med
           [[5 20], [-90 -45]+360]; ...         % Northern SA
           [[-10, 1], [-75, -53]+360]; ...      % Amazon
           [[-10 10], [15, 30]]];                % central africa
                      
sigChg = [];

load e:/data/projects/bowen/derived-chg/rsdsChg-absolute;
load e:/data/projects/bowen/derived-chg/rsusChg-absolute;
load e:/data/projects/bowen/derived-chg/rldsChg-absolute;
load e:/data/projects/bowen/derived-chg/rlusChg-absolute;

%load e:/data/projects/bowen/derived-chg/rsdt-absolute-chg-all;
%load e:/data/projects/bowen/derived-chg/rsut-absolute-chg-all;

rsdsChg(isinf(rsdsChg) | abs(rsdsChg) > 1000) = NaN;
rsusChg(isinf(rsusChg) | abs(rsusChg) > 1000) = NaN;
rlusChg(isinf(rlusChg) | abs(rlusChg) > 1000) = NaN;
rldsChg(isinf(rldsChg) | abs(rldsChg) > 1000) = NaN;

%load e:/data/projects/bowen/derived-chg/hfss-absolute-chg-all;
%load e:/data/projects/bowen/derived-chg/hfls-absolute-chg-all;

load 2017-bowen/hottest-season-ncep;

seasons = [[12 1 2];
           [3 4 5];
           [6 7 8];
           [9 10 11]];

surfSwNetChg = squeeze(rsdsChg - rsusChg);
surfLwNetChg = squeeze(rldsChg - rlusChg);

%heatFluxChg = squeeze(hfssChg+hflsChg);

net = surfSwNetChg;

%topSwNetChg = net;
%save('e:/data/projects/bowen/derived-chg/topSwNet-absolute-chg-all.mat', 'topSwNetChg');

%save('e:/data/projects/bowen/derived-chg/surfSwNet.mat', 'surfSwNetChg');

warmNet = zeros(size(net, 1), size(net, 2));
warmNet(warmNet == 0) = NaN;

for xlat = 1:size(lat, 1)
    for ylon = 1:size(lat, 2)
        if waterGrid(xlat, ylon)
            sigChg(xlat, ylon) = 0;
            continue;
        end
        med = squeeze(nanmedian(nanmean(net(xlat, ylon, :, seasons(hottestSeason(xlat, ylon), :)), 4), 3));
        warmNet(xlat, ylon) = med;
        sigChg(xlat, ylon) = length(find(sign(nanmean(net(xlat, ylon, :, seasons(hottestSeason(xlat, ylon), :)), 4)) == sign(med))) < .75*size(net, 3);
    end
end

result = {lat, lon, warmNet};

sigChg(1:15, :) = 0;
sigChg(75:90, :) = 0;

saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [0 20], ...
                  'cbXTicks', 0:5:20, ...
                  'plotTitle', ['Net warm season surface SW radiation'], ...
                  'fileTitle', ['net-surf-sw-rad-rcp85-' num2str(size(net, 3)) '-cmip5-warm.eps'], ...
                  'plotXUnits', ['W/m^2'], ...
                  'blockWater', true, ...
                  'colormap', brewermap([],'Reds'), ...
                  'statData', sigChg, ...
                  'stippleInterval', 5, ...
                  'boxCoords', {regions([2,4,7], :)});
plotFromDataFile(saveData);
