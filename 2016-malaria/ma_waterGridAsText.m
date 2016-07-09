load waterGrid-suitable

fout = fopen('waterGrid.txt', 'w');

lat = waterGrid{1};
lon = waterGrid{2};
data = waterGrid{3};

% output lat grid
for x = 1:size(lat, 1)
    for y = 1:size(lat, 2)
        if y == size(lat, 2)
            % no comma
            fprintf(fout, '%.2f', lat(x,y));
        else
            % comma
            fprintf(fout, '%.2f,', lat(x,y));
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
            fprintf(fout, '%.2f', lon(x,y));
        else
            % comma
            fprintf(fout, '%.2f,', lon(x,y));
        end
    end
    fprintf(fout, '\r\n');
end

fprintf(fout, '\r\n');

% output water grid
for x = 1:size(data, 1)
    for y = 1:size(data, 2)
        if y == size(data, 2)
            % no comma
            fprintf(fout, '%d', round(data(x,y)));
        else
            % comma
            fprintf(fout, '%d,', round(data(x,y)));
        end
    end
    % new line after each row
    fprintf(fout, '\r\n');
end

fclose(fout);