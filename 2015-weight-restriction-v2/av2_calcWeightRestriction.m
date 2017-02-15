function [payloadRestriction, totalRestriction] = calcWeightRestriction(temp, runway, elevation, aircraft, acSurfaces)

    ind = -1;
    for a = 1:length(acSurfaces)
        if strcmp(acSurfaces{a}{1}{1}, aircraft)
            ind = a;
            break;
        end
    end
    
    maxWeight = av2_findMaxWeight(temp, runway, elevation, acSurfaces{ind});
    payloadRestriction = 0.83 * (acSurfaces{ind}{1}{3} - maxWeight);
    totalRestriction = acSurfaces{ind}{1}{3} - maxWeight;

end