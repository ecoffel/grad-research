
baseAgDataDir = '2017-ag-precip/ag-data/';
fileNames = {'corn-yield-al-ia-1970-2015.csv', ...
             'corn-yield-ks-ne-1970-2015.csv', ...
             'corn-yield-nj-wy-1970-2015.csv'}; 

% load the census county database
countyDb = ag_loadCountyDb();

% load state abriviations
stateDb = ag_loadStateDb();
         
% this is for NASS QuickStat yield data - read each column as a string
fileFormatStr = '%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s';

cropData = {};

% process all files
for f = 1:length(fileNames)
    fileName = fileNames{f};
    
    fin = fopen([baseAgDataDir fileName]);
    data = textscan(fin, fileFormatStr, 'Delimiter', ',');

    % columns:
    % 2 - year (int)
    % 6 - state name (str)
    % 7 - state ID (int)
    % 8 - ag district (str)
    % 9 - ag district ID (int)
    % 10 - county name (str)
    % 11 - county ID (int)
    % 22 - value (float)

    % remove double quotes and convert to number
    years = cell2mat(cellfun(@(x) str2num(strrep(x, '"', '')), data{2}, 'UniformOutput', 0));
    stateName = cellfun(@(x) strrep(x, '"', ''), data{6}, 'UniformOutput', 0);
    stateId = cell2mat(cellfun(@(x) str2num(strrep(x, '"', '')), data{7}, 'UniformOutput', 0));
    countyName = cellfun(@(x) strrep(x, '"', ''), data{10}, 'UniformOutput', 0);
    countyId = cellfun(@(x) str2num(strrep(x, '"', '')), data{11}, 'UniformOutput', 0);
    
    % some of the ids are empty, so replace them with -1 before converting
    % cell to mat so that all of our matricies are the same size
    for i = 1:length(countyId)
        if length(countyId{i}) == 0
            countyId{i} = [-1];
        end
    end
    countyId = cell2mat(countyId);
    
    yield = cell2mat(cellfun(@(x) str2num(strrep(x, '"', '')), data{22}, 'UniformOutput', 0));

    % remove first row (header)
    stateName(1) = [];
    countyName(1) = [];

    minYear = min(years);
    maxYear = max(years);
    
    % build a look up table for states and counties
    lookupTable = {};
    
    % sequential numbers for current state
    curStateInd = 0;

    % sequential numbers for counties, reset for each state
    curCountyInd = 0;

    % loop over all entries in the crop data (states + counties)
    for i = 1:length(stateName)

        % check if we've seen the state before
        repeatState = false;
        for j = 1:length(cropData)

            % names match - we've seen the state before, so use its
            % id rather than creating a new one
            if strcmp(cropData{j}{1}, stateName{i})
                curStateInd = j;

                % now check if we have seen this county before, or
                % if we should move on to a new one
                repeatCounty = false;
                for k = 1:length(cropData{j}{3})
                    % seen it before
                    if strcmp(cropData{j}{3}{k}{1}, countyName{i})
                        curCountyInd = k;
                        repeatCounty = true;
                        break;
                    end
                end

                % new county, start on the next county ID for this state
                if ~repeatCounty
                    curCountyInd = length(cropData{j}{3}) + 1;
                end

                repeatState = true;
            end
        end

        % we are on a new state
        if ~repeatState
            curStateInd = length(cropData) + 1;
            curCountyInd = 1;
        end

        % create cell for the state if it doesn't exist
        if length(cropData) < curStateInd
            
            % find state abriviation in lookup table
            stateAb = '';
            for s = 1:length(stateDb)
                if strcmp(lower(stateName{i}), lower(stateDb{1}{s}))
                    stateAb = upper(stateDb{2}{s});
                    break;
                end
            end
            
            cropData{curStateInd} = {stateAb, stateId(i), {}};
        end

        % create a new cell for the county if it doesn't exist
        if length(cropData{curStateInd}{3}) < curCountyInd
            
            % find lat/lon of this county in the county DB
            countyLat = -1;
            countyLon = -1;
            
            % first find correct state - loop over states
            for s = 1:length(countyDb)
                if strcmp(upper(countyDb{s}{1}), upper(cropData{curStateInd}{1}))
                    
                    % loop over counties
                    for c = 1:length(countyDb{s})
                        % we have found the DB county that matches the
                        % current county
                        if strcmp(lower(countyDb{s}{2}{c}{1}), lower(countyName{i}))
                            % set its lat/lon
                            countyLat = countyDb{s}{2}{c}{2};
                            countyLon = countyDb{s}{2}{c}{3};
                            break;
                        end
                    end
                    
                    break;
                end
            end
            
            cropData{curStateInd}{3}{curCountyInd} = {countyName{i}, countyId(i), countyLat, countyLon, []};
        end

        % store the data in the proper state & county
        cropData{curStateInd}{3}{curCountyInd}{3}(years(i) - minYear + 1) = yield(i);
    end     
end

save('ag-corn-yield-us.mat', 'cropData');