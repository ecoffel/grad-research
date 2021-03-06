load toe-multi-run-mean--10-model-range;
data10 = saveData.data;

load toe-multi-run-mean--9-model-range;
data9 = saveData.data;

load toe-multi-run-mean--11-model-range;
data11 = saveData.data;

load toe-multi-run-mean--16-model-range;
data16 = saveData.data;

result9 = {data10{1}, data10{2}, data9{3}-data10{3}};
result11 = {data10{1}, data10{2}, data11{3}-data10{3}};
result16 = {data10{1}, data10{2}, data16{3}-data10{3}};

%result9{3}(result9{3} == 0) = NaN;
%result11{3}(result11{3} == 0) = NaN;
%result16{3}(result16{3} == 0) = NaN;

% compute stippling - cells where the abs(YOE) is <= stippleThresh across all three
% panels (-9, -11, -16)
stippleThresh = 5;
stipple = [];
for xlat = 1:size(result9{3}, 1)
    for ylon = 1:size(result9{3}, 2)
        if ~isnan(result9{3}(xlat, ylon)) && ~isnan(result11{3}(xlat, ylon)) && ~isnan(result16{3}(xlat, ylon)) && ...
           abs(result9{3}(xlat, ylon)) <= stippleThresh && abs(result11{3}(xlat, ylon)) <= stippleThresh && abs(result16{3}(xlat, ylon)) <= stippleThresh
            stipple(xlat, ylon) = 1;
        else
            stipple(xlat, ylon) = 0;
        end
    end
end

saveData9 = saveData;
saveData9.data = result9;
saveData9.plotRange = [-20 20];
saveData9.colormap = 'jet';
saveData9.fileTitle = 'toe-multi-run-mean--9-diff-model-range.png';
saveData9.plotTitle = 'Time of emergence, multi-run mean, 9 diff';
saveData9.magnify = '2';
saveData9.statData = stipple;
saveData9.stippleInterval = 0.5;
saveData9.blockWater = true;

saveData11 = saveData;
saveData11.data = result11;
saveData11.plotRange = [-20 20];
saveData11.colormap = 'jet';
saveData11.fileTitle = 'toe-multi-run-mean--11-diff-model-range.png';
saveData11.plotTitle = 'Time of emergence, multi-run mean, 11 diff';
saveData11.magnify = '2';
saveData11.statData = stipple;
saveData11.stippleInterval = 0.5;
saveData11.blockWater = true;

saveData16 = saveData;
saveData16.data = result16;
saveData16.plotRange = [-20 20];
saveData16.colormap = 'jet';
saveData16.fileTitle = 'toe-multi-run-mean--16-diff-model-range.png';
saveData16.plotTitle = 'Time of emergence, multi-run mean, 16 diff';
saveData16.magnify = '2';
saveData16.statData = stipple;
saveData16.stippleInterval = 0.5;
saveData16.blockWater = true;

plotFromDataFile(saveData9);
plotFromDataFile(saveData11);
plotFromDataFile(saveData16);

