regridVar = 'pr';
gridSpacing = 2;

latGrid = meshgrid(linspace(-90, 90, 180/gridSpacing), linspace(0, 360, 360/gridSpacing))';
lonGrid = meshgrid(linspace(0, 360, 360/gridSpacing), linspace(-90, 90, 180/gridSpacing));
baseGrid = {latGrid, lonGrid, []};

modelBaseDir = 'cmip5/output';
% models = {'ccsm4', 'cesm1-bgc', ...
%           'gfdl-cm3', 'mpi-esm-mr', ...
%           'gfdl-esm2m', 'gfdl-esm2g', ...
%           'canesm2', 'noresm1-m', ...
%           'hadgem2-es', 'cesm1-cam5', ...
%           'cmcc-cm', 'cmcc-cms', ...    
%           'cnrm-cm5', 'ipsl-cm5a-mr', ...
%           'bnu-esm', 'miroc-esm', ...
%           'mri-cgcm3'};
      
models = {'hadgem2-es', 'mpi-esm-mr', 'ipsl-cm5a-mr', 'noresm1-m'};

ensembles = {'r1i1p1'};
rcps = {'historical', 'rcp85'};
plevs = {};

% nepal
latLonBounds = [[15 45]; [70 100]];
v7 = false;
      
for m = 1:length(models)
    for e = 1:length(ensembles)
        for r = 1:length(rcps)
            if length(plevs) > 0
                for p = 1:length(plevs)
                    regridOutput(['e:/data/' modelBaseDir '/' models{m} '/' ensembles{e} '/' rcps{r} '/' regridVar], regridVar, baseGrid, 'skipexisting', true, 'plev', plevs{p}, 'latLonBounds', latLonBounds, 'v7', v7);
                end
            else
                regridOutput(['e:/data/' modelBaseDir '/' models{m} '/' ensembles{e} '/' rcps{r} '/' regridVar], regridVar, baseGrid, 'skipexisting', true, 'latLonBounds', latLonBounds, 'v7', v7);
            end
        end
    end
end