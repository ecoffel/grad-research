
timePeriod = [1980 2010];

if ~exist('tmaxBase','var')
    tmaxBase = loadDailyData('e:/data/ncep-reanalysis/output/tmax/regrid/world', 'yearStart', timePeriod(1), 'yearEnd', timePeriod(end));
    prBase = loadDailyData('e:/data/ncep-reanalysis/output/prate/regrid/world', 'yearStart', timePeriod(1), 'yearEnd', timePeriod(end));
    wbBase = loadDailyData('e:/data/ncep-reanalysis/output/wb/regrid/world', 'yearStart', timePeriod(1), 'yearEnd', timePeriod(end));
    
    % kill off water now so it's not involved in any future calcs
    load waterGrid;
    waterGrid = logical(waterGrid);

    for xlat = 1:size(tmaxBase{3}, 1)
        for ylon = 1:size(tmaxBase{3}, 2)
            if waterGrid(xlat, ylon)
                tmaxBase{3}(xlat, ylon) = NaN;
                wbBase{3}(xlat, ylon) = NaN;
                prBase{3}(xlat, ylon) = NaN;
            end
        end
    end
end

% select lat/lon
%[latInd, lonInd] = latLonIndexRange(tmaxBase, [44 47], [8 11]); % milan
[latInd, lonInd] = latLonIndexRange(tmaxBase, [41 41], [269 269]); % iowa
%[latInd, lonInd] = latLonIndexRange(tmaxBase, [40 43], [283 286]); % nyc
%[latInd, lonInd] = latLonIndexRange(tmaxBase, [32 35], [275 278]); % ATL
%[latInd, lonInd] = latLonIndexRange(tmaxBase, [31 34], [246 249]); % phoenix

%[latInd, lonInd] = latLonIndexRange(tmaxBase, [0 60], [0 360]); % central US

lat = tmaxBase{1};
lon = tmaxBase{2};

% classifications for seasons... {name, tmax, tmaxRange, pr, wb}
seasons = {{'hot-dry-stable', [30, 15, 15, 20]}, ...
           {'cold-dry-variable', [0, 35, 5, 0]}, ...
           {'cool-dry-variable', [15, 30, 10, 10]}, ...
           {'cold-dry-chaos', [0, 100, 5, 0]}, ...
           {'warm-wet-stable', [25, 15, 60, 20]}, ...
           {'cool-wet-variable', [10, 40, 30, 5]}};

dims = [2 3];

seasonalTrends = zeros(length(latInd), length(lonInd), dims(1)*dims(2));

gridSize = 1;

for xlati = 1:gridSize:length(latInd)
    for yloni = 1:gridSize:length(lonInd)
        
        xlat = latInd(xlati):latInd(xlati+gridSize-1);
        
        l1 = lonInd(yloni);
        l2 = lonInd(yloni+gridSize-1);
        if l2<l1
            ylon = [l1:180 1:l2];
        else
            ylon = l1:l2;
        end
        
        fprintf('processing (%d, %d)\n',xlat(1), ylon(1));
        
        if sum(sum(waterGrid(latInd(xlati:xlati+gridSize-1), lonInd(yloni:yloni+gridSize-1))))/(gridSize*gridSize) > 0.75
            seasonalTrends(xlati:xlati+gridSize, yloni:yloni+gridSize, :) = NaN;
            continue;
        end
        
        % variables
        tmax = nanmean(nanmean(tmaxBase{3}(xlat, ylon, :, :, :), 2), 1)-273.15;
        tmax = reshape(tmax, [numel(tmax), 1]);

        % build arrays of year, month
        [y, m, d] = ind2sub(size(squeeze(tmaxBase{3}(xlat, ylon, :, :, :))), 1:length(tmax));

        % daily difference in temperature
        tmaxDiff = diff(tmax);

        pr = nanmean(nanmean(prBase{3}(xlat, ylon, :, :, :), 2), 1).*60.*60.*24; % mm/day
        pr = reshape(pr, [numel(pr), 1]);

        wb = nanmean(nanmean(wbBase{3}(xlat, ylon, :, :, :), 2), 1); % percent
        wb = reshape(wb, [numel(wb), 1]);

        % remove 1st element to harmonize lengths with difference array
        tmax = tmax(2:end);
        pr = pr(2:end);
        wb = wb(2:end);
        m = m(2:end);

        % eliminate nans
        nn = find(~isnan(tmaxDiff) & ~isnan(tmax) & ~isnan(pr) & ~isnan(wb));
        pr = pr(nn);
        tmax = tmax(nn);
        wb = wb(nn);
        tmaxDiff = tmaxDiff(nn);
        m = m(nn);

        monthlyTmax = [];
        monthlyTmaxDiff = [];
        monthlyPr = [];
        monthlyWb = [];

