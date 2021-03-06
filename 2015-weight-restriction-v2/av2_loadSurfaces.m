function [acSurfaces] = loadAvSurfaces()

    % aircraft name, OEW, min search weight, max take off weight
    aircraft = {{'737-800', 91, 140, 174, 'poly23'}, {'777-200', 0, 440, 545, 'poly23'}, ...
                {'777-300', 299, 480, 660, 'poly32'}, {'787', 260, 420, 502, 'poly23'}, ...
                {'a320', 93, 100, 174, 'poly23'}, {'a380', 610, 840, 1260, 'poly23'}};

    for a = 1:length(aircraft)
        data = csvread(['performance-data-' aircraft{a}{1} '.csv'], 1, 0);
        
        cutoffData = [];
        
        % if cutoff data is available
        if size(data, 2) == 6
            % select data that specifies cutoff line
            cutoffData = data(:, 5:6);
            % trim it (not as many rows as real data)
            cutoffData(find(cutoffData(:, 1) == 0), :) = [];
        end
       
        % select performance data
        data = data(:, 1:4);

        % elevation 0
        ind0 = find(data(:, 3) == 0);

        % elevation 2000
        ind2 = find(data(:, 3) == 2000);

        % elevation 4000
        ind4 = find(data(:, 3) == 4000);

        % make the surfaces
        f0 = fit([data(ind0, 1), data(ind0, 2)], data(ind0, 4), aircraft{a}{5}, 'Normalize','on');
        
        if length(ind2) > 10
            f2 = fit([data(ind2, 1), data(ind2, 2)], data(ind2, 4), aircraft{a}{5}, 'Normalize','on');
        else
            f2 = [];
        end
        
        if length(ind4) > 10
            f4 = fit([data(ind4, 1), data(ind4, 2)], data(ind4, 4), aircraft{a}{5}, 'Normalize','on');
        else
            f4 = [];
        end

        % make cutoff line fit
        if length(cutoffData) > 2
            fCutoff = fit(cutoffData(:,1), cutoffData(:,2), 'poly1', 'Normalize','on');
        else
            fCutoff = [];
        end
        
        acSurfaces{a} = {aircraft{a}, f0, f2, f4, fCutoff};

        % surfaces take in (temp, weight in thousands of pounds)
    end
end

