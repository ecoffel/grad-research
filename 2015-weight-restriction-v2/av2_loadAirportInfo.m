function [airports, airportRunway, airportElevation] = av2_loadAirportInfo()

    fin = fopen('airport-data.csv', 'r');

    data = textscan(fin, '%*[^\n]', 1);
    data = textscan(fin, '%s %d %d%*[^\n]', 'Delimiter', ',');

    fclose(fin);
    
    airports = data{1};
    airportRunway = data{2};
    airportElevation = data{3};

end