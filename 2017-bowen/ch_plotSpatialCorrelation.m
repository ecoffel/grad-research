load E:\data\projects\bowen\derived-chg\txxAmpThresh99.mat;
load E:\data\projects\bowen\derived-chg\prChgWarmTxxAnom.mat;

load waterGrid.mat;
waterGrid = logical(waterGrid);

figure('Color',[1,1,1]);
hold on;
grid on;
axis square;
box on;

for m = 1:size(amp,3)
    %subplot(5,5,m);
    %hold on;
    
    a = squeeze(amp(:,:,m));
    a(waterGrid) = NaN;
    a(1:15, :) = NaN;
    a(75:90, :) = NaN;
    a = reshape(a, [numel(a),1]);
    
    x = squeeze(prChgWarmTxxAnom(:,:,m)) .* 3600 .* 24;
    x(waterGrid) = NaN;
    x(1:15, :) = NaN;
    x(75:90, :) = NaN;
    x = reshape(x, [numel(x),1]);
    
    nn = find(isnan(a) | isnan(x));
    
    x(nn) = [];
    a(nn) = [];
    
    %p1 = plot(x,a,'k.');
    
    [f,gof,out] = fit(x, a, 'poly1');
    p = plot([min(x) max(x)], [f(min(x)) f(max(x))], 'k', 'LineWidth', 1);
 
end

xlim([-12 12]);
set(gca, 'XTick', -12:3:12);
ylim([-2 3]);
ylabel(['99th % Tx amplification (' char(176) 'C)']);
xlabel('PR amplification (mm/day)');
set(gca, 'FontSize', 40);