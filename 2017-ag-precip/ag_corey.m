clear r_pex r_tex
cropStartYr = 1970; %or 1971?
r_tex = [];
r_pex = [];
states={'AL','AR','AZ','CA','CO','DE','FL','GA','IA','ID','IL','IN','KS','KY','LA','MD','MN','MO','MS','MT','NC','ND','NE','NJ','NM','NY','OH','OK','OR','PA','SC','SD','TN','TX','UT','VA','WA','WI','WV','WY'};

% loop state
for s = 2:length(states)
    dataloader = load(['2017-ag-precip\ag-data\cropWxData-' states{s} '-grouped-small.mat']);
    
    stateData=dataloader.cropWxData;
    stateId=stateData{2};

    % loop county
    for c = 1:length(stateData{1,3})
        %skip counties missing wx data
        if length(stateData{3}{c}) == 7
            
            countyId=stateData{3}{c}{2};
            countyAgTs=stateData{3}{c}{5};
            
            if length(countyAgTs) ~= 46
                continue
            end
            
            % some counties have badly formatted temp/pricip groupings -
            % this length should be 5, but in a few counties it's 10. skip 
            if length(stateData{3}{c}{7}{1}) == 10
                ['skipping state = ' num2str(s) ', county = ' num2str(c)]
                continue;
            end
            
            countyAgTs(1,countyAgTs==0)=NaN;
            countyAgTs_detrend = detrend2(countyAgTs);
            
            %pull y anoms for tex years
            for y = 1:length(stateData{3}{c}{7}{1}{1})
                
                r_tex(size(r_tex,1)+1,1) = stateId;
                r_tex(size(r_tex,1),2) = countyId;
                r_tex(size(r_tex,1),3) = stateData{3}{c}{7}{1}{1}{y}{1};                                        %year
                r_tex(size(r_tex,1),4) = countyAgTs_detrend(stateData{3}{c}{7}{1}{1}{y}{1} - cropStartYr + 1);  %Y anom
                r_tex(size(r_tex,1),5) = stateData{3}{c}{6};  %dist to station from county centroid
                r_tex(size(r_tex,1),6) = max(stateData{3}{c}{7}{1}{1}{y}{2});  %extreme value
                
                % collect mean T for r_tex & r_pex
                r_tex(size(r_tex,1),7) = stateData{3}{c}{7}{1}{4}(stateData{3}{c}{7}{1}{3}==stateData{3}{c}{7}{1}{1}{y}{1});  %seasonal avg T
                r_pex(size(r_tex,1),7) = stateData{3}{c}{7}{1}{4}(stateData{3}{c}{7}{1}{3} == stateData{3}{c}{7}{1}{1}{y}{1});             %seasonal avg T
                
            end
            
            for y = 1:length(stateData{3}{c}{7}{1}{2})
                r_pex(size(r_pex,1)+1,1) = stateId;
                r_pex(size(r_pex,1),2) = countyId;
                r_pex(size(r_pex,1),3) = stateData{3}{c}{7}{1}{2}{y}{1};
                r_pex(size(r_pex,1),4) = countyAgTs_detrend(stateData{3}{c}{7}{1}{2}{y}{1} - cropStartYr + 1);
                r_pex(size(r_pex,1),5) = stateData{3}{c}{6};
                r_pex(size(r_tex,1),6) = max(stateData{3}{c}{7}{1}{2}{y}{2});               %extreme value
                
                % collect mean P for r_tex & r_pex
                r_tex(size(r_tex,1),8) = stateData{3}{c}{7}{1}{5}(stateData{3}{c}{7}{1}{3}==stateData{3}{c}{7}{1}{2}{y}{1});  %seasonal avg P
                r_pex(size(r_tex,1),8) = stateData{3}{c}{7}{1}{5}(stateData{3}{c}{7}{1}{3} == stateData{3}{c}{7}{1}{2}{y}{1});             %seasonal avg P
                
            end
        end
    end
end