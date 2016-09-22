regridVars = {'hurs', 'tas', 'pr'};
gridSpacing = 2;

latGrid = meshgrid(linspace(-90, 90, 180/gridSpacing), linspace(0, 360, 360/gridSpacing))';
lonGrid = meshgrid(linspace(0, 360, 360/gridSpacing), linspace(-90, 90, 180/gridSpacing));
baseGrid = {latGrid, lonGrid, []};

modelBaseDir = 'cmip5/output';

models = {'access1-0', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', 'cnrm-cm5'};

ensembles = 1;
rcps = {'historical', 'rcp45', 'rcp85'};
plevs = {};

timespace = 'amon';
region = 'world';
skipexisting = true;
      
for v = 1:length(regridVars)
    for m = 1:length(models)
        for e = 1:length(ensembles)
            for r = 1:length(rcps)
                regridOutput(['e:/data/' modelBaseDir '/' models{m} '/r' num2str(ensembles(e)) 'i1p1/' rcps{r} '/' regridVars{v} '/' timespace], regridVars{v}, baseGrid, 'skipexisting', skipexisting);
            end
        end
    end
end