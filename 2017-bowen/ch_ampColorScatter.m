load E:\data\projects\bowen\derived-chg\txxAmpThresh99.mat
load E:\data\projects\bowen\derived-chg\efChgWarmTxxAnom.mat
load E:\data\projects\bowen\derived-chg\prChgWarmTxxAnom.mat
load lat
load lon
load waterGrid

waterGrid=logical(waterGrid);

regionNames = {'World', ...
                'Eastern U.S.', ...
                'Southeast U.S.', ...
                'Central Europe', ...
                'Mediterranean', ...
                'Northern SA', ...
                'Amazon', ...
                'Central Africa', ...
                'North Africa', ...
                'China', ...
                'South Africa', ...
                'Southern SA'};
regionAb = {'world', ...
            'us-east', ...
            'us-se', ...
            'europe', ...
            'med', ...
            'sa-n', ...
            'amazon', ...
            'africa-cent', ...
            'n-africa', ...
            'china', ...
            's-africa', ...
            'sa-s'};
            
regions = [[[-90 90], [0 360]]; ...             % world
           [[30 42], [-91 -75] + 360]; ...     % eastern us
           [[30 41], [-95 -75] + 360]; ...      % southeast us
           [[45, 55], [10, 35]]; ...            % Europe
           [[35 50], [-10+360 45]]; ...        % Med
           [[5 20], [-90 -45]+360]; ...         % Northern SA
           [[-10, 7], [-75, -62]+360]; ...      % Amazon
           [[-10 10], [15, 30]]; ...            % central africa
           [[15 30], [-4 29]]; ...              % north africa
           [[22 40], [105 122]]; ...               % china
           [[-24 -8], [14 40]]; ...                      % south africa
           [[-45 -25], [-65 -49]+360]];

region = 2;

[latInds, lonInds] = latLonIndexRange({lat, lon, []}, regions(region, [1 2]), regions(region, [3 4]));

ampProc = [];
efProc = [];
prProc = [];

for m = 1:25
    a=amp(:,:,m);
    a(waterGrid)=NaN;
    a(1:20,:)=NaN;
    a(75:90,:)=NaN;
    ampProc(:,:,m)=a;

    e=efChgWarmTxxAnom(:,:,m);
    e(waterGrid)=NaN;
    e(1:20,:)=NaN;
    e(75:90,:)=NaN;
    efProc(:,:,m)=e;
    
    p=prChgWarmTxxAnom(:,:,m);
    p(waterGrid)=NaN;
    p(1:20,:)=NaN;
    p(75:90,:)=NaN;
    prProc(:,:,m)=p;
end

a=reshape(ampProc,[numel(ampProc),1]);
e=reshape(efProc,[numel(efProc),1]);
p=reshape(prProc,[numel(prProc),1]);

nn = find(isnan(e) | isnan(a) | isnan(p) | abs(e)>.5);

a(nn)=[];
e(nn)=[];
p(nn)=[];

cmap = '*RdBu';
ampSort = a(randperm(length(a)));
cmap = brewermap(200, cmap);
cmapRange = [-1 1];

% loop over all models
colors = ampSort ./ cmapRange(2);
colors(colors>1) = 1;
colors(colors<-1) = -1;
colors = round(colors*100)+100;
colors(colors==0)=1;
colors = cmap(colors,:);

scatter(e,p,10,colors,'filled');


colormap(cmap);
caxis(cmapRange);
cb = colorbar();
ylabel(cb, 'TXx amplification');

