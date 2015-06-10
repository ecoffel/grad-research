function [airportCode, airportLat, airportLon] = searchAirportDb(db, code)

index = find(cell2mat(cellfun(@(x) strcmp(x{1}, code), db, 'UniformOutput', false)));

airportCode = '';
airportLat = -Inf;
airportLon = -Inf;

if index >= 1 & index <= size(db,1)
    airportCode = code;
    airportLat = db{index}{2};
    airportLon = db{index}{3} + 360;
end
