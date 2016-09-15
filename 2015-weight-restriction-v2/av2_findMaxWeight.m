function [maxWeight] = findMaxWeight(temp, runway, elevation)
    
    [f0, f2, f4] = av2_loadSurfaces();
    
    % minimum weight to start search (for 737-800)
    startingWeight = 140;
    maxTakeoffWeight = 174;
    
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