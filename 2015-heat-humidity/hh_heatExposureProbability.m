
decade = 2070;
exportFormat = 'png';
heatThresholds = [34 35];% 33 34 35];
rcps = {'rcp45', 'rcp85'};

ssps = 1:5;

load lat;
load lon;

region = 'world';

colors = {[0 0 0], [.2 0 0], [.4 0 0], [.6 0 0], [.8 0 0], [.9 0 0], [1 0 0]};
lStr = '';

figure('Color', [1,1,1]);
hold on;

cnt = 1;

rcp45Color = [85/255.0, 158/255.0, 237/255.0];
rcp85Color = [237/255.0, 92/255.0, 85/255.0];

for h = 1:length(heatThresholds)
    
    heatThreshold = heatThresholds(h);
    popBins = [1 10 100 500 1000 5000 1e4 5e4 1e5 5e5 1e6 5e6 1e7 5e7 1e8];% 5e8 1e9 5e9 1e10];
    
    ax = subplot(2, 2, h);
    title([num2str(heatThreshold) char(176) 'C'], 'FontSize', 30);
    hold on;
    
    set(gca,'Xdir','reverse')
    set(gca,'xscale','log')
    xlabel('Mean annual exposure', 'FontSize', 30);
    ylabel('Probability', 'FontSize', 30);
    ylim([0 100]);
    xlim([1 1e8]);
    set(gca, 'XTick', [1 10 100 1000 1e4 1e5 1e6 1e7 1e8]);
    set(gca,'FontSize', 30);

    for r = 1:length(rcps)
        rcp = rcps{r};
        
        popVals = zeros(length(popBins), 1);
        popExposure = [];
        
        % 36 scenarios if using both rcps, otherwise only 18
        if strcmp(rcp, 'all-rcp')
            scenarios = 1:36;
        else
            scenarios = 1:18;
        end
        
        for c = scenarios
            selGridStr = ['selGrid/selGrid-' num2str(decade) 's-' rcp '-' num2str(heatThreshold) 'C-scenario-' num2str(c)];

            % try to load future file
            if exist([selGridStr '.mat'], 'file')

                % load future counts
                load(selGridStr);

                % loop through all scenarios and count pop for each
                for s = 1:length(ssps)
                    popExposure(c, s) = hh_countPop({lat, lon, selGrid}, region, [decade], ssps(s), true);

                    for p = 1:length(popBins)
                        if popExposure(c, s) < popBins(p)
                            popVals(p) = popVals(p)+1;
                            break;
                        end
                    end
                end
            end
        end

        popVals = popVals ./ sum(popVals) .* 100;
        for p = 1:length(popVals)
            popVals(p) = sum(popVals(p:end));
        end

        p1 = plot(popBins, popVals, 'LineWidth', 4);        

        if strcmp(rcp, 'rcp45')
            set(p1, 'Color', rcp45Color);
        elseif strcmp(rcp, 'rcp85')
            set(p1, 'Color', rcp85Color);
        end
        
        cnt = cnt+1;
    end
end

set(gcf, 'Position', get(0,'Screensize'));
set(gcf, 'Color', [1,1,1]);
%l = legend(lStr);
%set(l, 'FontSize', 24);
%export_fig(['heatExposureProbability-' num2str(heatThreshold) '.png']);