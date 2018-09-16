
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

dataset = 'ncep-reanalysis';

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
                prBase{3}(xlat, ylon) = NaN;
            end
        end
    end
end

% select lat/lon
%[latInd, lonInd] = latLonIndexRange(tmaxBase, [45 45], [9 9]); % milan
[latInd, lonInd] = latLonIndexRange(tmaxBase, [40 40], [269 269]); % iowa
%[latInd, lonInd] = latLonIndexRange(tmaxBase, [41 41], [285 285]); % nyc
%[latInd, lonInd] = latLonIndexRange(tmaxBase, [34 34], [276 276]); % ATL
%[latInd, lonInd] = latLonIndexRange(tmaxBase, [33 33], [247 247]); % phoenix
%[latInd, lonInd] = latLonIndexRange(tmaxBase, [27 27], [281 281]); % miami
%[latInd, lonInd] = latLonIndexRange(tmaxBase, [47 47], [238 238]); % seattle
%[latInd, lonInd] = latLonIndexRange(tmaxBase, [40 40], [255 255]); % denver

%[latInd, lonInd] = latLonIndexRange(tmaxBase, [38 42], [278 282]); % central US

avoidWater = true;
gridSize = 1;
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

        % variables
        tmax = squeeze(nanmean(nanmean(tmaxBase{3}(xlat, ylon, :, :, :), 2), 1))-273.15;
        %tmax = reshape(permute(tmax,[3,2,1]), [numel(tmax), 1]);

        pr = squeeze(nanmean(nanmean(prBase{3}(xlat, ylon, :, :, :), 2), 1));
        %pr = reshape(permute(pr,[3,2,1]), [numel(pr), 1]);

        figure('Color',[1,1,1]);
        for month = 1:12
            subplot(3,4,month);
            hold on;
            axis square;
            grid on;
            box on;
            
            monthTemps = squeeze(nanmean(tmax(:, month, :), 3));
            monthStd = squeeze(nanstd(tmax(:, month, :), [], 3));
            monthPr = squeeze(nanmean(pr(:, month, :), 3));
            
            yyaxis left;
            plot(monthTemps);
            if Mann_Kendall(monthTemps, 0.05)
                f = fit((1:length(monthTemps))', monthTemps, 'poly1');
                plot(1:length(monthTemps), f(1:length(monthTemps)), '--');
            end
            
            plot(monthStd, 'g-');
            if Mann_Kendall(monthStd, 0.05)
                f = fit((1:length(monthStd))', monthStd, 'poly1');
                plot(1:length(monthStd), f(1:length(monthStd)), 'g--');
            end
            
            yyaxis right;
            plot(monthPr);
            if Mann_Kendall(monthPr, 0.05)
                f = fit((1:length(monthPr))', monthPr, 'poly1');
                plot(1:length(monthPr), f(1:length(monthPr)), '--');
            end
            
            title(['Month ' num2str(month)]);
        end
        
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
% 
%         % how many days to group over (1 week now)
%         groupingN = 5;
% 
%         % now compute weekly metrics
%         tmaxGroup = arrayfun(@(i) nanmean(tmax(i:i+groupingN-1)),1:groupingN:length(tmax)-groupingN+1)'; 
%         tmaxVar = arrayfun(@(i) nanstd(tmax(i:i+groupingN-1)),1:groupingN:length(tmax)-groupingN+1)';
%         prGroup = arrayfun(@(i) nansum(pr(i:i+groupingN-1)),1:groupingN:length(pr)-groupingN+1)'; 
%         mGroup = arrayfun(@(i) round(nanmean(monthList(i:i+groupingN-1))),1:groupingN:length(monthList)-groupingN+1)'; 
%         yGroup = arrayfun(@(i) round(nanmean(yearList(i:i+groupingN-1))),1:groupingN:length(yearList)-groupingN+1)'; 
    end
end
