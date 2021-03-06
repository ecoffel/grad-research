regridVars = {'tas', 'pr'};
gridSpacing = 2;

latGrid = meshgrid(linspace(-90, 90, 180/gridSpacing), linspace(0, 360, 360/gridSpacing))';
lonGrid = meshgrid(linspace(0, 360, 360/gridSpacing), linspace(-90, 90, 180/gridSpacing));
baseGrid = {latGrid, lonGrid, []};

modelBaseDir = 'cmip5/output';
models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'ec-earth', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'giss-e2-h', 'giss-e2-h-cc', 'giss-e2-r', 'giss-e2-r-cc', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-lr', 'ipsl-cm5a-mr', 'ipsl-cm5b-lr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'}; %'ccsm4'};
models = {'gfdl-cm3'};
%ensembles = {'r1i1p1', 'r2i1p1', 'r3i1p1', 'r4i1p1', 'r5i1p1', 'r6i1p1', 'r7i1p1', 'r8i1p1', 'r9i1p1', 'r10i1p1'};
ensembles = {'r1i1p1'};
rcps = {'historical', 'rcp45', 'rcp85'};
plevs = {};

region = 'world';
skipexisting = true;
monthly = true;

latLonBounds = [];
if strcmp(region, 'usne')
    latLonBounds = [[30 55]; [-100 -62]+360];
elseif strcmp(region, 'world')
    latLonBounds = [[-90 90]; [0 360]];
elseif strcmp(region, 'nepal')
    latLonBounds = [[15 45]; [70 100]];
end

v7 = false;
      
for v = 1:length(regridVars)
    for m = 1:length(models)
        for e = 1:length(ensembles)
            for r = 1:length(rcps)
                if length(plevs) > 0
                    for p = 1:length(plevs)
                        regridOutput(['e:/data/' modelBaseDir '/' models{m} '/' ensembles{e} '/' rcps{r} '/' regridVars{v}], regridVars{v}, baseGrid, 'skipexisting', skipexisting, 'plev', plevs{p}, 'latLonBounds', latLonBounds, 'v7', v7, 'region', region, 'startYear', 1950, 'endYear', 2100);
                    end
                else
                    if monthly
                        regridOutput(['e:/data/' modelBaseDir '/' models{m} '/mon/' ensembles{e} '/' rcps{r} '/' regridVars{v}], regridVars{v}, baseGrid, 'skipexisting', skipexisting, 'latLonBounds', latLonBounds, 'v7', v7, 'region', region, 'tos-strangegrid', false, 'startYear', 1850, 'endYear', 2100);
                    else
                        regridOutput(['e:/data/' modelBaseDir '/' models{m} '/' ensembles{e} '/' rcps{r} '/' regridVars{v}], regridVars{v}, baseGrid, 'skipexisting', skipexisting, 'latLonBounds', latLonBounds, 'v7', v7, 'region', region, 'tos-strangegrid', false, 'startYear', 1950, 'endYear', 2100);
                    end
                end
            end
        end
    end
end