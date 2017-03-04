baseDirGcm = 'E:/data/flight/airport-wx/';
baseDirAsos = '2015-weight-restriction-v2/airport-wx/processed/';

airports = {'DCA', 'DEN', 'IAH', 'JFK', 'LAX', 'LGA', 'MIA', 'ORD'};

% load pre-computed biases
load gcm-bias.mat;

for a = 1:length(airports)
    airport = airports{a};
    ['processing ' airport '...']
    
    % find index for current airport in error data
    aIndError = -1;
    for i = 1:length(errors)
        if strcmp(errors{i}{1}, airport)
            aIndError = i;
            break;
        end
    end
    
    % load CMIP5 temps
    load([baseDirGcm 'airport-wx-cmip5-rcp85-' airport '.mat']);
    tempsGcm = wxData;
    
    gcmMax = [];
    gcmMin = [];
    
    % max error: errors{a}{2}{m}{2}
    % min error: errors{a}{2}{m}{3}
    
    % loop over models
    for m = 1:length(tempsGcm)
        gcmMax(:, :, m) = nanmax(tempsGcm{m}{2}{2}(:, 1:372, :), [], 3);
        gcmMin(:, :, m) = nanmin(tempsGcm{m}{2}{2}(:, 1:372, :), [], 3);
    end
    
    % percentiles to calculate
    prcThresh = 0:10:100;
    
    for m = 1:size(gcmMax, 3)
        curModel = tempsGcm{m}{1};
        ['processing ' curModel '...']

        % find index of current model in errors
        indMod = -1;
        for i = 1:length(errors{aIndError}{2})
            if strcmp(errors{aIndError}{2}{i}{1}, curModel)
                indMod = i;
                break;
            end
        end

        gcmDistMax = [];
        gcmDistMin = [];

        % calculate percentile cutoffs for current GCM dist
        for p = 1:length(prcThresh)
            gcmDistMax(p) = prctile(reshape(gcmMax(:, :, m), [size(gcmMax(:, :, m), 1)*size(gcmMax(:, :, m), 2), 1]), prcThresh(p));
            gcmDistMin(p) = prctile(reshape(gcmMin(:, :, m), [size(gcmMin(:, :, m), 1)*size(gcmMin(:, :, m), 2), 1]), prcThresh(p));
        end

        % loop over years
        for y = 1:size(tempsGcm{m}{2}{2}, 1)
            
            % loop over days
            for d = 1:size(tempsGcm{m}{2}{2}, 2)
                % loop over hours
                for h = 1:size(tempsGcm{m}{2}{2}, 3)
                    temp = tempsGcm{m}{2}{2}(y, d, h);
                    corr = 0;
                    
                    % less than daily mean, use the daily min bias
                    if temp < nanmean(tempsGcm{m}{2}{2}(y, d, :), 3)
                        % find correct percentile bin
                        indBin = find(temp < gcmDistMin, 1, 'first');
                        
                        % if no value found, means that temp is past the
                        % last percentile - give it the max correction
                        if length(indBin) == 0
                            indBin = length(gcmDistMin);
                        end
                        
                        corr = errors{aIndError}{2}{indMod}{3}(indBin);
                    else
                        % use the daily max bias
                        % find correct percentile bin
                        indBin = find(temp < gcmDistMax, 1, 'first');
                        
                        % if no value found, means that temp is past the
                        % last percentile - give it the max correction
                        if length(indBin) == 0
                            indBin = length(gcmDistMax);
                        end
                        
                        corr = errors{aIndError}{2}{indMod}{2}(indBin);
                    end
                    
                    % correct the temperature
                    tempsGcm{m}{2}{2}(y, d, h) = temp - corr;
                    
                end
            end
        end
    end

    % save corrected GCM data
    wxData = tempsGcm;
    save([baseDirGcm 'airport-wx-cmip5-historical-bc-' airport '.mat'], 'wxData');
    
end
