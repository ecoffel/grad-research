figure('Color',[1,1,1]);
hold on;

usLat = [20 50 50 20];
usLon = [-90 -90 -62 -62] + 360;

chinaLat = [20 50 50 20];
chinaLon = [100 100 135 135];

wAfLat = [0 30 30 0];
wAfLon = [340 340 40 40];

indiaLat = [8 34 34 8];
indiaLon = [67 67 90 90];

landmass = shaperead('landareas.shp', 'UseGeoCoords', true);
countries = shaperead('countries', 'UseGeoCoords', true);
geoshow(landmass, 'FaceColor', [253/255.0, 192/255.0, 134/255.0]);

geoshow(indiaLat, indiaLon, 'DisplayType', 'polygon', 'FaceColor', [0, 0, 0], 'EdgeColor', 'None');
regionCountries = {'India'};
for c = 1:length(countries)
    curCountry = countries(c);
    if length(find(ismember(regionCountries, curCountry.NAME))) == 0
        geoshow(curCountry.Lat, curCountry.Lon, 'DisplayType', 'polygon', 'FaceColor', [253/255.0, 192/255.0, 134/255.0], 'EdgeColor', 'None');
    end
end
geoshow(usLat, usLon, 'DisplayType', 'polygon', 'FaceColor', [0, 0, 0], 'EdgeColor', 'None');
geoshow(wAfLat, wAfLon, 'DisplayType', 'polygon', 'FaceColor', [0, 0, 0], 'EdgeColor', 'None');
geoshow(chinaLat, chinaLon, 'DisplayType', 'polygon', 'FaceColor', [0, 0, 0], 'EdgeColor', 'None');

regionCountries = {'United States', 'China', 'India', 'Benin', 'Burkina Faso', 'Cape Verde', 'Gambia', ...
                            'Ghana', 'Guinea', 'Guinea-Bissau', 'Cote d''Ivoire', ...
                            'Liberia', 'Mali', 'Niger', 'Nigeria', 'Senegal', ...
                            'Sierra Leone', 'Togo'};
for c = 1:length(countries)
    curCountry = countries(c);
    if length(find(ismember(regionCountries, curCountry.NAME))) == 0
        geoshow(curCountry.Lat, curCountry.Lon, 'DisplayType', 'polygon', 'FaceColor', [253/255.0, 192/255.0, 134/255.0], 'EdgeColor', 'None');
    end
end

load coast;
geoshow(flipud(lat),flipud(long), 'DisplayType', 'polygon', 'FaceColor', [166/255.0, 205/255.0, 227/255.0]);

axis off;
set(gcf, 'Position', get(0,'Screensize'));
export_fig hh_regions.pdf;