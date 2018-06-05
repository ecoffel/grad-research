% needs to handle plev
regridVar = {'d2m'};
gridSpacing = 2;

latGrid = meshgrid(linspace(-90, 90, 180/gridSpacing), linspace(0, 360, 360/gridSpacing))';
lonGrid = meshgrid(linspace(0, 360, 360/gridSpacing), linspace(-90, 90, 180/gridSpacing));
baseGrid = {latGrid, lonGrid, []};

for v = 1:length(regridVar)
    regridOutput(['e:/data/era-interim/output/' regridVar{v}], regridVar{v}, baseGrid, 'skipexisting', true, 'region', 'world');
end