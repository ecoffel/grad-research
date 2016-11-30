regions = {'us-ne', 'india', 'china', 'west-africa'};
regionTitles = {'U.S. Southeast', 'India', 'China', 'West Africa'};

figure('Color', [1,1,1]);

for r = 1:length(regions)
    sp = subplot(2, 2, r);
    hold on;
    
    region = regions{r};
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

    tempPrcChg45Data = [];
    tempPrcChg85Data = [];
    hussPrcChg45Data = [];
    hussPrcChg85Data = [];

    tempChg45Data = [];
    tempChg85Data = [];
    hussChg45Data = [];
    hussChg85Data = [];

    rcp45Color = [85/255.0, 158/255.0, 237/255.0];
    rcp85Color = [237/255.0, 92/255.0, 85/255.0];

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

        tempPrcChg45Data(end+1) = tempChg45Prc;
        tempPrcChg85Data(end+1) = tempChg85Prc;

        hussPrcChg45Data(end+1) = hussChg45Prc;
        hussPrcChg85Data(end+1) = hussChg85Prc;

        tempChg45Data(end+1) = tempChg45;
        tempChg85Data(end+1) = tempChg85;

        hussChg45Data(end+1) = hussChg45;
        hussChg85Data(end+1) = hussChg85;

        p1 = plot(hussChg45Prc, tempChg45, 'o', 'LineWidth', 3);
        set(p1, 'MarkerSize', 13, 'MarkerEdgeColor', rcp45Color);
        p2 = plot(hussChg85Prc, tempChg85, 'o', 'LineWidth', 3);
        set(p2, 'MarkerSize', 13, 'MarkerEdgeColor', rcp85Color);

    end

    p1 = plot(sp, nanmean(hussPrcChg45Data), nanmean(tempChg45Data), 'ob', 'LineWidth', 2);
    set(p1, 'MarkerSize', 18, 'MarkerFaceColor', rcp45Color, 'MarkerEdgeColor', 'k');
    p2 = plot(sp, nanmean(hussPrcChg85Data), nanmean(tempChg85Data), 'or', 'LineWidth', 2);
    set(p2, 'MarkerSize', 18, 'MarkerFaceColor', rcp85Color, 'MarkerEdgeColor', 'k');

    xlim([0 30]);
    ylim([0 10]);
    xlabel('Specific humidity', 'FontSize', 26);
    ylabel('Temperature', 'FontSize', 26);
    title(regionTitles{r}, 'FontSize', 40);
    set(gca, 'FontSize', 26);
    %legend([p1, p2], 'RCP4.5 average', 'RCP8.5 average');
end

