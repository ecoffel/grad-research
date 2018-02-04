function heatWaves = findHeatWaves(dataBase, data, percentile, duration, monthly)
    heatWaves = []; 
    
    % for all months, calculate the chance of there being a heatwave matching
    % defined characteristics...
    
    % loop over all gridcells
    for xlat = 1:size(dataBase, 1)
        for ylon = 1:size(dataBase, 2)
            
            % calculate threshold relative to whole gridcell climatology
            if ~monthly
                threshTemp = prctile(reshape(dataBase(xlat,ylon,:,:,:), [numel(dataBase(xlat,ylon,:,:,:)),1]), percentile);
            end
            
            for month = 1:12
                % threshold relative to climatology for this month
                if monthly
                    threshTemp = prctile(reshape(dataBase(xlat,ylon,:,month,:), [numel(dataBase(xlat,ylon,:,month,:)),1]), percentile);
                end

                for year = 1:size(dataBase, 3)
                    % convert to 1D for current gridcell
                    % if there is no future data provided, look at
                    % historical data
                    if length(data) == 0
                        d = reshape(permute(squeeze(dataBase(xlat, ylon, year, month, :)), [3,2,1]), [numel(dataBase(xlat, ylon, year, month, :)), 1]);
                    else
                        d = reshape(permute(squeeze(data(xlat, ylon, year, month, :)), [3,2,1]), [numel(data(xlat, ylon, year, month, :)), 1]);
                    end

                    % find all days above threshold temperature
                    indTemp = find(d > threshTemp);

                    % for how ever many days long wave we're looking for, take
                    % difference of temp threshold indices - so if 1, that means
                    % consequitive hot days
                    % look for sub-arrays that contain X number of sequential ones
                    x = (diff(indTemp))'==1;
                    f = find([false, x] ~= [x, false]);
                    indDur = length(find(f(2:2:end)-f(1:2:end-1) >= duration));

                    % average number of events per year
                    heatWaves(xlat, ylon, year, month) = indDur;
                end 
            end
        end
    end
end