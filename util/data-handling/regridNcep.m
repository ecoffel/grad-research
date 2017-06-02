% needs to handle plev
baseGridModel = 'f:/data/ncep-reanalysis/output';
regridVar = 'soilw10';
gridSpacing = 2;

latGrid = meshgrid(linspace(-90, 90, 180/gridSpacing), linspace(0, 360, 360/gridSpacing))';
lonGrid = meshgrid(linspace(0, 360, 360/gridSpacing), linspace(-90, 90, 180/gridSpacing));
baseGrid = {latGrid, lonGrid, []};

regridOutput(['f:/data/ncep-reanalysis/output/' regridVar], regridVar, baseGrid, 'skipexisting', false);