load suitable;

fout = fopen('suitable.txt', 'w');

lat = suitable{1};
lon = suitable{2};
data = suitable{3};

% output lat grid
for x = 1:size(lat, 1)
    for y = 1:size(lat, 2)
        if y == size(lat, 2)
            % no comma
            fprintf(fout, '%d', lat(x,y));
        else
            % comma
            fprintf(fout, '%d,', lat(x,y));
        end
    end
    fprintf(fout, '\r\n');
end

fprintf(fout, '\r\n');

% output lat grid
for x = 1:size(lon, 1)
    for y = 1:size(lon, 2)
        if y == size(lon, 2)
            % no comma
            fprintf(fout, '%d', lon(x,y));
        else
            % comma
            fprintf(fout, '%d,', lon(x,y));
        end
    end
    fprintf(fout, '\r\n');
end

fprintf(fout, '\r\n');

% output data grids, each grid separated by a new line
for m = 1:size(data, 3)
    for x = 1:size(data, 1)
        for y = 1:size(data, 2)
            if y == size(data, 2)
                % no comma
                fprintf(fout, '%d', data(x,y,m));
            else
                % comma
                fprintf(fout, '%d,', data(x,y,m));
            end
        end
        % new line after each row
        fprintf(fout, '\r\n');
    end
    
    % line between grids
    if m < size(data, 3)
        fprintf(fout, '\r\n');
    end
end

fclose(fout);