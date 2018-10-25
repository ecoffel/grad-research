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

cind = 1;
for city = cities

    load([city{1} 'MortData.mat']);

    wbMax = mortData{2}(1:5114,12);
    tMax = mortData{2}(1:5114,7);
    tMax(abs(tMax)>100)=NaN;
    mdata = mortData{2}(1:5114,5);
    
    madj = mdata-smooth(mdata, 30);
    
    nn = find(isnan(wbMax) | isnan(mdata));
    wbMax(nn)=[];
    mdata(nn)=[];
    wbthresh = [20:29];

    wind = 1;
    for w = wbthresh
        if w<29
            ind = find(wbMax>w & wbMax<w+1);
        else
            ind = find(wbMax>w);
        end
        wbdays(wind,cind) = length(ind)/14;
        if length(ind) == 0
            wbanom(wind,cind) = NaN;
            wbanomabs(wind,cind) = NaN;
        else
            if kstest(madj(ind))
                wbanom(wind,cind) = (nanmean(madj(ind))-nanmean(madj))/nanmean(mdata)*100;
                wbanomabs(wind,cind) = (nanmean(mdata(ind))-nanmean(madj(ind)));
            else
                wbanom(wind,cind) = NaN;
                wbanomabs(wind,cind) = NaN;
            end
        end
        
        wind=wind+1;
    end
    mdataall(:,cind) = mdata;
    cind = cind+1;
     
%     figure;
%     plot(wbthresh,wbanom,'or');
%     ylim([0 50]);
%     xlim([19 30]);
%     title(city);
end
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

b = boxplot(wbanom', 'widths', .8);
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
plot(1:10, nanmean(wbdays,2), 'k');
ylabel('Mean # days per year');
ylim([-10 18])
set(gca, 'YTick', 0:4:16);

set(gcf, 'Position', get(0,'Screensize'));
export_fig(['heat-mort-us.eps']);
close all;