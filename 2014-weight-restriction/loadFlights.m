airports = {'DEN', 'PHX', 'LGA', 'DCA', 'SEA'};
blockSize = 10000;
flightsProcessed = 0;
flightsAdded = 0;

months = [12 1 2 6:8];

for y = 2003:2008
    f = fopen(['e:/data/flight/flight-stats/year', num2str(y), '.csv']);
    ['year ' num2str(y)]
    
    flights = {};
    while ~feof(f)
        curFlightData = textscan(f, '%f %f %f %*s %s %s %*s %*s %s %f %*s %*s %*s %*s %*s %f %s %s %*s %*s %*s %f %*[^\n]', ...
                                 blockSize, 'Delimiter', ',', 'HeaderLines', 1, 'TreatAsEmpty', 'NA');
        
        departureAirports = curFlightData{9};
        departureMonths = curFlightData{2};
        indices = find(ismember(departureAirports, airports) & ismember(departureMonths, months));
        clear departureAirports departureMonths;
        
        curFlights = {};
        for j = 1 : length(indices)
            i = indices(j);
            
            year = curFlightData{1}(i);
            month = curFlightData{2}(i);
            day = curFlightData{3}(i);
            
            % pad the times w/ a leading zero if necessary
            actDepTime = sprintf('%04s', curFlightData{4}{i});
            schedDepTime = sprintf('%04s', curFlightData{5}{i});
            
            schedDepTime = datenum(year, month, day, str2num(schedDepTime(1:2)), str2num(schedDepTime(3:4)), 0);
            actDepTime = datenum(year, month, day, str2num(actDepTime(1:2)), str2num(actDepTime(3:4)), 0);
            
            airline = curFlightData{6}{i};
            flightNumber = curFlightData{7}(i);
            depDelay = curFlightData{8}(i);
            origin = curFlightData{9}{i};
            dest = curFlightData{10}{i};
            cancelled = curFlightData{11}(i);
            
            if length(curFlights) == 0
                curFlights = {{airline, flightNumber, origin, dest, depDelay, schedDepTime, actDepTime, cancelled}};
                flightsAdded = flightsAdded+1;
            else
                curFlights = {curFlights{:} {airline, flightNumber, origin, dest, depDelay, schedDepTime, actDepTime, cancelled}};
                flightsAdded = flightsAdded+1;
            end
            
        end
        clear curFlightData;
        
        if length(flights) == 0
            flights = curFlights;
        else
            flights = {flights{:} curFlights{:}};
        end
        
        clear curFlights;
        flightsProcessed = flightsProcessed+blockSize;
        [num2str(flightsAdded) ' flights added, ' num2str(flightsProcessed) ' flights processed...']
    end
    eval(['flights', num2str(y), ' = flights;']);
    save(['aviation-weather/flights', num2str(y), '.mat'], ['flights', num2str(y)]);
    eval(['clear flights', num2str(y), ';']);
    clear flights;
end

