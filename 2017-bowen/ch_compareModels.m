
regions = {'world', 'europe', 'us-cent', 'amazon'};
models = {'poly1', 'poly2', 'poly3'};



for r = 1:length(regions)
    ['region = ' regions{r} '...']
    
    figure('Color', [1,1,1]);
    hold on;
    axis square;
    grid on;
    box on;
    for m = 1:length(models)
        load(['r2BT-' regions{r} '-' models{m} '.mat']);
        
        [models{m} ' = ' num2str(nanmean([nanmean(r2BT(end-1, :)) nanmean(r2BT(end, :))])) '...']
        
        % get ncep & era model info
        ncep = r2BT(end-1, :);
        era = r2BT(end, :);
        
        plot(1:12, ncep, 'Color', 'r', 'LineWidth', 2);
        plot(1:12, era, 'Color', 'b', 'LineWidth', 2);
    end
end