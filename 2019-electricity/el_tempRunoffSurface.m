data = csvread(['2019-electricity/nuke-panel-data.csv'], 0, 0);

tempQsSurf = fit([data(:, 1), data(:, 2)], data(:, 3), 'poly35');

x = linspace(20, 50, 100);
y = linspace(-3, 3, 100);
[X, Y] = meshgrid(x,y);

Z = tempQsSurf(X, Y);
Z(Z > 100) = NaN;
Z(Z < 0) = NaN;
surf(X, Y, Z, 'EdgeColor', 'none');


histTx = csvread(['2019-electricity/entsoe-nuke-pp-tx-era.csv'], 0, 0);
histYr = histTx(1,:);
histMn = histTx(2,:);
histDy = histTx(3,:);
histTx = histTx(4:end,:);

ind = find(histMn == 7 | histMn == 8);

histTx = histTx(:, ind);

prctileChg = [];

warmings = [1, 1.5, 2, 3, 4];
pLevels = [.04 .05 .075 .1 .5 1 5 10];
returns = (100 ./ pLevels) / 62;

for p = 1:length(pLevels)
    for w = 1:length(warmings)
        xreal = histTx+warmings(w);
        qsreal = ones(size(xreal)) .* nanmean(data(:,2)) - .25;

        pcHist = tempQsSurf(histTx,qsreal);
        pcFut = tempQsSurf(xreal,qsreal);
        
        prctileChg(w, p) = nanmean(prctile(pcFut,pLevels(p),2) - prctile(pcHist,pLevels(p),2));
    end
end

figure('color', [1,1,1]);
hold on;

plot(prctileChg');
set(gca, 'xticklabels', round(returns,1));
