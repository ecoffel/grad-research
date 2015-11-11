load ssp\ssp5\output\ssp5\regrid\ssp5_2060.mat

[fg,cb] = plotModelData(ssp5_2060,'asia-heat', 'colormap', 'summer', 'caxis', [0 9e7]);
set(gca, 'Color', 'none');
set(gca, 'FontSize', 24);
title('Population density, 2060-2070', 'FontSize', 24);
set(gcf, 'Position', get(0,'Screensize'));
tightmap;
export_fig pop-dens-2060.pdf