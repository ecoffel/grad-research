
load lat;
load lon;
load waterGrid;
waterGrid = logical(waterGrid);

load e:/data/projects/bowen/derived-chg/hfss-chg-all;
hfssChg(hfssChg>1000 | hfssChg<-1000) = NaN;

load e:/data/projects/bowen/derived-chg/hfls-chg-all;
hflsChg(hflsChg>1000 | hflsChg<-1000) = NaN;

regions = [[[-90 90], [0 360]]; ...             % world
           [[30 42], [-91 -75] + 360]; ...     % eastern us
           [[30 41], [-95 -75] + 360]; ...      % southeast us
           [[45, 55], [10, 35]]; ...            % Europe
           [[35 50], [-10+360 45]]; ...        % Med
           [[5 20], [-90 -45]+360]; ...         % Northern SA
           [[-10, 1], [-75, -53]+360]; ...      % Amazon
           [[-10 10], [15, 30]]; ...            % central africa
           [[15 30], [-4 29]]];                 % north africa

showOutliers = true;
warmSeason = false;

corrMap = [];
corrSig = [];

seasons = [[12 1 2];
           [3 4 5];
           [6 7 8];
           [9 10 11]];

% load hottest seasons for each grid cell
load('2017-bowen/hottest-season-ncep.mat');

for xlat = 1:size(lat, 1)
    for ylon = 1:size(lat, 2)
        if waterGrid(xlat, ylon)
            corrMap(xlat, ylon) = NaN;
            corrSig(xlat, ylon) = 0;
            continue;
        end

        if warmSeason
            hotSeason = hottestSeason(xlat, ylon);
            driverMonths = seasons(hotSeason,:);
        else
            driverMonths = 1:12;
        end
        
        regionHfss = squeeze(nanmean(hfssChg(xlat, ylon, :, driverMonths), 4));

        % and bowen
        regionHfls = squeeze(nanmean(hflsChg(xlat, ylon, :, driverMonths), 4));

        nn = find(~isnan(regionHfls) & ~isnan(regionHfss));
        regionHfss = regionHfss(nn);
        regionHfls = regionHfls(nn);

        if length(nn) < 10
            corrMap(xlat, ylon) = NaN;
            corrSig(xlat, ylon) = 0;
            continue;
        end

        if showOutliers
            hfssOutlierStdMult = 2;
            hflsOutlierStdMult = 2;

            hflsOutliers = find(regionHfls > nanstd(regionHfls)*hflsOutlierStdMult+nanmean(regionHfls) | ...
                                 regionHfls < -nanstd(regionHfls)*hflsOutlierStdMult+nanmean(regionHfls));
            hfssOutliers = find(regionHfss > nanstd(regionHfss)*hfssOutlierStdMult+nanmean(regionHfss) | ...
                               regionHfss < -nanstd(regionHfss)*hfssOutlierStdMult+nanmean(regionHfss));

            outliers = union(hflsOutliers, hfssOutliers);
            regionHflsChgNoOutliers = regionHfls;
            regionHflsChgNoOutliers(outliers) = [];
            regionHfssNoOutliers = regionHfss;
            regionHfssNoOutliers(outliers) = [];
        end

        if showOutliers
            f = fit(regionHfssNoOutliers, regionHflsChgNoOutliers, 'poly1');
            c = confint(f);

        end
        corrMap(xlat, ylon) = f.p1;
        corrSig(xlat, ylon) = sign(c(1,1)) == sign(c(2,1));

    end
end

corrSig(1:15,:) = 0;
corrSig(75:90,:) = 0;

result = {lat, lon, corrMap};

saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [-1 1], ...
                  'cbXTicks', -1:.25:1, ...
                  'plotTitle', 'SH - LH tradeoff', ...
                  'fileTitle', 'sh-lh-tradeoff-all-year.eps', ...
                  'plotXUnits', ['Slope'], ...
                  'blockWater', true, ...
                  'statData', corrSig, ...
                  'stippleInterval', 5, ...
                  'colormap', brewermap([], '*RdBu'), ...
                  'boxCoords', {regions([2,4,7], :)});
plotFromDataFile(saveData);