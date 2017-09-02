load('toe-multi-run-mean--10-model-range');

fout = fopen('bt-output.txt', 'w');

lat = saveData.data{1};
lon = saveData.data{2};
data = saveData.data{3};

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

% output data grids, each grid separated by a new line
for m = 1:size(data, 3)
    for x = 1:size(data, 1)
        for y = 1:size(data, 2)
            if y == size(data, 2)
                % no comma
                fprintf(fout, '%.2f', data(x,y,m));
            else
                % comma
                fprintf(fout, '%.2f,', data(x,y,m));
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