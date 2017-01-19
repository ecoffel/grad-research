
if ~exist('wxDataRcp85')
    load airport-wx-cmip5-rcp85;
    wxDataRcp85 = wxData;
end

if ~exist('wxDataRcp45')
    load airport-wx-cmip5-rcp45;
    wxDataRcp45 = wxData;
end

% mean daily max or annual max
annMax = true;

airports = {'PHX', 'DEN', 'MDW', 'DXB'};

figure('Color', [1, 1, 1]);

ind = 1;
% loop over airports
for a = 1:length(wxData{1})
    
    if ~ismember(wxData{1}{a}{1}, airports)
        continue;
    end
    
    tasmaxRcp85 = [];
    tasmaxRcp45 = [];
    
    ['processing ' wxData{1}{a}{1} '...']
    
    % loop over models
    for m = 1:length(wxDataRcp85)
        % loop over years
        for y = 1:size(wxDataRcp85{m}{a}{2}, 1)
            % loop over days
            for d = 1:size(wxDataRcp85{m}{a}{2}, 2)
                % max of 24 hour temps
                tasmaxRcp85(m, y, d) = nanmax(wxDataRcp85{m}{a}{2}(y, d, :));
                tasmaxRcp45(m, y, d) = nanmax(wxDataRcp45{m}{a}{2}(y, d, :));
            end
        end
    end
    
    annualMeanRcp85 = squeeze(nanmean(tasmaxRcp85, 3));
    annualMaxRcp85 = squeeze(nanmax(tasmaxRcp85, [], 3));
    annualMeanErrRcp85 = std(annualMeanRcp85, [], 1);
    annualMaxErrRcp85 = std(annualMaxRcp85, [], 1);
    
    annualMeanRcp45 = squeeze(nanmean(tasmaxRcp45, 3));
    annualMaxRcp45 = squeeze(nanmax(tasmaxRcp45, [], 3));
    annualMeanErrRcp45 = std(annualMeanRcp45, [], 1);
    annualMaxErrRcp45 = std(annualMaxRcp45, [], 1);
    
    h = subplot(2, 2, ind);
    hold on;
    
    if annMax
        p1 = shadedErrorBar(1:size(annualMaxRcp85, 2), nanmean(annualMaxRcp85, 1), annualMaxErrRcp85, '-', 1);
        set(p1.mainLine,  'LineWidth', 2, 'Color', [237/255.0, 104/255.0, 104/255.0]);
        set(p1.patch, 'FaceColor', [237/255.0, 104/255.0, 104/255.0]);
        set(p1.edge, 'Color', 'k');

        p2 = shadedErrorBar(1:size(annualMaxRcp45, 2), nanmean(annualMaxRcp45, 1), annualMaxErrRcp45, '-', 1);
        set(p2.mainLine,  'LineWidth', 2, 'Color', [104/255.0, 186/255.0, 237/255.0]);
        set(p2.patch, 'FaceColor', [104/255.0, 186/255.0, 237/255.0]);
        set(p2.edge, 'Color', 'k');
    else
        p1 = shadedErrorBar(1:size(annualMeanRcp85, 2), nanmean(annualMeanRcp85, 1), annualMeanErrRcp85, '-', 1);
        set(p1.mainLine,  'LineWidth', 2, 'Color', [237/255.0, 104/255.0, 104/255.0]);
        set(p1.patch, 'FaceColor', [237/255.0, 104/255.0, 104/255.0]);
        set(p1.edge, 'Color', 'k');

        p2 = shadedErrorBar(1:size(annualMeanRcp45, 2), nanmean(annualMeanRcp45, 1), annualMeanErrRcp45, '-', 1);
        set(p2.mainLine,  'LineWidth', 2, 'Color', [104/255.0, 186/255.0, 237/255.0]);
        set(p2.patch, 'FaceColor', [104/255.0, 186/255.0, 237/255.0]);
        set(p2.edge, 'Color', 'k');
    end
    
    set(h, 'XTick', [1 21 41 61]);
    set(h, 'XTickLabel', [2020 2040 2060 2080]);
    set(h, 'FontSize', 30);
    ylabel(['Temperature (' char(176) 'C)'], 'FontSize', 30);
    xlim([1 61]);
    title(wxDataRcp85{1}{a}{1}, 'FontSize', 30);
    legend([p1.mainLine, p2.mainLine], 'RCP 8.5', 'RCP 4.5');
    
    
    ind = ind + 1;
end