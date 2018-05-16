load 2017-bowen/hottest-season-txx-rel-cmip5-all-txx;
load lat
load lon

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

txxMonthLengthHist = [];
txxMonthLengthFut = [];
for m = 1:length(models)          
    load(['2017-bowen/txx-timing/txx-months-' models{m} '-historical-cmip5-1981-2005.mat']);
    txxMonthsHist = txxMonths;
    
    load(['2017-bowen/txx-timing/txx-months-' models{m} '-future-cmip5-2061-2085.mat']);
    txxMonthsFut = txxMonths;

    for xlat = 1:size(lat,1)
        for ylon = 1:size(lat,2)
            txxMonthLengthHist(xlat,ylon,m) = length(unique(squeeze(txxMonthsHist(xlat,ylon,:))));
            txxMonthLengthFut(xlat,ylon,m) = length(unique(squeeze(txxMonthsFut(xlat,ylon,:))));
        end
    end
end
result = {lat, lon, mode(hottestSeason, 3)};

saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [1 12], ...
                  'cbXTicks', 1:12, ...
                  'plotTitle', ['TXx month'], ...
                  'fileTitle', ['hottest-season-cmip5.eps'], ...
                  'plotXUnits', ['Month'], ...
                  'blockWater', false, ...
                  'colormap', brewermap(11,'*Spectral'));
plotFromDataFile(saveData);
          
% for m = 1:length(models)
% 
% result = {lat, lon, hottestSeason(:,:,m)};
% 
% saveData = struct('data', {result}, ...
%                   'plotRegion', 'world', ...
%                   'plotRange', [1 12], ...
%                   'cbXTicks', 1:12, ...
%                   'plotTitle', [models{m} ' TXx month'], ...
%                   'fileTitle', ['hottest-season-' models{m} '.png'], ...
%                   'plotXUnits', ['Month'], ...
%                   'blockWater', false, ...
%                   'colormap', brewermap(11,'*Spectral'));
% plotFromDataFile(saveData);
% end
%     