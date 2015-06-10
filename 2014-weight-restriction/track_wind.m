if ~exist('diff_2070')
    [diff_2070, diff_2090] = calcWindDiff();
end

if ~exist('airportDb')
    airportDb = loadAirportDb('airports.dat');
end

if ~exist('routeDb')
    routeDb = loadRouteDb('routes.dat');
end

tracks = [];
ua_winds = [];
rand_indices = randi(length(routeDb),500,1);
record_count = 1;
fail_count = 0;

for index=1:length(rand_indices)%size(routeDb,1)
    cur_index = rand_indices(index);
    
    if mod(index,100)==0
        index
    end
    [airport1_code, airport1_lat, airport1_lon] = searchAirportDb(airportDb, routeDb{cur_index}{1});
    [airport2_code, airport2_lat, airport2_lon] = searchAirportDb(airportDb, routeDb{cur_index}{2});
    
    if strcmp(airport1_code, '') | strcmp(airport2_code, '') | ...
            airport1_lat == -Inf | airport1_lon == -Inf | ...
            airport2_lat == -Inf | airport2_lon == -Inf
        fail_count = fail_count + 1;
        continue;
    end
    
    loc1 = [airport1_lat, airport1_lon];
    loc2 = [airport2_lat, airport2_lon];
    
    [track_lat, track_lon] = gcwaypts(loc1(1), loc1(2), loc2(1), loc2(2), 10);

    lat = diff_2070{1}{1};
    lon = diff_2070{1}{2};
    
    % find closest points
    for m=1:12
        monthly_winds = diff_2090{m}{3};

        lat_indices = [];
        lon_indices = [];

        for i=1:length(track_lat)
            if size(tracks, 3) < length(track_lat)
                tracks(index, 1, i) = track_lat(i);
                tracks(index, 2, i) = track_lon(i);
            end
            
            %lat
            [~,I] = min(abs(lat(:,1)-track_lat(i)));
            lat_indices(i) = I;

            %lon
            [~,I] = min(abs(lon(:,1)-track_lon(i)));
            lon_indices(i) = I;

            ua_winds(record_count, m, i) = monthly_winds(lat_indices(end),lon_indices(end));
        end
        record_count = record_count+1;
    end
end

% monthly track winds

ua_winds = mean(ua_winds,3)';

% track mean winds (yearly)
ua_winds = mean(ua_winds, 2)

mean(ua_winds)
