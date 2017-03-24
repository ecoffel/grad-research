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

saveData9 = saveData;
saveData9.data = result9;
saveData9.plotRange = [-20 20];
saveData9.colormap = 'jet';
saveData9.fileTitle = 'toe-multi-run-mean--9-diff-model-range.png';
saveData9.plotTitle = 'Time of emergence, multi-run mean, 9 diff';
saveData9.magnify = '2';

saveData11 = saveData;
saveData11.data = result11;
saveData11.plotRange = [-20 20];
saveData11.colormap = 'jet';
saveData11.fileTitle = 'toe-multi-run-mean--11-diff-model-range.png';
saveData11.plotTitle = 'Time of emergence, multi-run mean, 11 diff';
saveData11.magnify = '2';

saveData16 = saveData;
saveData16.data = result16;
saveData16.plotRange = [-20 20];
saveData16.colormap = 'jet';
saveData16.fileTitle = 'toe-multi-run-mean--16-diff-model-range.png';
saveData16.plotTitle = 'Time of emergence, multi-run mean, 16 diff';
saveData16.magnify = '2';


plotFromDataFile(saveData9);
plotFromDataFile(saveData11);
plotFromDataFile(saveData16);

