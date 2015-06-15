compType = 'narccap-sw-past-future-winter';

if strcmp(compType, 'narccap-ne-past-future-summer')
    load tempProfile-airmax-narccap-summer-ext-2051-2069-narccap-1981-1998-ne;
    saveDataExt = saveData;
    load tempProfile-airmax-narccap-summer-mean-2051-2069-narccap-1981-1998-ne;
    saveDataMean = saveData;

    plotTitle = ['NARCCAP NE summer temperature profile change'];
    Xlabel = 'Temperature (degrees C)';
    Ylabel = 'Pressure (hPa)';

    figure('Color', [1, 1, 1]);
    hold on;
    axis square;
    set(gca, 'FontSize', 24);
    set(gca,'YDir','reverse');
    hAxExt = plot(saveDataExt.dataY, saveDataExt.dataX, 'r', 'LineWidth', 2);
    hAxMean = plot(saveDataMean.dataY, saveDataMean.dataX, 'b', 'LineWidth', 2);

    xlim([0 5]);

    title(plotTitle, 'FontSize', 24);
    xlabel(Xlabel, 'FontSize', 24);
    ylabel(Ylabel, 'FontSize', 24);

    set(gcf, 'Position', get(0,'Screensize'));
    eval(['export_fig tempProfile-airmax-narccap-summer-prof-chg-2051-2069-narccap-1981-1998-ne.pdf;']);
    close all;
elseif strcmp(compType, 'narccap-ne-past-future-winter')
    load tempProfile-airmin-narccap-winter-ext-2051-2069-narccap-1981-1998-ne;
    saveDataExt = saveData;
    load tempProfile-airmin-narccap-winter-mean-2051-2069-narccap-1981-1998-ne;
    saveDataMean = saveData;

    plotTitle = ['NARCCAP NE winter temperature profile change'];
    Xlabel = 'Temperature (degrees C)';
    Ylabel = 'Pressure (hPa)';

    figure('Color', [1, 1, 1]);
    hold on;
    axis square;
    set(gca, 'FontSize', 24);
    set(gca,'YDir','reverse');
    hAxExt = plot(saveDataExt.dataY, saveDataExt.dataX, 'r', 'LineWidth', 2);
    hAxMean = plot(saveDataMean.dataY, saveDataMean.dataX, 'b', 'LineWidth', 2);

    xlim([0 5]);

    title(plotTitle, 'FontSize', 24);
    xlabel(Xlabel, 'FontSize', 24);
    ylabel(Ylabel, 'FontSize', 24);

    set(gcf, 'Position', get(0,'Screensize'));
    eval(['export_fig tempProfile-airmin-narccap-winter-prof-chg-2051-2069-narccap-1981-1998-ne.pdf;']);
    close all;
elseif strcmp(compType, 'narccap-sw-past-future-summer')
    load tempProfile-airmax-narccap-summer-ext-2051-2069-narccap-1981-1998-sw;
    saveDataExt = saveData;
    load tempProfile-airmax-narccap-summer-mean-2051-2069-narccap-1981-1998-sw;
    saveDataMean = saveData;

    plotTitle = ['NARCCAP SW summer temperature profile change'];
    Xlabel = 'Temperature (degrees C)';
    Ylabel = 'Pressure (hPa)';

    figure('Color', [1, 1, 1]);
    hold on;
    axis square;
    set(gca, 'FontSize', 24);
    set(gca,'YDir','reverse');
    hAxExt = plot(saveDataExt.dataY, saveDataExt.dataX, 'r', 'LineWidth', 2);
    hAxMean = plot(saveDataMean.dataY, saveDataMean.dataX, 'b', 'LineWidth', 2);

    xlim([0 5]);

    title(plotTitle, 'FontSize', 24);
    xlabel(Xlabel, 'FontSize', 24);
    ylabel(Ylabel, 'FontSize', 24);

    set(gcf, 'Position', get(0,'Screensize'));
    eval(['export_fig tempProfile-airmax-narccap-summer-prof-chg-2051-2069-narccap-1981-1998-sw.pdf;']);
    close all;
