function [ind, perc] = mo_findHeatWaves(tempVar)

    % percentiles to test death anomalies
    prcTest = 0:5:100;
    
    perc = prcTest(2:end);

    % death anomalies for each percentile
    prcAnom = [];

    % heat wave length
    heatLength = 1:5;

    % starting dates of heat waves for each n
    ind = {};

    for n = heatLength
        ind{n} = {};
        for p = 1:length(prcTest)-1

            % define heat wave as 3 consec days above 90th percentile of tMax
            tempThreshLow = prctile(tempVar, prcTest(p));
            tempThreshHigh = prctile(tempVar, prcTest(p+1));

            % find starting dates of heat waves
            ind{n}{p} = [];
            i = 1;
            while i <= length(tempVar)-(n-1)
                % search for a heat wave
                wave = true;

                for j = 1:n

                    % if < 50th percentile end the cold snap when temps rise
                    % above the upper end of the percentile bin (so allow
                    % colder temps)
                    if prcTest(p) < 50
                        if tempVar(i+j-1) > tempThreshHigh %|| tempVar(i+j-1) >= tempThreshHigh
                            wave = false;
                            break;
                        end
                    % above the 50th percentile do the opposite, so allow for
                    % hotter temperatures
                    elseif prcTest(p) > 50
                        if tempVar(i+j-1) < tempThreshLow %|| tempVar(i+j-1) >= tempThreshHigh
                            wave = false;
                            break;
                        end
                    elseif prcTest(p) == 50
                        wave = false;
                        break;
                    end
                end

                if wave
                    ind{n}{p}(end+1) = i;
                    
                    % skip to next non heat wave / cold snap day
                    if prcTest(p) < 50
                        while tempVar(i) <= tempThreshHigh && i < length(tempVar)
                            i = i + 1;
                        end
                    elseif prcTest(p) > 50
                        while tempVar(i) >= tempThreshLow && i < length(tempVar)
                            i = i + 1;
                        end
                    end
                end

                i = i + 1;
            end
        end
    end
end