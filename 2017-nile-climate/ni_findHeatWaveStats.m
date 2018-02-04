function [heatWaveDurMean, heatWaveDurMax, heatWaveInt] = findHeatWaveStats(dataBase, dataFuture, percentile)
    heatWaveDurMean = []; 
    heatWaveDurMax = []; 
    heatWaveInt = []; 
    
    % for all months, calculate the chance of there being a heatwave matching
    % defined characteristics...
    
    % loop over all gridcells
    for xlat = 1:size(dataBase, 1)
        for ylon = 1:size(dataBase, 2)
            
            % calculate threshold relative to whole gridcell climatology
            threshTemp = prctile(reshape(dataBase(xlat,ylon,:,:,:), [numel(dataBase(xlat,ylon,:,:,:)),1]), percentile);
           
            for year = 1:size(dataFuture, 3)
                % convert to 1D for current gridcell
                % if there is no future data provided, look at
                % historical data
                d = reshape(permute(squeeze(dataFuture(xlat, ylon, year, :, :)), [2,1]), [numel(dataBase(xlat, ylon, year, :, :)), 1]);

                % find all days above threshold temperature
                indTemp = find(d > threshTemp);

                % for how ever many days long wave we're looking for, take
                % difference of temp threshold indices - so if 1, that means
                % consequitive hot days
                % look for sub-arrays that contain X number of sequential ones
                x = (diff(indTemp))'==1;
                f = find([false, x] ~= [x, false]);
                indDur = f(2:2:end)-f(1:2:end-1);

                % average number of events per year
                if length(indDur) > 0
                    heatWaveDurMean(xlat, ylon, year) = nanmean(indDur);
                    heatWaveDurMax(xlat, ylon, year) = max(indDur);
                else
                    heatWaveDurMean(xlat, ylon, year) = NaN;
                    heatWaveDurMax(xlat, ylon, year) = NaN;
                end
                heatWaveInt(xlat, ylon, year) = nanmean(d(indTemp));
            end 
        end
    end
end