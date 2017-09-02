% needs to handle plev
regridVar = 'mn2t';
gridSpacing = 2;

latGrid = meshgrid(linspace(-90, 90, 180/gridSpacing), linspace(0, 360, 360/gridSpacing))';
lonGrid = meshgrid(linspace(0, 360, 360/gridSpacing), linspace(-90, 90, 180/gridSpacing));
baseGrid = {latGrid, lonGrid, []};

regridOutput(['g:/data/era-interim/output/' regridVar], regridVar, baseGrid, 'skipexisting', false);