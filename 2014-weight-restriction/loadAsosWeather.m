airports = {'DEN', 'PHX', 'LGA', 'DCA'};
%airports = {'DCA'};
blockSize = 1000;
wxDir = 'e:/data/flight/wx/raw/asos-5'
outputDir = 'e:/data/flight/wx/output/asos-5';
wxObsAdded = 0;

for y = 2003:2012
    
    for a = 1:length(airports)
        curAirport = airports{a};
        curDir = [wxDir, num2str(y)];
        datFileNames = dir([wxDir, num2str(y), '/*.dat']);
        datFileNames = {datFileNames.name};
        
        for f = 1 : length(datFileNames)
            wx = {};
            curFile = datFileNames{f};
            curFileParts = strsplit(curFile, '.');
            fileYear = curFileParts{1}(end-5:end-2);
            fileMonth = curFileParts{1}(end-1:end);
            fileCode = curFileParts{1}(end-8:end-6);
            
            if ~strcmp(fileCode, curAirport)
                continue;
            end
            
            f = fopen([curDir '/' curFile]);

            while ~feof(f)
                curWxData = textscan(f, '%s', blockSize, 'Delimiter', '\n');
                curWx = {};
                
                lastRecTemp = -9999;
                
                for i = 1 : length(curWxData{1})
                    line = curWxData{1}{i};
                    lineParts = strsplit(line, ' ');

                    dateStr = lineParts{2};
                    year = y;
                    month = str2num(dateStr(8:9));
                    day = str2num(dateStr(10:11));
                    if length(lineParts) < 9
                        continue
                    else
                        if length(lineParts{6}) ~= 7
                            continue;
                        end
                    end
                    hour = str2num(lineParts{6}(3:4));
                    minute = str2num(lineParts{6}(5:6));
                    time = datenum(year, month, day, hour, minute, 0);

                    code = lineParts{5}(2:end);

                    windDir = -9999;
                    windSpd = -9999;
                    windGust = -9999;
                    vis = -9999;
                    temp = -9999;

                    % find wind
                    windIndex = find(cellfun(@(x) ~isempty(x), cellfun(@(x) findstr(x, 'KT'), lineParts, 'UniformOutput', false)));
                    if length(windIndex) > 0
                        if length(lineParts{windIndex(1)}) >= 5
                            windDir = str2num(lineParts{windIndex(1)}(1:3));
                            windSpd = str2num(lineParts{windIndex(1)}(4:5));
                            if length(lineParts{windIndex(1)}(1:end-2)) > 5
                                windGust = str2num(lineParts{windIndex(1)}(7:end-2));
                            end
                        end
                    end

                    % find visibility
                    visIndex = find(cellfun(@(x) ~isempty(x), cellfun(@(x) findstr(x, 'SM'), lineParts, 'UniformOutput', false)));
                    if length(visIndex) > 0
                        if length(strfind(lineParts{visIndex(1)}, '/')) > 0
                            visParts = strsplit(lineParts{visIndex(1)}(1:end-2), '/');
                            vis = str2num(visParts{1})/str2num(visParts{2});
                        else
                            vis = str2num(lineParts{visIndex(1)}(1:end-2));
                        end
                    end

                    % find temperature
                    tempSearchStart = min(6, length(lineParts));
                    tempSearchEnd = min(13, length(lineParts));
                    tempIndex = find(cellfun(@(x) ~isempty(x), cellfun(@(x) findstr(x, '/'), lineParts(tempSearchStart:tempSearchEnd), 'UniformOutput', false)));
                    if length(tempIndex) > 0
                        tempSubIndex = 1;
                        while tempSubIndex <= length(tempIndex)
                            tempParts = strsplit(lineParts{tempIndex(tempSubIndex)+tempSearchStart-1}, '/');
                            if length(tempParts{1}) < 4 & length(tempParts{2}) < 4
                                break;
                            end
                            tempSubIndex = tempSubIndex+1;
                        end
                        if length(tempParts{1} > 0) | length(tempParts{1}) < 4
                            tempParts{1} = strrep(tempParts{1}, 'M', '');
                            tempParts{1} = strrep(tempParts{1}, 'R', '');
                            if length(find(~isstrprop(tempParts{1}, 'digit'))) == 0
                                temp = str2num(tempParts{1});
                            end
                        end
                    end
                    
                    % temp out of range
                    if temp > 60 | temp < -50
                        temp = -9999;
                    end
                    
                    % temp difference between obs too large
                    if lastRecTemp ~= -9999 & abs(lastRecTemp - temp) > 8
                        temp = -9999;
                    end
                    
                    if lastRecTemp == -9999 & temp ~= -9999
                        lastRecTemp = temp;
                    end
                    
                    if length(curWx) == 0
                        curWx = {{code, time, temp, windDir, windSpd, windGust, vis}};
                        wxObsAdded = wxObsAdded+1;
                    else
                        curWx = {curWx{:} {code, time, temp, windDir, windSpd, windGust, vis}};
                        wxObsAdded = wxObsAdded+1;
                    end
                end
                clear curWxData;

                if length(wx) == 0
                    wx = curWx;
                else
                    wx = {wx{:} curWx{:}};
                end

                [num2str(wxObsAdded) ' obs added...']
                clear curWx;
            end

            eval(['wx_', fileCode, '_', fileYear, '_', fileMonth, ' = wx;']);
            save([outputDir, '/wx_', fileCode, '_', fileYear, '_', fileMonth, '.mat'], ...
                 ['wx_', fileCode, '_', fileYear, '_', fileMonth]);
            eval(['clear wx_', fileCode, '_', fileYear, '_', fileMonth, ';']);
            clear wx;
        end
    end
end