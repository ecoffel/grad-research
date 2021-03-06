load ssp\ssp5\output\ssp5\regrid\ssp5_2010.mat

load('pop-colormap.mat');

[fg,cb] = plotModelData(ssp5_2010,'asia-heat', 'colormap', colormap, 'caxis', [0 9e7]);
set(gca, 'Color', 'none');
set(gca, 'FontSize', 24);
title('Population density, SSP5, 2010', 'FontSize', 24);
xlabel(cb, 'People per gridbox', 'FontSize', 24);
set(gcf, 'Position', get(0,'Screensize'));
tightmap;
export_fig pop-dens-ssp5-2010.pdf