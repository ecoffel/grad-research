tempRange = 10:60;
runwayRange = 4000:500:16000
elevationRange = [0 2000 4000];

surfs = av2_loadSurfaces();

wrLookup = {};

% loop over aircraft
for s = 1:length(surfs)
    surf = surfs{s};
    
    curAc = surf{1}{1};
    minWeight = surf{1}{2};
    maxWeight = surf{1}{3};
    weightRange = minWeight:maxWeight;
    
    f0 = surf{2};
    f2 = surf{3};
    f4 = surf{4};
    
    % set up look up table for this aircraft - 
    % ac string, min - max weight, temp/weight lookup, WR lookup, TR lookup
    wrLookup{end+1} = {curAc, {elevationRange, tempRange, runwayRange, maxWeight}, [], []};
    
    % loop over elevation
    for e = 1:length(elevationRange)
        elevation = elevationRange(e)
        
        % skip this elevation if it doesn't exist
        if (elevation == 2000 && length(f2) == 0) || ...
           (elevation == 4000 && length(f4) == 0)
            continue;
        end
        
        % loop over temp
        for t = 1:length(tempRange)
            temp = tempRange(t)
            
            % loop over runways
            for r = 1:length(runwayRange)
                runway = runwayRange(r);

                % calculate WR for this combo
                [wrLookup{end}{3}(e, t, r), wrLookup{end}{4}(e, t, r)] = av2_calcWeightRestriction(temp, runway, elevation, curAc, surfs);

            end
        end
    end 
end

save('wrLookup', 'wrLookup');