%         for month = 1:12
%             % find indicies for current month
%             ind = find(m == month);
% 
%             % cluster variables for this month
%             monthlyTmax(month) = nanmean(tmax(ind));
%             monthlyTmaxDiff(month) = nanmean(tmaxDiff(ind));
%             monthlyPr(month) = nanmean(pr(ind));
%             monthlyWb(month) = nanmean(wb(ind));
%         end

        groupingN = 7;

        % now compute weekly metrics
        tmaxGroup = arrayfun(@(i) mean(tmax(i:i+groupingN-1)),1:groupingN:length(tmax)-groupingN+1)'; 
        tmaxVar = arrayfun(@(i) var(tmax(i:i+groupingN-1)),1:groupingN:length(tmax)-groupingN+1)';

        wbGroup = arrayfun(@(i) mean(wb(i:i+groupingN-1)),1:groupingN:length(wb)-groupingN+1)'; 
        prGroup = arrayfun(@(i) sum(pr(i:i+groupingN-1)),1:groupingN:length(pr)-groupingN+1)'; 

        mGroup = arrayfun(@(i) round(mean(m(i:i+groupingN-1))),1:groupingN:length(m)-groupingN+1)'; 

        X = [tmaxGroup, tmaxVar, prGroup, wbGroup]';
        Xn = [normc(tmaxGroup), normc(tmaxVar), normc(prGroup), normc(wbGroup)]';

        som = selforgmap(dims);
        som.trainParam.epochs = 400;
        som = configure(som, Xn);
        som.trainParam.showWindow = false;
        som = train(som, Xn);

        y = som(Xn);
        classes = vec2ind(y);
        classVals = [];
        varNames = {'TmaxWeek', 'TmaxVar', 'PrWeek', 'WbWeek'};
        for i = 1:max(classes)
            ind = find(classes == i);
            prc = length(ind)/length(classes)*100;

            topMonth = mode(mGroup(ind));
            %figure;
            %hist(mGroup(ind), unique(mGroup(ind)));

            fprintf('Class %i, %.1f, month = %i\n', i, prc, topMonth);

            for v = 1:size(Xn, 1)
                cV = nanmean(X(v, ind));
                classVals(i,v) = cV;
                fprintf('%s = %f\n', varNames{v}, cV)
            end
            fprintf('\n\n')
        end

        figure('Color',[1,1,1]);
        hold on;
        grid on;
        axis square;
        box on;
        colors = distinguishable_colors(max(classes));
        legItems = [];
        for c = 1:max(classes)
            occurrence = arrayfun(@(i) length(find((classes(i:i+52-1))==c)),1:52:length(classes)-52+1)';
            f = fit((1:length(occurrence))', occurrence, 'poly1');
            p = plot(occurrence, 'Color', colors(c, :));
            legItems(c) = p;

            ci = confint(f);
            if (ci(2,1) < 0 && ci(1,1) < 0 ) || (ci(2,1) > 0 && ci(1,1) > 0)
                seasonalTrends(xlati:xlati+gridSize-1, yloni:yloni+gridSize-1, c) = 1;
                plot(1:length(occurrence), f(1:length(occurrence)), 'LineStyle', '--', 'Color', colors(c, :));
            else
                seasonalTrends(xlati:xlati+gridSize-1, yloni:yloni+gridSize-1, c) = 0;
            end
        end
        legend(legItems,{'class 1', 'class 2', 'class 3', 'class 4', 'class 5', 'class 6'});

    end
end

result = sum(seasonalTrends,3);
plotModelData({lat(latInd,lonInd),lon(latInd,lonInd),result}, 'world', 'caxis', [0 4]);

% result = {lat(regionLat,regionLon),lon(regionLat,regionLon),squeeze(m(k,c,:,:))'};
% 
% saveData = struct('data', {result}, ...
%                   'plotRegion', 'north america', ...
%                   'plotRange', [-200 200], ...
%                   'cbXTicks', -200:50:200, ...
%                   'plotTitle', [''], ...
%                   'fileTitle', ['som-z500.png'], ...
%                   'plotXUnits', ['m'], ...
%                   'blockWater', true, ...
%                   'colormap', cmocean('thermal'), ...
%                   'magnify', '2');
% plotFromDataFile(saveData);

