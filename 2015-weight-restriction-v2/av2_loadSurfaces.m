function [acSurfaces] = loadAvSurfaces()
    data = csvread('performance-data.csv', 1, 0);
    data = data(:, 1:4);

    % elevation 0
    ind0 = find(data(:, 3) == 0);

    % elevation 2000
    ind2 = find(data(:, 3) == 2000);

    % elevation 4000
    ind4 = find(data(:, 3) == 4000);

    % make the surfaces
    f0 = fit([data(ind0, 1), data(ind0, 2)], data(ind0, 4), 'poly32');
    f2 = fit([data(ind2, 1), data(ind2, 2)], data(ind2, 4), 'poly32');
    f4 = fit([data(ind4, 1), data(ind4, 2)], data(ind4, 4), 'poly32');
    
    acSurfaces = {f0, f2, f4};
    
    % surfaces take in (temp, weight in thousands of pounds)
end

