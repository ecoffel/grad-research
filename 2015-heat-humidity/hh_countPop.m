% counts the population within a given region and under certain gridboxes

function [popCount] = countPop(selectionGrid, region, popYears, sspNum, regridded)

    popCount = [];

    bbList = {};
    if strcmp(region, 'usne')
        states = {'Massachusettes', 'Connecticut', 'New Jersey', ...
                 'Pennsylvania', 'Maryland', 'Delaware', 'Vermont', ...
                 'New Hampshire', 'New York', 'District of Columbia', ...
                 'Virginia'};
        
        stateShape = shaperead('usastatelo', 'UseGeoCoords', true, 'Selector', ...
                               {@(name) ~any(strcmp(name,{'Alaska','Hawaii'})), 'Name'});
        curState = [];
        for s = 1:length(stateShape)
            curState = stateShape(s);
            %['processing ' curState.Name]
            if length(find(ismember(states, curState.Name))) > 0    
                latBounds = curState.Lat;
                lonBounds = curState.Lon + 360;
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

%                 if minLon < 0
%                     minLon = minLon + 360;
%                 end
%                 if maxLon < 0
%                     maxLon = maxLon + 360;
%                 end
                    
                xlativ = find(squeeze(sspLat(:,1)) >= minLat & squeeze(sspLat(:,1)) <= maxLat);
                yloniv = find(squeeze(sspLon(1,:)) >= minLon & squeeze(sspLon(1,:)) <= maxLon);

                for xlat = 1:length(xlativ)
                    for ylon = 1:length(yloniv)
                        if inpolygon(sspLat(xlativ(xlat), yloniv(ylon)), sspLon(xlativ(xlat), yloniv(ylon)), latBounds, lonBounds)
                            popCount(end) = popCount(end) + sspData(xlativ(xlat), yloniv(ylon));
                        end
                    end
                end
            end
        end
    end
end