elseif strcmp(compType, 'narccap-sw-past-future-winter')
    load tempProfile-airmin-narccap-winter-ext-2051-2069-narccap-1981-1998-sw;
    saveDataExt = saveData;
    load tempProfile-airmin-narccap-winter-mean-2051-2069-narccap-1981-1998-sw;
    saveDataMean = saveData;

    plotTitle = ['NARCCAP SW winter temperature profile change'];
    Xlabel = 'Temperature (degrees C)';
    Ylabel = 'Pressure (hPa)';

    figure('Color', [1, 1, 1]);
    hold on;
    axis square;
    set(gca, 'FontSize', 24);
    set(gca,'YDir','reverse');
    hAxExt = plot(saveDataExt.dataY, saveDataExt.dataX, 'r', 'LineWidth', 2);
    hAxMean = plot(saveDataMean.dataY, saveDataMean.dataX, 'b', 'LineWidth', 2);

    xlim([0 5]);

    title(plotTitle, 'FontSize', 24);
    xlabel(Xlabel, 'FontSize', 24);
    ylabel(Ylabel, 'FontSize', 24);

    set(gcf, 'Position', get(0,'Screensize'));
    eval(['export_fig tempProfile-airmin-narccap-winter-prof-chg-2051-2069-narccap-1981-1998-sw.pdf;']);
    close all;
elseif strcmp(compType, 'ne-base-summer')
    load tempProfile-airmax-summer-ext-narccap-1981-1998-ne;
    narccapExt = saveData;
    load tempProfile-airmax-summer-mean-narccap-1981-1998-ne;
    narccapMean = saveData;
    load tempProfile-airmax-summer-mean-narr-1981-1998-ne;
    narrMean = saveData;
    load tempProfile-airmax-summer-ext-narr-1981-1998-ne;
    narrExt = saveData;
    
    plotTitle = ['NARR/NARCCAP NE summer temperature profile'];
    Xlabel = 'Temperature (degrees C)';
    Ylabel = 'Pressure (hPa)';

    figure('Color', [1, 1, 1]);
    hold on;
    axis square;
    set(gca, 'FontSize', 24);
    set(gca,'YDir','reverse');
    hAxNarrExt = plot(narrExt.dataY, narrExt.dataX, 'r', 'LineWidth', 2);
    hAxNarrMean = plot(narrMean.dataY, narrMean.dataX, 'b', 'LineWidth', 2);
    
    hAxNarccapExt = plot(narccapExt.dataY, narccapExt.dataX, '-.r', 'LineWidth', 2);
    hAxNarccapMean = plot(narccapMean.dataY, narccapMean.dataX, '-.b', 'LineWidth', 2);

    xlim([-50 50]);

    title(plotTitle, 'FontSize', 24);
    xlabel(Xlabel, 'FontSize', 24);
    ylabel(Ylabel, 'FontSize', 24);
    
    legend('narr extreme', 'narr mean', 'narccap extreme', 'narccap mean');

    set(gcf, 'Position', get(0,'Screensize'));
    eval(['export_fig tempProfile-airmax-narccap-narr-summer-prof-1981-1998-ne.pdf;']);
    close all;
elseif strcmp(compType, 'ne-base-winter')
    load tempProfile-airmin-winter-ext-narccap-1981-1998-ne;
    narccapExt = saveData;
    load tempProfile-airmin-winter-mean-narccap-1981-1998-ne;
    narccapMean = saveData;
    load tempProfile-airmin-winter-mean-narr-1981-1998-ne;
    narrMean = saveData;
    load tempProfile-airmin-winter-ext-narr-1981-1998-ne;
    narrExt = saveData;
    
    plotTitle = ['NARR/NARCCAP NE winter temperature profile'];
    Xlabel = 'Temperature (degrees C)';
    Ylabel = 'Pressure (hPa)';

    figure('Color', [1, 1, 1]);
    hold on;
    axis square;
    set(gca, 'FontSize', 24);
    set(gca,'YDir','reverse');
    hAxNarrExt = plot(narrExt.dataY, narrExt.dataX, 'r', 'LineWidth', 2);
    hAxNarrMean = plot(narrMean.dataY, narrMean.dataX, 'b', 'LineWidth', 2);
    
    hAxNarccapExt = plot(narccapExt.dataY, narccapExt.dataX, '-.r', 'LineWidth', 2);
    hAxNarccapMean = plot(narccapMean.dataY, narccapMean.dataX, '-.b', 'LineWidth', 2);

    xlim([-50 50]);

    title(plotTitle, 'FontSize', 24);
    xlabel(Xlabel, 'FontSize', 24);
    ylabel(Ylabel, 'FontSize', 24);
    
    legend('narr extreme', 'narr mean', 'narccap extreme', 'narccap mean');

    set(gcf, 'Position', get(0,'Screensize'));
    eval(['export_fig tempProfile-airmin-narccap-narr-winter-prof-1981-1998-ne.pdf;']);
    close all;
