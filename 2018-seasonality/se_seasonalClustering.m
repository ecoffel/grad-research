
timePeriod = [1980 2016];

subPeriods = {[1980 2010],...
              [1981 2011],...
              [1982 2012],...
              [1983 2013],...
              [1984 2014],...
              [1985 2015],...
              [1986 2016]};
yearN = 31;

if ~exist('tmaxBase','var')
    tmaxBase = loadDailyData('e:/data/ncep-reanalysis/output/tmax/regrid/world', 'yearStart', timePeriod(1), 'yearEnd', timePeriod(end));
    prBase = loadDailyData('e:/data/ncep-reanalysis/output/prate/regrid/world', 'yearStart', timePeriod(1), 'yearEnd', timePeriod(end));
    qBase = loadDailyData('e:/data/ncep-reanalysis/output/shum/regrid/world', 'yearStart', timePeriod(1), 'yearEnd', timePeriod(end));
    
    %tmaxBase = loadDailyData('d:/data/era-interim/output/tmax/regrid/world', 'yearStart', timePeriod(1), 'yearEnd', timePeriod(end));
    %prBase = loadDailyData('d:/data/era-interim/output/prate/regrid/world', 'yearStart', timePeriod(1), 'yearEnd', timePeriod(end));
    %qBase = loadDailyData('d:/data/era-interim/output/shum/regrid/world', 'yearStart', timePeriod(1), 'yearEnd', timePeriod(end));
    
    % kill off water now so it's not involved in any future calcs
    load waterGrid;
    waterGrid = logical(waterGrid);

    for xlat = 1:size(tmaxBase{3}, 1)
        for ylon = 1:size(tmaxBase{3}, 2)
            if waterGrid(xlat, ylon)
                tmaxBase{3}(xlat, ylon) = NaN;
                qBase{3}(xlat, ylon) = NaN;
                prBase{3}(xlat, ylon) = NaN;
            end
        end
    end
end

% select lat/lon
%[latInd, lonInd] = latLonIndexRange(tmaxBase, [45 45], [9 9]); % milan
%[latInd, lonInd] = latLonIndexRange(tmaxBase, [41 41], [269 269]); % iowa
%[latInd, lonInd] = latLonIndexRange(tmaxBase, [41 41], [285 285]); % nyc
%[latInd, lonInd] = latLonIndexRange(tmaxBase, [34 34], [276 276]); % ATL
%[latInd, lonInd] = latLonIndexRange(tmaxBase, [33 33], [247 247]); % phoenix
%[latInd, lonInd] = latLonIndexRange(tmaxBase, [27 27], [281 281]); % miami
%[latInd, lonInd] = latLonIndexRange(tmaxBase, [47 47], [238 238]); % seattle
%[latInd, lonInd] = latLonIndexRange(tmaxBase, [40 40], [255 255]); % denver

[latInd, lonInd] = latLonIndexRange(tmaxBase, [40 50], [250 260]); % central US

gridSize = 3;
avoidWater = true;
plotLine = true;
plotMap = false;
robustTimeSeries = true;

lat = tmaxBase{1};
lon = tmaxBase{2};

% classifications for seasons... {name, tmax, tmaxVar, pr, wb}
% stable: tmaxVar = 5; variable: tmaxVar = 30
seasonProperties = containers.Map;
seasonProperties('tmax') = {{'hot', 'warm', 'cool', 'cold'}, ...
                            [40,    25,     10,     0]};
seasonProperties('tmaxVar') = {{'stable', 'variable', 'chaos'}, ...
                               [10,       50,         90]};
seasonProperties('pr') = {{'pdry', 'damp', 'wet', 'soaked'}, ...
                            [5,    20,     50,     100]}; 
seasonProperties('q') = {{'humid', 'adry'}, ...
                          [.015,    .005]}; 

dims = [2 3];

seasonalTrends = {};

curXpos = 0;
curYpos = 0;

