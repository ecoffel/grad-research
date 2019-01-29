cities = ["atl", "stl", "chi", "det", "bos", "balt", "dc", "hous", "char", "aust", "birm", ...
          "albu", "cinc", "clev", "dayt", "denv", "desm", "elpa", "evan", "fres", "ftwa", ...
          "gdrp", "grnb", "hono", "hunt", "indi", "jcks", "jckv", "john", "jers", "kan", ...
          "kans", "king", "knox", "lafy", "lasv", "lex", "linc", "loui", "ltrk", "lubb", "madi", "memp", "miam", "milw", "minn", "mobi", "mode", "musk", "nash", "new", "no", "nor", ...
          "nwk", "ny", "oakl", "okla", "olym", "oma", "orla", "phil", "phoe", "pitt", "port", "prov", "ral", "rich", "rive", "roch", "sacr", "salt", "sana", "sanb", "sand", "sanf", ...
          "sanj", "seat", "shr", "spok", "staa", "stoc", "stpe", "syra", "taco", "tamp", "tole", "tope", "tucs", "tuls", "wich", "wor", ...
          "akr", "anch", "arlv", "bake", "batr", "bidd", "buff", "cayc", "cdrp", "clmg", "clmo", "colo", "corp", "covt", "dlft"];


wbanom = [];
wbanomabs = [];
mdataall = [];
wbdays = [];
tanom = [];

hotdayT = [];
hotdayWb = [];
hotdayMort = [];

cind = 1;
for city = cities

    load(['2016-heat-humid-mortality/mortality-data/' city{1} 'MortData.mat']);

    wbMax = mortData{2}(1:5114,11);
    tMax = mortData{2}(1:5114,9);
    tMax(abs(tMax)>100)=NaN;
    mdata = mortData{2}(1:5114,5);
    
    madj = mdata-smooth(mdata, 30);
    
    nn = find(isnan(wbMax) | isnan(mdata));
    wbMax(nn)=[];
    mdata(nn)=[];
    wbthresh = [20:29];
    tthresh = [22:3:50];
    bstrapLen = 0;
    
    t1 = 25;
    t2 = 60;
    
    ind = find(tMax>t1 & tMax<t2 & wbMax > 10);
    
    if length(ind>10)
        f = fitlm(normc(tMax(ind)), (madj(ind)-nanmean(madj))./nanmean(mdata));
        hotdayTMSlope(cind) = f.Coefficients.Estimate(2);
        hotdayTMP(cind) = f.Coefficients.pValue(2);

        f = fitlm(normc(wbMax(ind)), (madj(ind)-nanmean(madj))./nanmean(mdata));
        hotdayWbMSlope(cind) = f.Coefficients.Estimate(2);
        hotdayWbMP(cind) = f.Coefficients.pValue(2);
    end
    
    hotdayT{cind} = normc(tMax(tMax>t1 & tMax<t2 & wbMax > 10));
    hotdayWb{cind} = normc(wbMax(tMax>t1 & tMax<t2 & wbMax > 10));
    hotdayMort{cind} = (madj(tMax>t1 & tMax<t2 & wbMax > 10)-nanmean(madj))./nanmean(mdata);
    
    
    wind = 1;
    for i = 1:length(wbthresh)
        w = wbthresh(i);
        t = tthresh(i);
        
        if i == 10
            indWb = find(wbMax>w);
            indT = find(tMax>t);
        else
            indWb = find(wbMax>w & wbMax<w+1);
            indT = find(tMax>=t & tMax<t+3);
        end

        % mean # days with this thresh (div by # years)
        wbdays(i,cind) = length(indWb)/14;
        tdays(i,cind) = length(indT)/14;
        if length(indWb) == 0
            wbanom(i,cind) = NaN;
            wbanomabs(i,cind) = NaN;
        else
            if kstest(madj(indWb))
                wbanom(i,cind) = (nanmean(madj(indWb))-nanmean(madj))/nanmean(mdata)*100;
                wbanomabs(i,cind) = (nanmean(mdata(indWb))-nanmean(madj(indWb)));
            else
                wbanom(i,cind) = NaN;
                wbanomabs(i,cind) = NaN;
            end
        end
        
        if length(indT) == 0
            tanom(i,cind) = NaN;
            tanomabs(i,cind) = NaN;
        else
            if kstest(madj(indT))
                tanom(i,cind) = (nanmean(madj(indT))-nanmean(madj))/nanmean(mdata)*100;
                tanomabs(i,cind) = (nanmean(mdata(indT))-nanmean(madj(indT)));
            else
                tanom(i,cind) = NaN;
                tanomabs(i,cind) = NaN;
            end
        end
        
    end
    mdataall(:,cind) = mdata;
    
    
