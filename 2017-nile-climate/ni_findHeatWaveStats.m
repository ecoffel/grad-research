function [heatWaveDurMean, heatWaveDurMax, heatWaveIntMean, heatWaveIntMax] = findHeatWaveStats(dataBase, dataFuture, percentile)

    minDur = 3;

    heatWaveDurMean = []; 
    heatWaveDurMax = []; 
    heatWaveIntMean = []; 
    heatWaveIntMax = []; 
    
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
                
                indDur(indDur < minDur) = [];

                % average number of events per year
                if length(indDur) > 0
                    heatWaveDurMean(xlat, ylon, year) = nanmean(indDur);
                    heatWaveDurMax(xlat, ylon, year) = nanmax(indDur);
                    heatWaveIntMean(xlat, ylon, year) = nanmean(d(indTemp));
                    heatWaveIntMax(xlat, ylon, year) = nanmax(d(indTemp));
                else
                    heatWaveDurMean(xlat, ylon, year) = NaN;
                    heatWaveDurMax(xlat, ylon, year) = NaN;
                    heatWaveIntMean(xlat, ylon, year) = NaN;
                    heatWaveIntMax(xlat, ylon, year) = NaN;
                end
                
            end 
        end
    end
end