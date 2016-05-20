function [ret] = mo_removeSeasonal(data)

    % all days of year
    for i = 1:364
        
        % find all instances of this day in the dataset
        days = [];
        for j = i:365:length(data)
            days = [days data(j)];
        end
        
        meanDays = nanmean(days);
        
        for j = i:365:length(data)
            data(j) = data(j) - meanDays;
        end
    end
    
    ret = data;

end