ssp = 3;
x = [2020 2030 2040 2050 2060];
wb = [29 30 31 32 33];

traces = {};

for w = wb
    load(['heatExposure-cmip5-wb-' num2str(w) '-ssp' num2str(ssp) '-world.mat']);
    err = saveData.futureDecYerr(:, 4) ./ saveData.futureDecY(:, 4);
    
    trace = struct('x', { x }, ...
                  'y', err, ...
                  'name', [num2str(w) 'C error'], ...
                  'type', 'bar');
    traces = {traces{:} trace};
end

plotlyLayout = struct('barmode', 'group');
plotlyResponse = plotly(traces, struct('layout', plotlyLayout, 'filename', ['heatUncert-ssp' num2str(ssp)], 'fileopt', 'overwrite'));