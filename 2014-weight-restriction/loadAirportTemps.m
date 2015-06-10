airports = {'LGA', 'DCA', 'DEN', 'PHX'};
stationNumbers = [14732, 13743, 03017, 23183];
blockSize = 1000;
wxDir = 'e:/data/flight/wx/raw/daily/airport-temps.csv';
outputDir = 'e:/data/flight/wx/output/daily';
wxObsAdded = 0;

f = fopen([wxDir]);
header = false;

curTmax = [];
curTmin = [];
curStation = -1;
curYear = -1;
curMonth = -1;

while ~feof(f)
    curWxData = textscan(f, '%s', blockSize, 'Delimiter', '\n');
    
    for i = 1 : length(curWxData{1})
        if ~header
            header = true;
            continue;
        end
        
        line = curWxData{1}{i};
        lineParts = strsplit(line, ',');
        
        stationId = str2num(lineParts{1}(end-4:end));
        
        year = str2num(lineParts{3}(1:4));
        month = str2num(lineParts{3}(5:6));
        day = str2num(lineParts{3}(7:8));
        
        tmax = str2num(lineParts{4})/10.0;
        tmin = str2num(lineParts{5})/10.0;
        
        if month ~= curMonth | curMonth == -1 | stationId ~= curStation
            % clear data and write file
            
            if curMonth ~= -1
                airportCode = airports{find(stationNumbers == curStation)};
                
                eval(['tasmax_', airportCode, '_', num2str(curYear), '_', sprintf('%02d', curMonth), '_01', ' = curTmax;']);
                eval(['tasmin_', airportCode, '_', num2str(curYear), '_', sprintf('%02d', curMonth), '_01', ' = curTmin;']);

                save([outputDir, '/tasmax_', airportCode, '_', num2str(curYear), '_', sprintf('%02d', curMonth), '_01', '.mat'], ...
                     ['tasmax_', airportCode, '_', num2str(curYear), '_', sprintf('%02d', curMonth), '_01']);

                save([outputDir, '/tasmin_', airportCode, '_', num2str(curYear), '_', sprintf('%02d', curMonth), '_01', '.mat'], ...
                     ['tasmin_', airportCode, '_', num2str(curYear), '_', sprintf('%02d', curMonth), '_01']);

                eval(['clear tasmax_', airportCode, '_', num2str(curYear), '_', sprintf('%02d', curMonth), '_01', ';']);
                eval(['clear tasmin_', airportCode, '_', num2str(curYear), '_', sprintf('%02d', curMonth), '_01', ';']);
                clear curTmax curTmin;
            end
            
            curTmax = [];
            curTmin = [];
            curMonth = month;
            curStation = stationId;
        end
        
        if year ~= curYear | curYear == -1    
            curYear = year;
        end
        
        curTmax = [curTmax; tmax];
        curTmin = [curTmin ;tmin];
    end
end