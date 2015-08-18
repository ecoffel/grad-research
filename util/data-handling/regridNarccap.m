baseGridModel = 'e:/data/narccap/output/crcm/cgcm3';
baseGridVar = 'tasmax';

models = {'crcm/ccsm', 'crcm/cgcm3', ...
          'ecp2/gfdl', 'hrm3/gfdl', ...
          'hrm3/hadcm3', 'mm5i/ccsm', ...
          'mm5i/hadcm3', 'rcm3/cgcm3', ...
          'rcm3/gfdl', 'wrfg/ccsm', ...
          'wrfg/cgcm3'};
% models = {'crcm/ncep', 'ecp2/ncep', ...
%           'hrm3/ncep', 'mm5i/ncep', ...
%           'rcm3/ncep', 'wrfg/ncep'};
      
%vars = {'tasmax', 'tasmin', 'mrso', 'swe', 'va850', 'ua850', 'hus850'};
vars = {'psl'};

baseGridMonthly = loadMonthlyData([baseGridModel '/' baseGridVar '/regrid'], baseGridVar, 'yearStart', 1981, 'yearEnd', 1981);
baseGrid = {baseGridMonthly{1}{1}{1}, baseGridMonthly{1}{1}{2}, []};
clear baseGridMonthly;

for m = 1:length(models)
    for v = 1:length(vars)
        regridOutput(['e:/data/narccap/output/' models{m} '/' vars{v}], vars{v}, baseGrid, 'skipexisting', true);
    end
end