function [countyDb] = loadCountyDb()
    filePath = '2017-ag-precip/ag-data/counties.txt';
    
    headerLines = 1;
    fileFormat = '%s%n%n%s%n%n%n%n%n%n%n%n%*[^\n]';
    
    % open the file
    fin = fopen(filePath);
    
    % skip header lines
    textscan(fin, '%*[^\n]', headerLines);
    
    % read the main data
    countyDb = textscan(fin, fileFormat, 'Delimiter', '\t');
    
    % close
    fclose(fin);
    
    % db columns
    % 1 - state
    % 4 - county name
    % 11 - lat
    % 12 - long
    
    states = cellfun(@(x) strtrim(x), countyDb{1}, 'UniformOutput', false);
    countyNames = cellfun(@(x) strtrim(strrep(x, 'County', '')), countyDb{4}, 'UniformOutput', false);
    lats = countyDb{11};
    longs = countyDb{12};
    
    % counties organized by state
    % {state} => {stateName, {counties} => {countyName, lat, lon}}
    newCountyDb = {};
    
    lastState = '';
    for s = 1:length(states)
        % move on to the next state
        if ~strcmp(states{s}, lastState)
            lastState = states{s};
            % create new entry in db for this state
            newCountyDb{end+1} = {states{s}, {}};
        end
        
        newCountyDb{end}{2}{end+1} = {countyNames{s}, lats(s), longs(s)};
    end
    
    countyDb = newCountyDb;

end