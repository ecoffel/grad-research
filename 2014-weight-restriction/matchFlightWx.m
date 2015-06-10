years = 2003:2008;
dataBaseDir = 'aviation-weather/data/';
flightCount = 0;

for y = years
    flightWx = {};
    tmpFlightWx = {};
    tmpFlightCount = 0;
    
    ['loading flights', num2str(y), '...']
    load([dataBaseDir, 'flights', num2str(y), '.mat']);
    curFlights = eval(['flights', num2str(y), ';']);
    eval(['clear flights', num2str(y), ';']);
    
    for f = 1:length(curFlights)
        [year, month, day, hour, minute] = datevec(curFlights{f}{6});
        wxVarName = ['wx_', curFlights{f}{3}, '_', num2str(year), '_', sprintf('%02d',month)];
        if ~exist(wxVarName)
            if exist([dataBaseDir, wxVarName, '.mat'], 'file')
                ['loading ', wxVarName, '...']
                load([dataBaseDir, wxVarName, '.mat']); 
            else
                continue;
            end
        end
        
        % find wx observation for the departure airport closest to the
        % scheduled departure time
        depTime = curFlights{f}{6};
        wxTimesVar = ['wxTimes_', curFlights{f}{3}, '_', num2str(year), '_', sprintf('%02d',month)];
        if ~exist(wxTimesVar)
            eval([wxTimesVar, ' = cellfun(@(x) x{2}, eval(wxVarName), ''UniformOutput'', false);']);
        end
        curWxTimesVar = eval(['abs([', wxTimesVar, '{:}]''-depTime);']);
        ind = find(curWxTimesVar == min(curWxTimesVar));
        if length(ind) > 0
            tmpFlightWx{tmpFlightCount+1} = {curFlights{f} eval([wxVarName, '{ind}'])};
            flightCount = flightCount+1;
            tmpFlightCount = tmpFlightCount+1;
            
            if mod(flightCount, 100) == 0
                [num2str(flightCount) ' flights processed...']
            end
            
            if mod(flightCount, 2000) == 0
                flightWx = {flightWx{:} tmpFlightWx{:}};
                tmpFlightCount = 0;
                tmpFlightWx = {};
            end
        end
    end
    
    eval(['flightWx', num2str(y), ' = flightWx;']);
    save([dataBaseDir, 'flightWx', num2str(y), '.mat'], ['flightWx', num2str(y)]);
    eval(['clear flightWx', num2str(y), ';']);
    clear flightWx tmpFlightWx;
end