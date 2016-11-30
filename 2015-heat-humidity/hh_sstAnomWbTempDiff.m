region = 'china';
dataset = 'cmip5';
tempVar = 'tasmax';
sstVar = 'tos';
timeperiod = 'future';

load lat;
load lon;

load([sstVar 'TempExtremes-' tempVar '-' region '-day-mean-' timeperiod '-top-max-' dataset '-100']);
tempSave=saveData;
load([sstVar 'TempExtremes-wb-' region '-day-mean-' timeperiod '-top-max-' dataset '-100']);
wbSave=saveData;

diff = wbSave.data{3} - tempSave.data{3};

result = {lat, lon, diff};
saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [-0.5 0.5], ...
                  'plotTitle', ['WB SST anom minus tasmax SST anom (' region ')'], ...
                  'fileTitle', ['sstAnomWbTempDiff-' region '-' dataset '-' timeperiod '.pdf'], ...
                  'plotXUnits', 'Degrees C', ...
                  'blockWater', false, ...
                  'blockLand', true);
plotFromDataFile(saveData);