% counts the population within a given region and under certain gridboxes

function [popCount] = countPop(selectionGrid, region, popYears, sspNum, regridded)

    popCount = [];

    bbList = {};
    
    load waterGrid;
    
    if strcmp(region, 'usne')
        countries = shaperead('countries', 'UseGeoCoords', true);
        
        curCountry = [];
        for c = 1:length(countries)
            curCountry = countries(c);  
            if strcmp(curCountry.NAME, 'United States')
                latBounds = curCountry.Lat;
                lonBounds = curCountry.Lon + 360;
                bbList{end+1} = [latBounds; lonBounds];
            end
        end
    elseif strcmp(region, 'china')
        countries = shaperead('countries', 'UseGeoCoords', true);
        
        curCountry = [];
        for c = 1:length(countries)
            curCountry = countries(c);  
            if strcmp(curCountry.NAME, 'China')
                latBounds = curCountry.Lat;
                lonBounds = curCountry.Lon;
                bbList{end+1} = [latBounds; lonBounds];
            end
        end
    elseif strcmp(region, 'india')
        countries = shaperead('countries', 'UseGeoCoords', true);
        
        curCountry = [];
        for c = 1:length(countries)
            curCountry = countries(c);  
            if strcmp(curCountry.NAME, 'India')
                latBounds = curCountry.Lat;
                lonBounds = curCountry.Lon;
                bbList{end+1} = [latBounds; lonBounds];
            end
        end
    elseif strcmp(region, 'west_africa')
        countries = shaperead('countries', 'UseGeoCoords', true);
        regionCountries = {'Benin', 'Burkina Faso', 'Cape Verde', 'Gambia', ...
                            'Ghana', 'Guinea', 'Guinea-Bissau', 'Cote d''Ivoire', ...
                            'Liberia', 'Mali', 'Niger', 'Nigeria', 'Senegal', ...
                            'Sierra Leone', 'Togo'};
        
        
        curCountry = [];
        for c = 1:length(countries)
            curCountry = countries(c);  
            if length(find(ismember(regionCountries, curCountry.NAME)))
                latBounds = curCountry.Lat;
                lonBounds = curCountry.Lon;
                bbList{end+1} = [latBounds; lonBounds];
            end
        end
    elseif strcmp(region, 'world')
        bbList{end+1} = [[-90 90 90 -90]; [0 0 360 360]];
    end
    
    selectionLat = selectionGrid{1};
    selectionLon = selectionGrid{2};
    selectionData = selectionGrid{3};
    
    for y = 1:length(popYears)

        if regridded
            load(['C:\git-ecoffel\grad-research\ssp\ssp5\output\ssp5\regrid\ssp5_' num2str(popYears(y)) '.mat']);
        else
            load(['C:\git-ecoffel\grad-research\ssp\ssp5\output\ssp5\ssp5_' num2str(popYears(y)) '.mat']);
        end
        
        eval(['ssp = ssp' num2str(sspNum) '_' num2str(popYears(y)) ';']);
        eval(['clear ssp' num2str(sspNum) '_' num2str(popYears(y)) ';']);

        popCount(end+1) = 0;

        sspLat = ssp{1};
        sspLon = ssp{2};
        sspData = ssp{3};
        
        for b = 1:length(bbList)
            latBounds = bbList{b}(1, :);
            lonBounds = bbList{b}(2, :);
            
            % search through selection grid for selected values
            [iv, jv] = ind2sub(size(selectionGrid{3}), find(selectionGrid{3}));

            for k = 1:length(iv)
                i = iv(k);
                j = jv(k);

                minLat = selectionLat(i, j);
                maxLat = minLat + 2;

                minLon = selectionLon(i, j);
                maxLon = minLon + 2;
    
                xlativ = find(squeeze(sspLat(:,1)) >= minLat & squeeze(sspLat(:,1)) <= maxLat);
                yloniv = find(squeeze(sspLon(1,:)) >= minLon & squeeze(sspLon(1,:)) <= maxLon);

                for xlat = 1:length(xlativ)
                    for ylon = 1:length(yloniv)
                        if waterGrid(xlativ(xlat), yloniv(ylon))
                            continue;
                        end
                        if inpolygon(sspLat(xlativ(xlat), yloniv(ylon)), sspLon(xlativ(xlat), yloniv(ylon)), latBounds, lonBounds)
                            popCount(end) = popCount(end) + selectionGrid{3}(i, j)*sspData(xlativ(xlat), yloniv(ylon));
                        end
                    end
                end
            end
        end
    end
end