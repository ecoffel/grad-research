warmSeasonAnom = false;
txxWarmAnom = true;

load e:/data/projects/bowen/derived-chg/seasonal-amp;
load e:/data/projects/bowen/derived-chg/txxAmp;

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

if warmSeasonAnom
    result = {lat, lon, nanmedian(seasonalAmp, 3)};
    for xlat = 1:size(lat, 1)
        for ylon = 1:size(lat, 2)
            if waterGrid(xlat, ylon)
                sigChg(xlat, ylon) = 0;
                continue;
            end
            med = nanmedian(seasonalAmp(xlat, ylon, :), 3);
            sigChg(xlat, ylon) = length(find(sign(seasonalAmp(xlat, ylon, :)) == sign(med))) < .75*size(amp, 3);
        end
    end
elseif txxWarmAnom
    % difference between TXx warming & warm season warming
    data = amp - seasonalAmp;
    result = {lat, lon, nanmedian(data, 3)};
    for xlat = 1:size(lat, 1)
        for ylon = 1:size(lat, 2)
            if waterGrid(xlat, ylon)
                sigChg(xlat, ylon) = 0;
                continue;
            end
            med = nanmedian(data(xlat, ylon, :), 3);
            sigChg(xlat, ylon) = length(find(sign(data(xlat, ylon, :)) == sign(med))) < .75*size(amp, 3);
        end
    end
end

sigChg(1:15, :) = 0;
sigChg(75:90, :) = 0;

saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [-3 3], ...
                  'cbXTicks', -3:.5:3, ...
                  'plotTitle', ['Amplification'], ...
                  'fileTitle', ['ampAgreement-rcp85-' num2str(size(amp, 3)) '-cmip5-txx-warm-anom.eps'], ...
                  'plotXUnits', ['Amplification (' char(176) 'C)'], ...
                  'blockWater', true, ...
                  'colormap', brewermap([],'*RdBu'), ...
                  'statData', sigChg, ...
                  'stippleInterval', 5, ...
                  'boxCoords', {regions([2,4,7], :)});
plotFromDataFile(saveData);
