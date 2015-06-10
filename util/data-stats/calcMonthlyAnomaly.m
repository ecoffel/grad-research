% Calculates the mean monthly anomaly for each gridbox between two monthly
% datasets (which must be the same length and cover the same years). The
% return variable anom has 12 columns which are the anomalies for each
% month. This script takes in baseDataGrid and newDataGrid. If the grids
% are not the same size, baseDataGrid is regridded to the grid of
% newDataGrid. Then the anom is calculated as newDataGrid - baseDataGrid.

function [anom] = calcMonthlyAnomaly(baseDataGrid, newDataGrid)

baseDataRegrid = {};

for m=1:length(baseDataGrid)
    if m > length(newDataGrid)
        break;
    end

    for y=1:length(baseDataGrid{m})
        if y > length(newDataGrid{m})
            break;
        end
        if size(baseDataGrid{m}{y}{3}) ~= size(newDataGrid{m}{y}{3})
            baseDataRegrid{m}{y} = regridGriddata(baseDataGrid{m}{y}, newDataGrid{m}{y});
        else
            baseDataRegrid{m}{y} = baseDataGrid{m}{y};
        end
    end
end

anom = {};

for m=1:length(baseDataRegrid)
    for y=1:length(baseDataRegrid{m})

        curObs = {{baseDataRegrid{m}{1:y-1} baseDataRegrid{m}{y+1:length(baseDataRegrid{m})}}};
        curObsMean = calcMonthlyMean(curObs);

        curModel = {{newDataGrid{m}{1:y-1} newDataGrid{m}{y+1:length(newDataGrid{m})}}};
        curModelMean = calcMonthlyMean(curModel);

        anom{m} = {baseDataRegrid{1}{1}{1}, baseDataRegrid{1}{1}{2}, curModelMean{1}{3}-curObsMean{1}{3}};
    end
end

end