for xlati = 1:gridSize:length(latInd)-gridSize+1
    curXpos = curXpos+1;
    curYpos = 0;
    for yloni = 1:gridSize:length(lonInd)-gridSize+1
        curYpos = curYpos+1;
        xlat = latInd(xlati):latInd(xlati+gridSize-1);
        
        l1 = lonInd(yloni);
        l2 = lonInd(yloni+gridSize-1);
        if l2<l1
            ylon = [l1:180 1:l2];
        else
            ylon = l1:l2;
        end
        
        fprintf('processing (%d, %d)\n',xlat(1), ylon(1));
        
        if avoidWater && sum(sum(waterGrid(latInd(xlati:xlati+gridSize-1), lonInd(yloni:yloni+gridSize-1))))/(gridSize*gridSize) > 0.75
            continue;
        end
        
        curTrend = containers.Map;
        curTrendPos = [curXpos; curYpos];
        curTrendOcr = zeros(dims(1)*dims(2), yearN, length(subPeriods));
        curTrendSig = zeros(dims(1)*dims(2), length(subPeriods));
        curTrendName = strings(dims(1)*dims(2), length(subPeriods));
        
        for period = 1:length(subPeriods)
            
            startYear = subPeriods{period}(1) - timePeriod(1) + 1;
            endYear = startYear + yearN -1;
            
            % variables
            tmax = nanmean(nanmean(tmaxBase{3}(xlat, ylon, startYear:endYear, :, :), 2), 1)-273.15;
            tmax = reshape(tmax, [numel(tmax), 1]);

            % build arrays of year, month
            [y, m, d] = ind2sub(size(squeeze(tmaxBase{3}(xlat(1), ylon(1), startYear:endYear, :, :))), 1:length(tmax));

            % daily difference in temperature
            tmaxDiff = diff(tmax);

            pr = nanmean(nanmean(prBase{3}(xlat, ylon, startYear:endYear, :, :), 2), 1).*60.*60.*24; % mm/day
            pr = reshape(pr, [numel(pr), 1]);

            q = nanmean(nanmean(qBase{3}(xlat, ylon, startYear:endYear, :, :), 2), 1); % percent
            q = reshape(q, [numel(q), 1]);

            % remove 1st element to harmonize lengths with difference array
            tmax = tmax(2:end);
            pr = pr(2:end);
            q = q(2:end);
            m = m(2:end);

            % eliminate nans
            nn = find(~isnan(tmaxDiff) & ~isnan(tmax) & ~isnan(pr) & ~isnan(q));
            %pr = pr(nn);
            %tmax = tmax(nn);
            %q = q(nn);
            %tmaxDiff = tmaxDiff(nn);
            %m = m(nn);

            % how many days to group over (1 week now)
            groupingN = 7;

            % now compute weekly metrics
            tmaxGroup = arrayfun(@(i) nanmean(tmax(i:i+groupingN-1)),1:groupingN:length(tmax)-groupingN+1)'; 
            tmaxVar = arrayfun(@(i) nanvar(tmax(i:i+groupingN-1)),1:groupingN:length(tmax)-groupingN+1)';
            qGroup = arrayfun(@(i) nanmean(q(i:i+groupingN-1)),1:groupingN:length(q)-groupingN+1)'; 
            prGroup = arrayfun(@(i) nansum(pr(i:i+groupingN-1)),1:groupingN:length(pr)-groupingN+1)'; 
            mGroup = arrayfun(@(i) round(nanmean(m(i:i+groupingN-1))),1:groupingN:length(m)-groupingN+1)'; 

            % build the SOM normalized and non-norm structures
            X = [tmaxGroup, tmaxVar, prGroup, qGroup]';
            Xn = [normc(tmaxGroup), normc(tmaxVar), normc(prGroup), normc(qGroup)]';

            % run SOM
            som = selforgmap(dims);
            som.trainParam.epochs = 500;
            som = configure(som, Xn);
            som.trainParam.showWindow = false;
            som = train(som, Xn);

            % get resulting weekly SOM classes
            y = som(Xn);
            classes = vec2ind(y);
            
            % stores the variable values for each class
            classVals = [];
            
            % variable names for line plot
            varNames = {'TmaxWeek', 'TmaxVar', 'PrWeek', 'QWeek'};
            
            % season names for line plot legend
            seasonNames = {};
            
            % loop over all som classes
            for i = 1:max(classes)
                
                % find all weeks with this class and what percent of total
                % weeks they make up
                ind = find(classes == i);
                prc = length(ind)/length(classes)*100;

                % most common month
                topMonth = mode(mGroup(ind));
                %figure;
                %hist(mGroup(ind), unique(mGroup(ind)));

                %fprintf('Class %i, %.1f, month = %i\n', i, prc, topMonth);

                % loop over all variables
                for v = 1:size(Xn, 1)
                    
                    % get the mean variable value for this som class
                    cV = nanmean(X(v, ind));
                    classVals(i,v) = cV;
