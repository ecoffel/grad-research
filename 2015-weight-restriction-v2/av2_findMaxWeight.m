function [maxWeight] = findMaxWeight(temp, runway, elevation, acSurfaces)
    
    if isnan(temp)
        maxWeight = NaN;
        return;
    end

    % acSurfaces{1} is the aircraft name
    f0 = acSurfaces{2};
    f2 = acSurfaces{3};
    f4 = acSurfaces{4};
    
    % minimum weight to start search 
    startingWeight = acSurfaces{1}{2};
    maxTakeoffWeight = acSurfaces{1}{3};
    
    % select correct surface for elevation
    surf = [];
    
    if elevation <= 1000
        surf = f0;
    elseif elevation > 1000 && elevation <= 3000
        surf = f2;
    elseif elevation > 3000
        surf = f4;
    end
    
    % search for highest allowable weight
    maxWeight = startingWeight;
    recRunway = surf(temp, maxWeight);
    while recRunway < runway && maxWeight <= maxTakeoffWeight
        maxWeight = maxWeight + 1;
        recRunway = surf(temp, maxWeight);
    end
    
    % take the last allowable weight
    maxWeight = maxWeight - 1;
    
end