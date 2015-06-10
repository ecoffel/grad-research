function [track, track_ind] = calcFlightTrack(code1, code2, airportDb, lat, lon)

if length(airportDb) == 0
    airportDb = loadAirportDb('airports.dat');
end

if length(lat) == 0 | length(lon) == 0
    [diff_2070, diff_2090] = calcWindDiff();
    lat = diff_2070{1}{1};
    lon = diff_2070{1}{2};
end

[airport1_code, airport1_lat, airport1_lon] = searchAirportDB(airportDb, code1);
[airport2_code, airport2_lat, airport2_lon] = searchAirportDB(airportDb, code2);

loc1 = [airport1_lat, airport1_lon];
loc2 = [airport2_lat, airport2_lon];

[track_lat, track_lon] = gcwaypts(loc1(1), loc1(2), loc2(1), loc2(2), 10);
track = {track_lat, track_lon};

lat_indices = [];
lon_indices = [];
for i=1:length(track_lat)
    
    %lat
    [~,I] = min(abs(lat(:,1)-track_lat(i)));
    lat_indices(i) = I;

    %lon
    [~,I] = min(abs(lon(:,1)-track_lon(i)));
    lon_indices(i) = I;
end

track_ind = {lat_indices, lon_indices};

end