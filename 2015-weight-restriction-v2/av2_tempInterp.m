airports = {'LGA'};

obsDir = 'e:\data\flight\wx\output\daily';
obsPeriod = 2010;

for a = 1:length(airports)

    for y = obsPeriod
        tempsMin = loadDailyData([obsDir '\tasmin'], 'yearStart', y, 'yearEnd', y, 'obs', 'daily', 'obsAirport', airports{a});
        tempsMax = loadDailyData([obsDir '\tasmax'], 'yearStart', y, 'yearEnd', y, 'obs', 'daily', 'obsAirport', airports{a});
    end
end

