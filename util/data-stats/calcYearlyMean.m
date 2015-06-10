function [means] = calcYearlyMean(data)    
    for y=1:length(data)
        agg(:,:,y) = data{y}{3};
    end
    
    means = {data{y}{1}, data{y}{2}, squeeze(nanmean(agg(:,:,:),3))}; 
    
end