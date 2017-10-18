figure('Color',[1,1,1]);

set(gcf,'renderer','opengl');

hold on;
axis off;
box off;

regionNames = {'Eastern U.S.', ...
                'Central Europe', ...
                'Mediterranean', ...
                'Northern SA', ...
                'Amazon', ...
                'Central Africa'};
regionAb = {'us-east', ...
            'europe', ...
            'med', ...
            'sa-n', ...
            'amazon', ...
            'africa-cent'};

regions = [[[30 42 42 30], [-91 -91 -75 -75] + 360]; ...     % eastern us
           [[45 55 55 45], [10 10 35 35]]; ...            % Europe
           [[36 45 45 36], [-5+360 -5+360 40 40]]; ...        % Med
           [[5 20 20 5], [-90 -90 -45 -45]+360]; ...         % Northern SA
           [[-10 1 1 -10], [-75 -75 -53 -53]+360]; ...      % Amazon
           [[-10 10 10 -10], [15 15 30 30]]];                % central africa

regionInds = [1 2 5];
       
landmass = shaperead('landareas.shp', 'UseGeoCoords', true);
countries = shaperead('countries', 'UseGeoCoords', true);
geoshow(landmass, 'FaceColor', 'w', 'EdgeColor', 'k');


load coast;
geoshow(flipud(lat),flipud(long), 'DisplayType', 'polygon', 'FaceColor', [166/255.0, 205/255.0, 227/255.0]);

for regionInd = regionInds
    geoshow(regions(regionInd, 1:4), regions(regionInd, 5:8), 'DisplayType', 'polygon', 'FaceColor', [0.7, 0.7, 0.7], 'FaceAlpha', 0.5, 'EdgeColor', 'k', 'LineWidth', 2);
end


set(gcf, 'Position', get(0,'Screensize'));