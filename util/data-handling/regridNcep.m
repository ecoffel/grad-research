% needs to handle plev
baseGridModel = 'e:/data/ncep-reanalysis/output';
regridVar = 'rhum';
gridSpacing = 2;

latGrid = meshgrid(linspace(-90, 90, 180/gridSpacing), linspace(0, 360, 360/gridSpacing))';
lonGrid = meshgrid(linspace(0, 360, 360/gridSpacing), linspace(-90, 90, 180/gridSpacing));
baseGrid = {latGrid, lonGrid, []};

regridOutput(['e:/data/ncep-reanalysis/output/' regridVar], regridVar, baseGrid, 'skipexisting', true, 'plev', 1);