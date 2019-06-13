% needs to handle plev
%baseGridModel = 'e:/data/cpc-temp/output';
baseGridModel = 'e:/data/cpc-temp/output';
regridVar = 'tmax';
%regridVar = 'precip';
gridSpacing = 2;

latGrid = meshgrid(linspace(-90, 90, 180/gridSpacing), linspace(0, 360, 360/gridSpacing))';
lonGrid = meshgrid(linspace(0, 360, 360/gridSpacing), linspace(-90, 90, 180/gridSpacing));
baseGrid = {latGrid, lonGrid, []};

region = 'world';

regridOutput(['e:/data/cpc-temp/output/' regridVar], regridVar, baseGrid, 'skipexisting', true, 'region', region);
%regridOutput(['e:/data/gpcp/output/' regridVar '/monthly'], regridVar, baseGrid, 'skipexisting', true, 'region', region);