%     % run bootstrap to compare 20-28c anoms using the same sample size as
%     % for 27+
%     if bstrapLen > 0
%         wind = 1;
%         for w = wbthresh
%             if w<29
%                 ind = find(wbMax>w & wbMax<w+1);
%             else
%                 ind = find(wbMax>w);
%             end
% 
%             if length(ind) == 0
%                 wbanomBootstrp(wind,cind) = NaN;
%                 wind = wind+1;
%                 continue;
%             end
% 
%             binds = randi([1 length(ind)], 100, min(bstrapLen, length(ind)));
%             means = [];
%             for i = 1:size(binds, 1)
%                 if kstest(madj(ind(binds(i, :))))
%                     means(i) = (nanmean(madj(ind(binds(i, :))))-nanmean(madj))/nanmean(mdata)*100;
%                 end
%             end
%             wbanomBootstrp(wind,cind) = nanmean(means);
%             wind=wind+1;
%         end
%     else
%         wbanomBootstrp(1:length(wbthresh),cind) = NaN;
%     end
    
    cind = cind+1;
     
%     figure;
%     plot(wbthresh,wbanom,'or');
%     ylim([0 50]);
%     xlim([19 30]);
%     title(city);
end
hotdayTMSlope(hotdayTMP>.05 | hotdayWbMP>.05) = [];
hotdayWbMSlope(hotdayTMP>.05 | hotdayWbMP>.05) = [];
figure; hold on; plot(hotdayTMSlope,hotdayWbMSlope,'o');plot([-10 10], [-10 10]);

colorTxx = [216, 66, 19]./255.0;
fig = figure('Color', [1,1,1]);
set(fig,'defaultAxesColorOrder',[colorTxx; [0 0 0]]);
hold on;
axis square;
box on;
grid on;
yyaxis left;
plot([0 30], [0 0], '--k', 'linewidth', 2);
%plot(wbthresh,nanmean(wbanom,2),'or','color', colorTxx,'markersize', 15, 'linewidth', 3)

b = boxplot(wbanom', 'widths', .6);
set(b, {'LineWidth', 'Color'}, {2, colorTxx})
lines = findobj(b, 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

xlim([.5 10.5]);
ylabel('Daily mortality (% above normal)');
xlabel(['T_W (' char(176) 'C)']);
set(gca, 'fontsize', 36);
set(gca, 'XTick', 1:10, 'XTickLabels', 20:29);
ylim([-100 180]);
set(gca, 'YTick', -90:30:180);

yyaxis right;
plot(1:10, nanmean(wbdays,2), 'k', 'linewidth', 2);
ylabel('Mean # days per year');
ylim([-10 18])
set(gca, 'YTick', 0:4:16);

set(gcf, 'Position', get(0,'Screensize'));
export_fig(['heat-tw-mort-us-bootstrap.eps']);
close all;












fig = figure('Color', [1,1,1]);
set(fig,'defaultAxesColorOrder',[colorTxx; [0 0 0]]);
hold on;
axis square;
box on;
grid on;
yyaxis left;
plot([0 30], [0 0], '--k', 'linewidth', 2);
%plot(wbthresh,nanmean(wbanom,2),'or','color', colorTxx,'markersize', 15, 'linewidth', 3)

b = boxplot(tanom', 'widths', .6);
set(b, {'LineWidth', 'Color'}, {2, colorTxx})
lines = findobj(b, 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

xlim([.5 10.5]);
ylabel('Daily mortality (% above normal)');
xlabel(['Tx (' char(176) 'C)']);
set(gca, 'fontsize', 36);
set(gca, 'XTick', 1:10, 'XTickLabels', 22:3:50);
ylim([-60 60]);
set(gca, 'YTick', -90:30:180);

yyaxis right;
plot(1:10, nanmean(tdays,2), 'k', 'linewidth', 2);
ylabel('Mean # days per year');
ylim([-30 30])
set(gca, 'YTick', 0:10:30);

set(gcf, 'Position', get(0,'Screensize'));
export_fig(['heat-tx-mort-us-bootstrap.eps']);
close all;