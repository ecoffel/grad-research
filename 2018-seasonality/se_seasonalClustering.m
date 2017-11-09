
timePeriod = [1980 2016];

subPeriods = {[1980 2014],...
              [1981 2015],...
              [1982 2016]};

%         subPeriods = {[1980 2009],...
%                       [1981 2010],...
%                       [1982 2011],...
%                       [1983 2012],...
%                       [1984 2013],...
%                       [1985 2014],...
%                       [1986 2015],...
%                       [1987 2016]};

yearN = 35;

dataset = 'era-interim';

if ~exist('tmaxBase','var')
    if strcmp(dataset, 'ncep-reanalysis')
        fprintf('loading temp...\n');
        tmaxBase = loadDailyData('e:/data/ncep-reanalysis/output/tmax/regrid/world', 'yearStart', timePeriod(1), 'yearEnd', timePeriod(end));
        
        fprintf('loading precip...\n');
        prBase = loadDailyData('e:/data/ncep-reanalysis/output/prate/regrid/world', 'yearStart', timePeriod(1), 'yearEnd', timePeriod(end));
    elseif strcmp(dataset, 'era-interim')
        fprintf('loading temp...\n');
        tmaxBase = loadDailyData('e:/data/era-interim/output/mx2t/regrid/world', 'yearStart', timePeriod(1), 'yearEnd', timePeriod(end));
        
        fprintf('loading precip...\n');
        prBase = loadDailyData('e:/data/era-interim/output/tp/regrid/world', 'yearStart', timePeriod(1), 'yearEnd', timePeriod(end));
    end
    
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
%[latInd, lonInd] = latLonIndexRange(tmaxBase, [40 40], [269 269]); % iowa
[latInd, lonInd] = latLonIndexRange(tmaxBase, [41 41], [285 285]); % nyc
%[latInd, lonInd] = latLonIndexRange(tmaxBase, [34 34], [276 276]); % ATL
%[latInd, lonInd] = latLonIndexRange(tmaxBase, [33 33], [247 247]); % phoenix
%[latInd, lonInd] = latLonIndexRange(tmaxBase, [27 27], [281 281]); % miami
%[latInd, lonInd] = latLonIndexRange(tmaxBase, [47 47], [238 238]); % seattle
%[latInd, lonInd] = latLonIndexRange(tmaxBase, [40 40], [255 255]); % denver

%[latInd, lonInd] = latLonIndexRange(tmaxBase, [38 42], [278 282]); % central US

gridSize = 1;
avoidWater = true;
plotLine = true;
plotMap = false;
robustTimeSeries = true;
numSomRuns = 1;
percentile = true;
detrendData = false;

lat = tmaxBase{1};
lon = tmaxBase{2};

seasonalTrends = {};

dims = [2 3];

