function [stateDb] = ag_loadStateDb()
    
    filePath = '2017-ag-precip/ag-data/states.csv';
    
    fileFormat = '%s%s%*[^\n]';
    
    % open and read the file
    fin = fopen(filePath, 'r');
    data = textscan(fin, fileFormat, 'Delimiter', ',');
    
    % strip off double quotes from each column
    names = cellfun(@(x) strrep(x, '"', ''), data{1}, 'UniformOutput', false);
    abriviations = cellfun(@(x) strrep(x, '"', ''), data{2}, 'UniformOutput', false);
    
    fclose(fin);
    
    stateDb = {names, abriviations};

end