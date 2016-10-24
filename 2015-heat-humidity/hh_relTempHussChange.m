region = 'us-ne';

load(['outputHuss-' region '-historical'])
hussHistorical = outputHuss;

load(['outputHuss-' region '-rcp45']);
hussRcp45 = outputHuss;

load(['outputHuss-' region '-rcp85']);
hussRcp85 = outputHuss;

load(['outputTemp-' region '-historical']);
tempHistorical = outputTemp;

load(['outputTemp-' region '-rcp45']);
tempRcp45 = outputTemp;

load(['outputTemp-' region '-rcp85']);
tempRcp85 = outputTemp;

load(['outputWb-' region '-historical']);
wbHistorical = outputWb;

load(['outputWb-' region '-rcp45']);
wbRcp45 = outputWb;

load(['outputWb-' region '-rcp85']);
wbRcp85 = outputWb;

tempChg45Data = [];
tempChg85Data = [];
hussChg45Data = [];
hussChg85Data = [];

figure('Color', [1,1,1]);
hold on;
for m = 1:length(hussHistorical)
    wbChg45 = nanmean(wbRcp45{m}) - nanmean(wbHistorical{m});
    wbChg85 = nanmean(wbRcp85{m}) - nanmean(wbHistorical{m});
    wbChg45Prc = wbChg45 / nanmean(wbHistorical{m}) * 100;
    wbChg85Prc = wbChg85 / nanmean(wbHistorical{m}) * 100;
    
    tempChg45 = nanmean(tempRcp45{m}) - nanmean(tempHistorical{m});
    tempChg85 = nanmean(tempRcp85{m}) - nanmean(tempHistorical{m});
    tempChg45Prc = tempChg45 / nanmean(tempHistorical{m}) * 100;
    tempChg85Prc = tempChg85 / nanmean(tempHistorical{m}) * 100;
    
    hussChg45 = nanmean(hussRcp45{m}) - nanmean(hussHistorical{m});
    hussChg85 = nanmean(hussRcp85{m}) - nanmean(hussHistorical{m});
    hussChg45Prc = hussChg45 / nanmean(hussHistorical{m}) * 100;
    hussChg85Prc = hussChg85 / nanmean(hussHistorical{m}) * 100;
    
    tempChg45Data(end+1) = tempChg45Prc;
    tempChg85Data(end+1) = tempChg85Prc;
    
    hussChg45Data(end+1) = hussChg45Prc;
    hussChg85Data(end+1) = hussChg85Prc;
    
    plot(hussChg45Prc, tempChg45Prc, 'ob', 'LineWidth', 1);
    plot(hussChg85Prc, tempChg85Prc, 'or', 'LineWidth', 1);
    
end

p1 = plot(nanmean(hussChg45Data), nanmean(tempChg45Data), 'ob', 'LineWidth', 6);
p2 = plot(nanmean(hussChg85Data), nanmean(tempChg85Data), 'or', 'LineWidth', 6);

xlim([0 30]);
ylim([0 30]);
xlabel('Percent change in specific humidity', 'FontSize', 26);
ylabel('Percent change in temperature', 'FontSize', 26);
title('U.S. Southeast', 'FontSize', 30);
set(gca, 'FontSize', 24);
legend([p1, p2], 'RCP4.5 average', 'RCP8.5 average');

