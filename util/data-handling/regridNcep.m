% needs to handle plev
baseGridModel = 'e:/data/ncep-reanalysis/output';
regridVar = 'pevpr';
gridSpacing = 2;

latGrid = meshgrid(linspace(-90, 90, 180/gridSpacing), linspace(0, 360, 360/gridSpacing))';
lonGrid = meshgrid(linspace(0, 360, 360/gridSpacing), linspace(-90, 90, 180/gridSpacing));
baseGrid = {latGrid, lonGrid, []};

region = 'world';

regridOutput(['e:/data/ncep-reanalysis/output/' regridVar], regridVar, baseGrid, 'skipexisting', true, 'region', region);