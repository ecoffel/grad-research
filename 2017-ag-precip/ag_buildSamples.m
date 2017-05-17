% load cropWxData (produced by ag_mergeCropWxData.m) and select the parts
% of the wx data that match the samples here

cropDataBaseDir = 'f:/data/ag/crop/';

tempPrc = 99.9;
precipPrc = 99.9;

pcnt = 0;
tcnt = 0;

% whether to generate full dataset with group and original hourly wx data
% or just groups and seasonal summaries
full = false;

% find names of all state crop data files
txtFileNames = dir([cropDataBaseDir, '/*.mat']);
txtFileNames = {txtFileNames.name};

% loop over states
for s = 1:length(txtFileNames)
    
    curFileParts = strsplit(txtFileNames{s}, '.');
    
    ['loading ' txtFileNames{s} '...']
    cropWxData = load([cropDataBaseDir txtFileNames{s}]);
    cropWxData = cropWxData.cropWxData;
    
    % loop over counties
    for c = 1:length(cropWxData{3})
        
        % if county doesn't have matched wx data, skip it
        if length(cropWxData{3}{c}) == 5
            cropWxData{3}{c}{5} = {};
            continue;
        end
        
        ['processing ' cropWxData{1} '/' cropWxData{3}{c}{1} '...']
        
        temp = cropWxData{3}{c}{7}{1}{end-2};
        precip = cropWxData{3}{c}{7}{1}{end};

        years = cropWxData{3}{c}{7}{1}{4};
        months = cropWxData{3}{c}{7}{1}{5};

        % select only growing season from april - sept
        growingSeasonInd = find(months>= 4 & months <= 9);

        if length(growingSeasonInd) == 0
            continue;
        end
        
        temp = temp(growingSeasonInd);
        precip = precip(growingSeasonInd);
        years = years(growingSeasonInd);
        months = months(growingSeasonInd);

        % calculate seasonal means
        tempMean = [];
        precipSum = [];
        
        tempThresh = prctile(temp, tempPrc);
        precipThresh = prctile(precip, tempPrc);

        tempGroup = [];
        precipGroup = [];
        
        % the indicies that mark the beginning of each year in the wx data
        yearInd = [];
        
        % find groups
        lastYear = years(1);
        lastYearStartInd = 1;
        lastYearEndInd = 1;
        
        % first dim = index
        yearInd(1, 1) = 1;
        % second dim = year
        yearInd(1, 2) = years(1);
        
        % loop over all years
        for y = 1:length(years)
            
            % if we are on a new year, use collected indicies to select
            % temp/precip data for this year
            if years(y) ~= lastYear && y <= length(temp) && y <= length(precip)
                lastYear = years(y);
                lastYearEndInd = y-1;
                
                tempYear = temp(lastYearStartInd:lastYearEndInd);
                precipYear = precip(lastYearStartInd:lastYearEndInd);
                
                % take the seasonal mean temperature
                tempMean(end+1) = nanmean(tempYear);
                
                % and sum of seasonal precip
                precipSum(end+1) = nansum(precipYear);
                
                % if there were any temps that exceeded the threshold,
                % stick this into the temp category
                if length(find(tempYear > tempThresh)) > 0
                    tempGroup(end+1) = years(y);

                % otherwise, stick it into the precip category
                elseif length(find(precipYear > precipThresh)) > 0
                    precipGroup(end+1) = years(y);
                end
                
                % mark the starting point of the next year
                yearInd(size(yearInd, 1)+1, 1) = y;
                yearInd(size(yearInd, 1), 2) = years(y);
                
                lastYearStartInd = y;
            end
        end

        % count how many temp/precip years we have
        tcnt = tcnt + length(tempGroup);
        pcnt = pcnt + length(precipGroup);
        
        tempGroupings = {};
        precipGroupings = {};
        
        % add temp years
        for tInd = 1:length(tempGroup)
            % find starting index of this year from the temp group
            yIndStart = find(yearInd(:, 2) == tempGroup(tInd));
            yIndEnd = yIndStart + 1;
            
            if yIndEnd < size(yearInd, 1)
                curTempData = temp(yearInd(yIndStart, 1):yearInd(yIndEnd, 1));
            else
                curTempData = temp(yearInd(yIndStart, 1):end);
            end
            
            tempGroupings{end+1} = {tempGroup(tInd), curTempData};
        end
        
        % add precip years
        for pInd = 1:length(precipGroup)
            % find starting index of this year from the temp group
            yIndStart = find(yearInd(:, 2) == precipGroup(pInd));
            yIndEnd = yIndStart + 1;
            
            if yIndEnd < size(yearInd, 1)
                curPrecipData = precip(yearInd(yIndStart, 1):yearInd(yIndEnd, 1));
            else
                curPrecipData = precip(yearInd(yIndStart, 1):end);
            end
            
            precipGroupings{end+1} = {precipGroup(pInd), curPrecipData};
        end
        
        if full
            % keep the full weather dataset
            cropWxData{3}{c}{7}{2} = {tempGroupings, precipGroupings, yearInd(:, 2), tempMean, precipSum};
        else
            % just include the grouped wx data and seasonal means
            cropWxData{3}{c}{7}{1} = {tempGroupings, precipGroupings, yearInd(:, 2), tempMean, precipSum};
        end
    end
    
    ['saving grouped data...']
    if full
        save(['2017-ag-precip/ag-data/' curFileParts{1} '-grouped-full'], 'cropWxData', '-v7.3');
    else
        save(['2017-ag-precip/ag-data/' curFileParts{1} '-grouped-small'], 'cropWxData', '-v7.3');
    end
end