elseif strcmp(compType, 'sw-base-summer')
    load tempProfile-airmax-summer-ext-narccap-1981-1998-sw;
    narccapExt = saveData;
    load tempProfile-airmax-summer-mean-narccap-1981-1998-sw;
    narccapMean = saveData;
    load tempProfile-airmax-summer-mean-narr-1981-1998-sw;
    narrMean = saveData;
    load tempProfile-airmax-summer-ext-narr-1981-1998-sw;
    narrExt = saveData;
    
    plotTitle = ['NARR/NARCCAP SW summer temperature profile'];
    Xlabel = 'Temperature (degrees C)';
    Ylabel = 'Pressure (hPa)';

    figure('Color', [1, 1, 1]);
    hold on;
    axis square;
    set(gca, 'FontSize', 24);
    set(gca,'YDir','reverse');
    hAxNarrExt = plot(narrExt.dataY, narrExt.dataX, 'r', 'LineWidth', 2);
    hAxNarrMean = plot(narrMean.dataY, narrMean.dataX, 'b', 'LineWidth', 2);
    
    hAxNarccapExt = plot(narccapExt.dataY, narccapExt.dataX, '-.r', 'LineWidth', 2);
    hAxNarccapMean = plot(narccapMean.dataY, narccapMean.dataX, '-.b', 'LineWidth', 2);

    xlim([-50 50]);

    title(plotTitle, 'FontSize', 24);
    xlabel(Xlabel, 'FontSize', 24);
    ylabel(Ylabel, 'FontSize', 24);
    
    legend('narr extreme', 'narr mean', 'narccap extreme', 'narccap mean');

    set(gcf, 'Position', get(0,'Screensize'));
    eval(['export_fig tempProfile-airmax-narccap-narr-summer-prof-1981-1998-sw.pdf;']);
    close all;
elseif strcmp(compType, 'sw-base-winter')
    load tempProfile-airmin-winter-ext-narccap-1981-1998-sw;
    narccapExt = saveData;
    load tempProfile-airmin-winter-mean-narccap-1981-1998-sw;
    narccapMean = saveData;
    load tempProfile-airmin-winter-mean-narr-1981-1998-sw;
    narrMean = saveData;
    load tempProfile-airmin-winter-ext-narr-1981-1998-sw;
    narrExt = saveData;
    
    plotTitle = ['NARR/NARCCAP SW winter temperature profile'];
    Xlabel = 'Temperature (degrees C)';
    Ylabel = 'Pressure (hPa)';

    figure('Color', [1, 1, 1]);
    hold on;
    axis square;
    set(gca, 'FontSize', 24);
    set(gca,'YDir','reverse');
    hAxNarrExt = plot(narrExt.dataY, narrExt.dataX, 'r', 'LineWidth', 2);
    hAxNarrMean = plot(narrMean.dataY, narrMean.dataX, 'b', 'LineWidth', 2);
    
    hAxNarccapExt = plot(narccapExt.dataY, narccapExt.dataX, '-.r', 'LineWidth', 2);
    hAxNarccapMean = plot(narccapMean.dataY, narccapMean.dataX, '-.b', 'LineWidth', 2);

    xlim([-50 50]);

    title(plotTitle, 'FontSize', 24);
    xlabel(Xlabel, 'FontSize', 24);
    ylabel(Ylabel, 'FontSize', 24);
    
    legend('narr extreme', 'narr mean', 'narccap extreme', 'narccap mean');

    set(gcf, 'Position', get(0,'Screensize'));
    eval(['export_fig tempProfile-airmin-narccap-narr-winter-prof-1981-1998-sw.pdf;']);
    close all;
end

