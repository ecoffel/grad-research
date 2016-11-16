function [payloadRestriction] = calcWeightRestriction(temp, runway, elevation, aircraft, acSurfaces)

    maxWeight = av2_findMaxWeight(temp, runway, elevation, acSurfaces);
    payloadRestriction = 0.83 * (174-maxWeight);

end