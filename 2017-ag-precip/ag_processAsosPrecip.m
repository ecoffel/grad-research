
baseDir = 'e:/data/asos/';

states = {'ia'};

% this is for comma delimited ASOS data with the format:
% station, time, lon, lat, tempC, relH, precipH
fileFormatStr = '%s%s%s%s%s%s%s%*[^\n]';

asosStations = {};
asosData = {};

% how many rows to read at a time
N = 100000;

% process all files
for s = 1:length(states)
    state = states{s};
    
    fin = fopen([baseDir 'asos-' state '.txt']);
    
    % skip first 6 lines (headers)
    textscan(fin, fileFormatStr, 6, 'Delimiter', ',');
    
    while ~feof(fin)
        [data, pos] = textscan(fin, fileFormatStr, N, 'Delimiter', ',');
        
        ['pos = ' num2str(pos)]
        
        % columns:
        % 1 - station
        % 2 - date/time
        % 3 - lon
        % 4 - lat
        % 5 - temp (C)
        % 6 - rel humidity (%)
        % 7 - precip (hourly, mm, M = none)

        % remove double quotes and convert to number
        stations = data{1};
        dateTimes = data{2};
        lons = data{3};
        lats = data{4};
        temps = data{5};
        relHs = data{6};
        precips = data{7};
        
        for sInd = 1:length(stations)
            [lia, locb] = ismember(stations{sInd}, asosStations);
            
            dateTime = dateTimes{sInd};
            lon = str2num(lons{sInd});
            lat = str2num(lats{sInd});
            temp = str2num(temps{sInd});
            relH = str2num(relHs{sInd});
            if strcmp(precips{sInd}, 'M')
                precip = NaN;
            else
                precip = str2num(relHs{sInd});
            end
            
            if lia == 0
                asosData{end+1} = {stations{sInd}, lon, lat, temp, relH, precip};
                asosStations{end+1} = stations{sInd};
            else
                asosData{locb}{4} = [asosData{locb}{4}; temp];
                asosData{locb}{5} = [asosData{locb}{5}; relH];
                asosData{locb}{6} = [asosData{locb}{6}; precip];
            end
        end
        
        clear station dateTime lon lat temp relH precip;
    end
      
end

%save('cropData.mat', 'cropData');