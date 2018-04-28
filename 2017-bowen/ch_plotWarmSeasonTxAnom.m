warmSeasonFrac = false;
txxWarmDiff = true;
txxThresh = false;

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
           [[-10, 7], [-75, -62]+360]; ...      % Amazon
           [[-10 10], [15, 30]]; ...            % central africa
           [[15 30], [-4 29]]; ...              % north africa
           [[22 40], [105 122]]];               % china
                      

sigChg = [];

if warmSeasonFrac
    % difference between warm season warming and annual warming
    
    load e:/data/projects/bowen/derived-chg/txxChg.mat;
    load e:/data/projects/bowen/derived-chg/txChgWarm.mat;
    
    data = txChgWarm ./ txxChg;
    plotData = [];
    for xlat = 1:size(lat, 1)
        for ylon = 1:size(lat, 2)
            if waterGrid(xlat, ylon)
                plotData(xlat, ylon) = NaN;
                continue;
            end
            med = nanmedian(data(xlat, ylon, :), 3);
            plotData(xlat, ylon) = nanmedian(data(xlat, ylon, :), 3);
            %sigChg(xlat, ylon) = length(find(sign(data(xlat, ylon, :) plotData(xlat, ylon)))) < .75*size(data, 3);
        end
    end
    
    result = {lat, lon, plotData .* 100};
    txWarmTXxFrac = data;
    %save(['e:/data/projects/bowen/derived-chg/txWarmTXxFrac.mat'], 'txWarmTXxFrac');
    
    sigChg(1:15, :) = 0;
    sigChg(80:90, :) = 0;

    saveData = struct('data', {result}, ...
                      'plotRegion', 'world', ...
                      'plotRange', [70 100], ...
                      'cbXTicks', 70:5:100, ...
                      'plotTitle', ['Warm season Tx change fraction of TXx change'], ...
                      'fileTitle', ['ampAgreement-rcp85-' num2str(size(data, 3)) '-cmip5-txx-tx-warm-fraction-99.eps'], ...
                      'plotXUnits', ['%'], ...
                      'blockWater', true, ...
                      'colormap', brewermap([],'*YlOrRd'), ...
                      'boxCoords', {regions([2,4,7,10], :)});
    plotFromDataFile(saveData);
    
    
    
elseif txxWarmDiff
    % difference between TXx warming & warm season warming
    
    load e:/data/projects/bowen/derived-chg/txxChg.mat;
    load e:/data/projects/bowen/derived-chg/txChgWarm.mat;
    
    
    data = txxChg - txChgWarm;
    plotData = [];
    for xlat = 1:size(lat, 1)
        for ylon = 1:size(lat, 2)
            if waterGrid(xlat, ylon)
                plotData(xlat, ylon) = NaN;
                sigChg(xlat, ylon) = 0;
                continue;
            end
            med = nanmedian(data(xlat, ylon, :), 3);
            if ~isnan(med)
                plotData(xlat, ylon) = nanmedian(data(xlat, ylon, :), 3);
                sigChg(xlat, ylon) = length(find(sign(data(xlat, ylon, :)) == sign(plotData(xlat, ylon)))) < .75*size(data, 3);
            else
                sigChg(xlat, ylon) = 1;
            end
        end
    end
    
    result = {lat, lon, plotData};
    
    sigChg(1:15, :) = 0;
    sigChg(80:90, :) = 0;

    saveData = struct('data', {result}, ...
                      'plotRegion', 'world', ...
                      'plotRange', [-1.5 1.5], ...
                      'cbXTicks', -1.5:.5:1.5, ...
                      'plotTitle', ['TXx Amplification over warm season'], ...
                      'fileTitle', ['ampAgreement-rcp85-' num2str(size(data, 3)) '-cmip5-txx-warm-diff-model-warm.eps'], ...
                      'plotXUnits', ['Amplification (' char(176) 'C)'], ...
                      'blockWater', true, ...
                      'colormap', brewermap([],'*RdBu'), ...
                      'statData', sigChg, ...
                      'stippleInterval', 5, ...
                      'boxCoords', {regions([2,4,7,10], :)});
    plotFromDataFile(saveData);
elseif txxThresh
    % difference between TXx warming & warm season warming
    
    load e:/data/projects/bowen/derived-chg/txxChgThresh90.mat;
    load e:/data/projects/bowen/derived-chg/txChgWarm.mat;
    
    
    data = txxChg - txChgWarm;
    plotData = [];
    for xlat = 1:size(lat, 1)
        for ylon = 1:size(lat, 2)
            if waterGrid(xlat, ylon)
                plotData(xlat, ylon) = NaN;
                continue;
            end
            med = nanmedian(data(xlat, ylon, :), 3);
            if ~isnan(med)
                if kstest(squeeze(data(xlat, ylon, :)))
                    plotData(xlat, ylon) = nanmedian(data(xlat, ylon, :), 3);
                    sigChg(xlat, ylon) = length(find(sign(data(xlat, ylon, :)) == sign(plotData(xlat, ylon)))) < .75*size(data, 3);
                else
                    sigChg(xlat, ylon) = 1;
                end
            else
                sigChg(xlat, ylon) = 1;
            end
        end
    end
    
    result = {lat, lon, plotData};
    
    sigChg(1:15, :) = 0;
    sigChg(80:90, :) = 0;

    saveData = struct('data', {result}, ...
                      'plotRegion', 'world', ...
                      'plotRange', [-3 3], ...
                      'cbXTicks', -3:.5:3, ...
                      'plotTitle', ['90th percentile Tx amp over warm season'], ...
                      'fileTitle', ['ampAgreement-rcp85-' num2str(size(data, 3)) '-cmip5-tx90-warm-diff-model-warm.eps'], ...
                      'plotXUnits', ['Amplification (' char(176) 'C)'], ...
                      'blockWater', true, ...
                      'colormap', brewermap([],'*RdBu'), ...
                      'statData', sigChg, ...
                      'stippleInterval', 5, ...
                      'boxCoords', {regions([2,4,7,10], :)});
    plotFromDataFile(saveData);
end



