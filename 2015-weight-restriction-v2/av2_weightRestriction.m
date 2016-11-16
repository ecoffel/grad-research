if ~exist('airportDb', 'var')
    airportDb = loadAirportDb('e:\data\flight\airports.dat');
end

obsAirports = {'PHX', 'LGA', 'DCA', 'DEN'};%, 'ORD', 'IAH', 'LAX', 'MIA'};
airportRunway = {11500, 7000, 7170, 16000};%, 13000, 12000, 12000, 13000};
airportElevation = {1135, 23, 14, 5433};%, 680, 96, 127, 9};

airportLats = [];
airportLons = [];

for a = 1:length(obsAirports)
    [code, airportLat, airportLon] = searchAirportDb(airportDb, 'DCA');
    airportLats(a) = airportLat;
    airportLons(a) = airportLon;
end

obsPeriods = {1981:2011, 1981:2011, 1981:2011, 1996:2011};
months = [6 7 8];

obsTasmaxDir = 'e:/data/flight/wx/output/daily/tasmax';
obsTasminDir = 'e:/data/flight/wx/output/daily/tasmin';

% hourly temperature data, interpolated between observed daily max and min
obsData = {};

% now load the obs at the end
for a = 1:length(obsAirports)
    obsStart(a) = obsPeriods{a}(1);
    obsEnd(a) = obsPeriods{a}(end);
    
    % load daily maximum temps
    curObsMax = loadDailyData(obsTasmaxDir, 'yearStart', obsStart(a), 'yearEnd', obsEnd(a), 'obs', 'daily', 'obsAirport', obsAirports{a});
    curObsMax = curObsMax(:, months, :);
    curObsMax = reshape(curObsMax, [size(curObsMax, 1), size(curObsMax, 2)*size(curObsMax, 3)]);
    
    % and daily minimums
    curObsMin = loadDailyData(obsTasminDir, 'yearStart', obsStart(a), 'yearEnd', obsEnd(a), 'obs', 'daily', 'obsAirport', obsAirports{a});
    curObsMin = curObsMin(:, months, :);
    curObsMin = reshape(curObsMin, [size(curObsMin, 1), size(curObsMin, 2)*size(curObsMin, 3)]);
    
    % now interpolate between max and min to generate hourly temps
    obsData{a} = [];
    for y = 1:size(curObsMax, 1)
        for d = 1:size(curObsMax, 2)
            obsData{a}(y, d, :) = [linspace(curObsMin(y,d), curObsMax(y,d), 12) linspace(curObsMax(y,d), curObsMin(y,d), 12)];
        end
    end
end

weightRestriction = {};
acSurfaces = av2_loadSurfaces();

figure('Color', [1,1,1]);
hold on;

colors = ['r', 'b', 'g', 'k'];
hours = 10:15;

for a = 1:length(obsAirports)
    weightRestriction{a} = [];
    for h = hours
        count = 1;
        for y = 1:size(obsData{a}, 1)
            for d = 1:size(obsData{a}, 2)
                weightRestriction{a}(h-hours(1)+1, count) = av2_calcWeightRestriction(obsData{a}(y,d,h), airportRunway{a}, airportElevation{a}, '737-800', acSurfaces);
                count = count+1;
            end
        end
    end
    
    s = smooth(weightRestriction{a}(12-hours(1), :), 15);
    plot(s, colors(a), 'LineWidth', 2);
    
end

save('weight-restriction.mat', 'weightRestriction');





