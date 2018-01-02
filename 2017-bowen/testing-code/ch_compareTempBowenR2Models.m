
regions = {'world', 'europe', 'us-east', 'amazon'};
regionNames = {'World', 'Central Europe', 'Eastern U.S.', 'Amazon'};
models = {'poly1', 'poly2'};




for r = 1:length(regions)
    ['region = ' regions{r} '...']
    figure('Color', [1,1,1]);
    hold on;
    axis square;
    grid on;
    box on;
    
    lineTypes = {'-', '--', ':'};
    
    for m = 1:length(models)
        load(['r2BT-' regions{r} '-' models{m} '.mat']);
        
        [models{m} ' = ' num2str(nanmean([nanmean(r2BT(end-1, :)) nanmean(r2BT(end, :))])) '...']
        
        % get ncep & era model info
        ncep = r2BT(end-1, :);
        era = r2BT(end, :);
        
        plot(1:12, ncep, 'LineStyle', lineTypes{m}, 'Color', 'r', 'LineWidth', 2);
        plot(1:12, era, 'LineStyle', lineTypes{m}, 'Color', 'b', 'LineWidth', 2);
    end
    
    if r == 1
        legend('NCEP, 1st degree', 'ERA, 1st degree', 'NCEP, 2nd degree', 'ERA, 2nd degree');
    end
    
    set(gca, 'FontSize', 30);
    title(regionNames{r}, 'FontSize', 40);
    xlabel('Month', 'FontSize', 32);
    xlim([0.5 12.5]);
    set(gca, 'XTick', 1:12);
    ylabel('R2', 'FontSize', 32);
    
    set(gcf, 'Position', get(0,'Screensize'));
    export_fig(['model-comparison-' regions{r} '.png']);
    close all;
end