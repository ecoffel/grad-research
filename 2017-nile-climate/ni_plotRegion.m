figure('Color',[1,1,1]);

set(gcf,'renderer','opengl');

hold on;
axis off;
box on;

[regionInds, regions, regionNames] = ni_getRegions();
regionBounds = regions('nile');
regionBoundsBlue = regions('nile-blue');
regionBoundsWhite = regions('nile-white');
regionBoundsNorth = regions('nile-north');


regions = [[[regionBoundsBlue(1,1) regionBoundsBlue(1,2) regionBoundsBlue(1,2) regionBoundsBlue(1,1)], [regionBoundsBlue(2,1) regionBoundsBlue(2,1) regionBoundsBlue(2,2) regionBoundsBlue(2,2)]]; ...
           [[regionBoundsWhite(1,1) regionBoundsWhite(1,2) regionBoundsWhite(1,2) regionBoundsWhite(1,1)], [regionBoundsWhite(2,1) regionBoundsWhite(2,1) regionBoundsWhite(2,2) regionBoundsWhite(2,2)]]];
           %[[regionBoundsNorth(1,1) regionBoundsNorth(1,2) regionBoundsNorth(1,2) regionBoundsNorth(1,1)], [regionBoundsNorth(2,1) regionBoundsNorth(2,1) regionBoundsNorth(2,2) regionBoundsNorth(2,2)]]];

worldmap('africa');
landmass = shaperead('landareas.shp', 'UseGeoCoords', true);
countries = shaperead('2017-nile-climate/data/shape/countries/ne_50m_admin_0_countries.shp', 'UseGeoCoords', true);
geoshow(landmass, 'FaceColor', 'w', 'EdgeColor', 'k');

% if ~exist('bwfp')
%     bwfpLat = [];
%     bwfpLon = [];
%     bwfp = [];
%     gwfp = [];
% 
%     % load domind bwfp
%     load E:\data\bgwfp\output\domind\bwfp\bwfp_1.mat
%     bwfpDomind = bwfp_1;
%     
%     for m = 1:12
%         fprintf('loading bwfp/gwfp month %d...\n', m);
% 
%         load(['E:\data\bgwfp\output\ag\bwfp\bwfp_' num2str(m)]);
%         eval(['bwfp(:, :, ' num2str(m) ') = bwfp_' num2str(m) '{3};']);
% 
%         if m == 1
%             bwfpLat = bwfp_1{1};
%             bwfpLon = bwfp_1{2};
%             bwfpDomind = regridGriddata(bwfpDomind, {bwfpLat, bwfpLon, []}, false); 
%         end
% 
%         % add domind onto ag bwfp
%         bwfp(:,:,m) = bwfp(:,:,m)+bwfpDomind{3};
%         
%         eval(['clear bwfp_' num2str(m) ';']);
%         eval(['clear gwfp_' num2str(m) ';']);
%     end
% end

load e:/data/ssp-pop/ssp3/output/ssp3/ssp3_2010.mat;
sspLat = ssp3_2010{1};
sspLon = ssp3_2010{2};
sspData = ssp3_2010{3};

[latInds, lonInds] = latLonIndexRange({sspLat, sspLon, []}, regionBounds(1,:), regionBounds(2,:));
earthradius = almanac('earth','radius','kilometers');

latdiff = ssp3_2010{1}(2,1)-ssp3_2010{1}(1,1);
londiff = ssp3_2010{2}(1,2)-ssp3_2010{2}(1,1);

areaTable = [];
for xind = 1:length(latInds)
    xlat = latInds(xind);
    for yind = 1:length(lonInds)
        ylon = lonInds(yind);
        curArea = areaint([ssp3_2010{1}(xlat, ylon) ssp3_2010{1}(xlat, ylon)+latdiff ssp3_2010{1}(xlat, ylon)+latdiff ssp3_2010{1}(xlat, ylon)], ...
                          [ssp3_2010{2}(xlat, ylon) ssp3_2010{2}(xlat, ylon) ssp3_2010{2}(xlat, ylon)+londiff ssp3_2010{2}(xlat, ylon)+londiff], earthradius);

        areaTable(xind, yind) = curArea;
    end
end

sspData = sspData(latInds, lonInds) ./ areaTable;

pcolorm(sspLat(latInds, lonInds), sspLon(latInds, lonInds), sspData);
cmap = brewermap(50,'Reds');
cmap(1,:)=[1 1 1];
colormap(cmap);

caxis([0, 5e2]);
alpha(.9);
cb = colorbar('Location', 'southoutside');
xlabel(cb, 'People per km^{2}', 'FontSize', 30);
set(gca, 'fontsize', 30);

geoshow(landmass, 'FaceColor', 'none', 'EdgeColor', 'k');

rivers = shaperead('2017-nile-climate/data/shape/rivers/world_rivers_dSe.shp', 'UseGeoCoords', true);
geoshow(rivers, 'Color', 'blue')
geoshow(countries, 'DisplayType', 'polygon', 'DefaultFaceColor', 'none');
tightmap;

load coast;
geoshow(flipud(lat),flipud(long), 'DisplayType', 'polygon', 'FaceColor', [166/255.0, 205/255.0, 227/255.0]);

for r = 1:size(regions,1)
    geoshow(regions(r, 1:4), regions(r, 5:8), 'DisplayType', 'polygon', 'FaceColor', [0.7, 0.7, 0.7], 'FaceAlpha', 0.2, 'EdgeColor', 'k', 'LineWidth', 1);
end

set(gcf, 'Position', get(0,'Screensize'));
export_fig nile-regions.png -m5;
