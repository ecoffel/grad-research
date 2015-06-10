function [anom] = calcYearlyAnomaly(baseDataGrid, newDataGrid)    
    for y=1:length(baseDataGrid)
        if y > length(newDataGrid)
            break;
        end

        baseDataRegrid{y} = regrid(baseDataGrid{y}, newDataGrid{y});
    end

    anom = {};

    for y=1:length(baseDataRegrid)
        curObs = {baseDataRegrid{1:y-1} baseDataRegrid{y+1:length(baseDataRegrid)}};
        curObsMean = calcMonthlyMean(curObs);

        curModel = {newDataGrid{1:y-1} newDataGrid{y+1:length(newDataGrid)}};
        curModelMean = calcYearlyMean(curModel);

        anom{y} = {baseDataRegrid{1}{1}, baseDataRegrid{1}{2}, curModelMean{3}-curObsMean{3}};
    end
end