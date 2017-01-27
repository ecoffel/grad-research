prefix = 'tr';
rcp = 'historical';

% the new tr/wr files minus the "tr"/"wr"
fileNew = ['-777-300-cmip5-' rcp '-new'];
fileOld = ['-777-300-cmip5-' rcp];

% load the data - and yes these if blocks do need to be repeated like this
load([prefix fileNew]);
if strcmp(prefix, 'wr')
    dataNew = weightRestriction;
elseif strcmp(prefix, 'tr')
    dataNew = totalRestriction;
end

load([prefix fileOld]);
if strcmp(prefix, 'wr')
    dataOld = weightRestriction;
elseif strcmp(prefix, 'tr')
    dataOld = totalRestriction;
end

for aNew = 1:length(dataNew)
    % is this airport in the old data file
    isIn = false;
    
    % search old data file for current airport
    for aOld = 1:length(dataOld)
        if strcmp(dataOld{aOld}{1}{1}, dataNew{aNew}{1}{1})
            isIn = true;
            break;
        end
    end
    
    % if not in old file, copy it in
    if ~isIn
        dataOld{end+1} = dataNew{aNew};
    end
end

% save the modified old file
if strcmp(prefix, 'wr')
    weightRestriction = dataOld;
    save([prefix fileOld '.mat'], 'weightRestriction');
elseif strcmp(prefix, 'tr')
    totalRestriction = dataOld;
    save([prefix fileOld '.mat'], 'totalRestriction');
end