%                     fprintf('%s = %f\n', varNames{v}, cV);
                end

                % generate the season name based on the pre-defined classes
                % for each variable
                seasonName = '';

                s1 = seasonProperties('tmax');
                s2 = seasonProperties('tmaxVar');
                s3 = seasonProperties('pr');
                s4 = seasonProperties('q');

                seasonName = [seasonName s1{1}{find(abs(classVals(i, 1) - s1{2}) == min(abs(classVals(i, 1) - s1{2})))} '-'];
                seasonName = [seasonName s2{1}{find(abs(classVals(i, 2) - s2{2}) == min(abs(classVals(i, 2) - s2{2})))} '-'];
                seasonName = [seasonName s3{1}{find(abs(classVals(i, 3) - s3{2}) == min(abs(classVals(i, 3) - s3{2})))} '-'];
                seasonName = [seasonName s4{1}{find(abs(classVals(i, 4) - s4{2}) == min(abs(classVals(i, 4) - s4{2})))}];

                % store season a
                seasonNames{i} = seasonName;

                % find the class index if we've seen this class before
                classInd = i;
                indTemp = find(curTrendName(:,1) == seasonName);
                if length(indTemp) > 0
                    classInd = indTemp(1);
                else
                    % if this is a new pattern, put it at the end if we
                    % have empty slots... otherwise discard it
                    if period > 1
                        indFree = find(curTrendName(:, period-1) == "");
                        if length(indFree) > 0
                            % set to first free row
                            classInd = indFree(1);
                        else
                            % add a new row
                            classInd = size(curTrendName, 1) + 1;
                            curTrendOcr = [curTrendOcr; zeros(1, size(curTrendOcr, 2), size(curTrendOcr, 3))];
                            curTrendSig = [curTrendSig; zeros(1, size(curTrendSig, 2), size(curTrendSig, 3))];
                            curTrendName = [curTrendName; strings(1, size(curTrendName, 2), size(curTrendName, 3))];
                        end
                    end
                end
                
                % find number of occurence each year (52-week)
                occurrence = arrayfun(@(x) length(find((classes(x:x+52-1))==i)), 1:52:length(classes)-52+1)';
                
                % this is a duplicate trend - add occurrences
                if sum(curTrendOcr(classInd, :, period)) > 0
                    curTrendOcr(classInd, :, period) = squeeze(curTrendOcr(classInd, :, period))' + occurrence;
                else
                    curTrendOcr(classInd, :, period) = occurrence;
                    curTrendName(classInd, period) = seasonName;
                end

                f = fit((1:length(occurrence))', occurrence, 'poly1');
                ci = confint(f, 0.9);
                % decreasing trend
                if (ci(2,1) < 0 && ci(1,1) < 0)
                    curTrendSig(classInd, period) = curTrendSig(classInd, period) - 1;
                % increasing trend
                elseif (ci(2,1) > 0 && ci(1,1) > 0)
                    curTrendSig(classInd, period) = curTrendSig(classInd, period) + 1;
                end
            end

        end
        
        curTrend('pos') = {latInd(1):gridSize:latInd(end), lonInd(1):gridSize:lonInd(end), curTrendPos};
        curTrend('occurrence') = curTrendOcr;
        curTrend('significant') = curTrendSig;
        curTrend('name') = curTrendName;
        curTrend('characteristics') = {varNames, classVals};
        
        seasonalTrends{end+1} = curTrend;

    end
end

save('strend-9', 'seasonalTrends');

% 
% result = {lat(latInd,lonInd), lon(latInd,lonInd), seasonalTrendsWx(:, :, 1)};
% plotModelData(result, 'usa', 'caxis', [-1 1]);
% 
% result = {lat(latInd,lonInd), lon(latInd,lonInd), seasonalTrendsWx(:, :, 2)};
% plotModelData(result, 'usa', 'caxis', [-1 1]);

trendMap = [];
localLat = [];
localLon = [];
for t = 1:length(seasonalTrends)
    loc = seasonalTrends{t}('pos');
    sig = seasonalTrends{t}('significant');
    ocr = seasonalTrends{t}('occurrence');
    name = seasonalTrends{t}('name');
    
    if length(localLat) == 0
        localLat = lat(loc{1}, loc{2});
        localLon = lon(loc{1}, loc{2});
    end
    
    xlat = loc{3}(1,1);
    ylon = loc{3}(2,1);
    
    % go through each trend
    for s = 1:size(sig, 1)
        % trend is robust across time series
        if sum(sig(s, :)) <= -5 || sum(sig(s, :)) >= 5
            try
                trendMap(xlat, ylon) = trendMap(loc{3}(1,1), loc{3}(2,1)) + 1;
            catch
                trendMap(xlat, ylon) = 1;
            end
        end
    end
    
    if plotLine
        if size(trendMap,1) >= xlat && size(trendMap,2) >= ylon && trendMap(xlat, ylon) > 0
            figure('Color',[1,1,1]);
            hold on;
            grid on;
            axis square;
            box on;
            
            colors = distinguishable_colors(size(sig,1));
            legItems = [];
            for c = 1:size(sig, 1)
                p = plot(squeeze(ocr(c,:,1)), 'Color', colors(c, :));
                legItems(c) = p;
                
                if sum(sig(c, :)) <= -5 || sum(sig(c, :)) >= 5
                    f = fit((1:size(ocr,2))', squeeze(ocr(c, :, 1))', 'poly1');
                    plot(1:size(ocr,2), f(1:size(ocr,2)), 'LineStyle', '--', 'Color', colors(c, :));
                end
            end
            title(['Lat/lon: (' num2str(round(lat(round(nanmean(loc{1})), round(nanmean(loc{2}))))) ', ' ...
                                num2str(round(lon(round(nanmean(loc{1})), round(nanmean(loc{2}))))) ')']);

            legend(legItems,seasonNames);
        end
    end
    
end

result = {localLat, localLon, trendMap};
plotModelData(result, 'north america', 'caxis', [0 4]);


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