for somRun = 1:numSomRuns

    ['processing som run ' num2str(somRun) '...']

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
            curTrendClasses = zeros(dims(1)*dims(2), 3);
            
            % season names for line plot legend
            seasonNames = {};
            
            % the months associated with each season classification
            classMonths = {};

            for period = 1:length(subPeriods)

                startYear = subPeriods{period}(1) - timePeriod(1) + 1;
                endYear = startYear + yearN - 1;

                % classifications for seasons... {name, tmax, tmaxVar, pr, wb}
                % stable: tmaxVar = 5; variable: tmaxVar = 30
                seasonProperties = containers.Map;

                if percentile
                    seasonProperties('tmax') = {{'hot', 'warm', 'cool', 'cold'}, ...
                                                 [90,    65,     35,    10]};
                    seasonProperties('tmaxVar') = {{'stable', 'flux', 'var'}, ...
                                                   [10,        50,     90]};
                    seasonProperties('pr') = {{'dry', 'damp', 'wet'}, ...
                                                [10,   50,     90]}; 
                else
                    seasonProperties('tmax') = {{'hot', 'warm', 'cool', 'cold'}, ...
                                                [40,    25,     15,     0]};
                    seasonProperties('tmaxVar') = {{'stable', 'flux'}, ...
                                                   [1,         9]};
                    seasonProperties('pr') = {{'pdry', 'damp', 'wet'}, ...
                                                [5,    30,      100]}; 
                end
                
                % variables
                tmax = squeeze(nanmean(nanmean(tmaxBase{3}(xlat, ylon, startYear:endYear, :, :), 2), 1))-273.15;
                tmax = reshape(permute(tmax,[3,2,1]), [numel(tmax), 1]);
                
                pr = squeeze(nanmean(nanmean(prBase{3}(xlat, ylon, startYear:endYear, :, :), 2), 1));
                pr = reshape(permute(pr,[3,2,1]), [numel(pr), 1]);
                
                % build arrays of year, month
                monthList = [];
                yearList = [];
                
                for y = 1:size(tmaxBase{3}, 3)
                    for m = 1:size(tmaxBase{3}, 4)
                        for d = 1:size(tmaxBase{3}, 5)
                            monthList(end+1) = m;
                            yearList(end+1) = y;
                        end
                    end
                end
                nn = find(~isnan(tmax) & ~isnan(pr));
                
                tmax = tmax(nn);
                pr = pr(nn);
                yearList = yearList(nn);
                monthList = monthList(nn);
                
                if detrendData
                    tmax = detrend(tmax);
                    pr = detrend(pr);
                end
                
                if strcmp(dataset, 'ncep-reanalysis')
                    pr = pr.*60.*60.*24; % mm/day
                elseif strcmp(dataset, 'era-interim')
                    pr = pr .* 1000; % mm/day
                end

                % how many days to group over (1 week now)
                groupingN = 5;

                % now compute weekly metrics
                tmaxGroup = arrayfun(@(i) nanmean(tmax(i:i+groupingN-1)),1:groupingN:length(tmax)-groupingN+1)'; 
                tmaxVar = arrayfun(@(i) nanstd(tmax(i:i+groupingN-1)),1:groupingN:length(tmax)-groupingN+1)';
                prGroup = arrayfun(@(i) nansum(pr(i:i+groupingN-1)),1:groupingN:length(pr)-groupingN+1)'; 
                mGroup = arrayfun(@(i) round(nanmean(monthList(i:i+groupingN-1))),1:groupingN:length(monthList)-groupingN+1)'; 
                yGroup = arrayfun(@(i) round(nanmean(yearList(i:i+groupingN-1))),1:groupingN:length(yearList)-groupingN+1)'; 
                
                % if using percentile, convert season params into
                % percentiles...
                if percentile
                    value = seasonProperties('tmax');
                    for v = 1:length(value{2})
                        value{2}(v) = prctile(tmaxGroup, value{2}(v));
                    end
                    seasonProperties('tmax') = value;
                    
                    value = seasonProperties('tmaxVar');
                    for v = 1:length(value{2})
                        value{2}(v) = prctile(tmaxVar, value{2}(v));
                    end
                    seasonProperties('tmaxVar') = value;
                    
                    value = seasonProperties('pr');
                    for v = 1:length(value{2})
                        value{2}(v) = prctile(prGroup, value{2}(v));
                    end
                    seasonProperties('pr') = value;
                end
                
                % build the SOM normalized and non-norm structures
                X = [tmaxGroup, tmaxVar, prGroup]';
                Xn = [normc(tmaxGroup), normc(tmaxVar), normc(prGroup)]';

                % run SOM
                som = selforgmap(dims);
                som.trainParam.epochs = 1000;
                som = configure(som, Xn);
                som.trainParam.showWindow = false;
                som = train(som, Xn);

                % get resulting weekly SOM classes
                y = som(Xn);
                classes = vec2ind(y);

                % stores the variable values for each class
                classVals = [];
                
                % variable names for line plot
                varNames = {'TmaxWeek', 'TmaxVar', 'PrWeek'};

                % loop over all som classes
                for i = 1:max(classes)

                    % find all weeks with this class and what percent of total
                    % weeks they make up
                    ind = find(classes == i);
                    prc = length(ind)/length(classes)*100;

                    % store months for this node
                    %classMonths{i} = mGroup(ind);
                    
                    % most common month
                    topMonth = mode(mGroup(ind));
                    %figure;
                    %hist(mGroup(ind), unique(mGroup(ind)));
                    %title(['Class ' num2str(i)]);

                    %fprintf('Class %i, %.1f, month = %i\n', i, prc, topMonth);

                    % loop over all variables
                    for v = 1:size(Xn, 1)

                        % get the mean variable value for this som class
                        cV = nanmean(X(v, ind));
                        classVals(i,v) = cV;
                        %fprintf('%s = %f\n', varNames{v}, cV);
                    end

                    % generate the season name based on the pre-defined classes
                    % for each variable
                    seasonName = '';

                    s1 = seasonProperties('tmax');
                    s2 = seasonProperties('tmaxVar');
                    s3 = seasonProperties('pr');
                    %s4 = seasonProperties('q');

                    seasonName = [seasonName s1{1}{find(abs(classVals(i, 1) - s1{2}) == min(abs(classVals(i, 1) - s1{2})))} '-'];
                    seasonName = [seasonName s2{1}{find(abs(classVals(i, 2) - s2{2}) == min(abs(classVals(i, 2) - s2{2})))} '-'];
                    seasonName = [seasonName s3{1}{find(abs(classVals(i, 3) - s3{2}) == min(abs(classVals(i, 3) - s3{2})))}];
                    %seasonName = [seasonName s4{1}{find(abs(classVals(i, 4) - s4{2}) == min(abs(classVals(i, 4) - s4{2})))}];

                    % find the class index if we've seen this class before
                    classInd = i;
                    [ix, iy] = find(curTrendName == seasonName);
                    if length(ix) > 0
                        classInd = ix(1);
                    else
                        % if this is a new pattern, look for very similar rows, or put it at the end if we
                        % have empty slots... otherwise discard it
                        if period > 1
                            found = false;
                            % go through each row
                            minDist = -1;
                            minInd = -1;
                            for row = 1:size(curTrendName,1)
                                
                                % nothing stored...
                                if sum(curTrendClasses(row,:)) == 0
                                    continue;
                                end
                                
                                % calc dist between current class and all
                                % other classes
                                dist = 0;
                                for d = 1:size(curTrendClasses, 2)
                                    dist = dist + (curTrendClasses(row,d)-classVals(i,d))^2;
                                end
                                if minDist == -1 || dist < minDist
                                    minDist = dist;
                                    minInd = row;
                                end
                            end
                            
                            fprintf('dist=%.2f\n',minDist);
                            % if dist is small... mark as this class
                            if minDist < 500 && minInd ~= -1
                                classInd = minInd;
                                found = true;
                                rowInd = find(curTrendName(minInd,:) ~= "");
                                seasonName = curTrendName(minInd,rowInd(1));
                            end
                            
                            if ~found
                                for row = 1:size(curTrendName,1)
                                    % find the free cols in this row
                                    indFree = find(curTrendName(row, :) == "");
                                    % if we find a row where all cols are free,
                                    % stop - this is our index
                                    if length(indFree) == size(curTrendName, 2)
                                        classInd = row;
                                        found = true;
                                        break;
                                    end
                                end
                            end
                            % we didn't find  a free row
                            if ~found
                                % add a new row
                                classInd = size(curTrendName, 1) + 1;
                                curTrendOcr = [curTrendOcr; zeros(1, size(curTrendOcr, 2), size(curTrendOcr, 3))];
                                curTrendSig = [curTrendSig; zeros(1, size(curTrendSig, 2))];
                                curTrendName = [curTrendName; strings(1, size(curTrendName, 2))];
                                curTrendClasses = [curTrendClasses; zeros(1, size(curTrendClasses, 2))];
                            end
                        % we're on period 1 - find first free row in first
                        % col
                        else
                            indFree = find(curTrendName(:,1) == "");
                            classInd = indFree(1);
                        end
                    end
                    
                    
                    % store characteristics for this trend, or average them
                    % if there is already a trend for this class
                    occClassInds = find(curTrendClasses(classInd, :) > 0);
                    if occClassInds == size(curTrendClasses, 2)
                        % if occupied, average each value
                        for v = 1:size(curTrendClasses, 2)
                            curTrendClasses(classInd, v) = nanmean([curTrendClasses(classInd, v), classVals(i, v)]);
                        end
                    % otherwise, just copy
                    else
                        curTrendClasses(classInd, :) = classVals(i, :);
                    end
                    
                    % find number of occurence each year (52-week)
                    numGroupsYear = floor(length(tmaxGroup)/yearN);
                    occurrence = arrayfun(@(x) length(find((classes(x:x+numGroupsYear-1))==i)), 1:numGroupsYear:length(classes)-numGroupsYear+1)';
                    
                    % this is a duplicate trend - add occurrences
                    if sum(curTrendOcr(classInd, :, period)) > 0
                        curTrendOcr(classInd, :, period) = squeeze(curTrendOcr(classInd, :, period))' + occurrence;
                    else
                        curTrendOcr(classInd, :, period) = occurrence;
                        curTrendName(classInd, period) = seasonName;
                    end
                    
                    yearNodeCounts = {};
                    for y = 1:max(yGroup)
                        % all indices with this year
                        yearInds = find(yGroup == y);
                        
                        % find only month counts that occured in this year
                        annualMonthCounts = mGroup(intersect(ind, yearInds));
                        
                        yearNodeCounts{y} = annualMonthCounts;
                    end       
                    if length(classMonths) < classInd
                        classMonths{classInd} = {};
                    end
                    classMonths{classInd} = {classMonths{classInd}{:}, yearNodeCounts};

                    f = fit((1:length(occurrence))', occurrence, 'poly1');
                    ci = confint(f, 0.95);
                    
                    [h,p] = Mann_Kendall(occurrence, 0.05);
                    curTrendSig(classInd, period) = h;
                end
            end

            curTrend('pos') = {latInd(1):gridSize:latInd(end), lonInd(1):gridSize:lonInd(end), curTrendPos};
            curTrend('occurrence') = curTrendOcr;
            curTrend('significant') = curTrendSig;
            curTrend('name') = curTrendName;
            curTrend('characteristics') = {varNames, curTrendClasses};

            seasonalTrends{end+1} = curTrend;

        end
    end

    save(['som-trend-' num2str(somRun)], 'seasonalTrends');

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
            if sum(sig(s, :)) == length(subPeriods)
                try
                    trendMap(xlat, ylon) = trendMap(loc{3}(1,1), loc{3}(2,1)) + 1;
                catch
                    trendMap(xlat, ylon) = 1;
                end
            end
        end

        if plotLine
            if size(trendMap,1) >= xlat && size(trendMap,2) >= ylon && trendMap(xlat, ylon) > 0
            
                % only plot seasons that show up in each period...
                plotInd = [];
                seasonNames = {};
                % change to not show plots for nodes that don't show up in
                % all periods
                for row = 1:size(name,1)
                    if length(find(name(row,:) ~= "")) == size(name, 2)
                        plotInd(end+1) = row;
                        seasonNames{end+1} = name{row,1};
                    end
                end
            
                figure('Color',[1,1,1]);
                hold on;
                grid on;
                axis square;
                box on;

                colors = distinguishable_colors(length(plotInd));
                legItems = [];
                for row = 1:length(plotInd)
                    p = plot(squeeze(ocr(plotInd(row),:,1)), 'Color', colors(row, :));
                    legItems(end+1) = p;

                    if sum(sig(plotInd(row), :)) == length(subPeriods)
                        f = fit((1:size(ocr,2))', squeeze(ocr(plotInd(row), :, 1))', 'poly1');
                        plot(1:size(ocr,2), f(1:size(ocr,2)), 'LineStyle', '--', 'Color', colors(row, :));
                    end
                end
                title(['Lat/lon: (' num2str(round(lat(round(nanmean(loc{1})), round(nanmean(loc{2}))))) ', ' ...
                                    num2str(round(lon(round(nanmean(loc{1})), round(nanmean(loc{2}))))) ')']);

                legend(legItems,seasonNames);
                
                export_fig(['trend-' num2str(t) '.png']);
            end
        end
    end
end

if plotMap
    result = {localLat, localLon, trendMap};
    plotModelData(result, 'north america', 'caxis', [0 4]);
    export_fig(['trend-map.png']);
end

monthCounts = zeros(length(classMonths),yearN,12);

% look at # trends per month/year
for i = 1:length(classMonths)
    figure;
    hold on;
    
    for p = 1:length(classMonths{i})
        for y = 1:length(classMonths{i}{p})
            for m = 1:12
                monthCounts(i, y, m) = monthCounts(i, y, m) + length(find(classMonths{i}{p}{y} == m));
            end
        end
    end
    
    for m = 1:12
        subplot(3,4,m)
        hold on;
        box on;
        axis square;
        d = squeeze(monthCounts(i,:,m));
        plot(d)
        
        [h,p] = Mann_Kendall(d, 0.05);
        if h
            f = fit((1:size(monthCounts, 2))', d', 'poly1');
            plot(1:size(monthCounts,2),f(1:size(monthCounts,2)));
        end
        title(['Month ' num2str(m)]);
    end
   
    
    c = seasonalTrends{1}('characteristics');
    c = c{2};
    names = seasonalTrends{1}('name');
    suptitle(names{i,1});
    %suptitle(['tmax = ' num2str(round(c(i,1))) ', var = ' num2str(round(c(i,2))), ', pr = ' num2str(round(c(i,3)))]);
    
end

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

