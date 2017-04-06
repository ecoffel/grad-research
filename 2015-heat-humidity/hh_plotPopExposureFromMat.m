function plotPopExposureFromMat(saveData)

    figure('Color', [1, 1, 1]);
    hold on;
    grid on;
    axis square;
    box on;

    [B, E] = barwitherr(saveData.futureDecYerr, saveData.futureDecX, saveData.futureDecY, 'LineWidth', 1, 'BarWidth', 1);

    set(B(1), 'FaceColor', [0.122, 0.467, 0.706]);
    set(E(1), 'Color', [0.1, 0.1, 0.1]);
    set(E(1), 'LineWidth', 2);

    set(B(2), 'FaceColor', [1, 0.5, 0.055]);
    set(E(2), 'Color', [0.1, 0.1, 0.1]);
    set(E(2), 'LineWidth', 2);

    set(B(3), 'FaceColor', [0.173, 0.627, 0.173]);
    set(E(3), 'Color', [0.1, 0.1, 0.1]);
    set(E(3), 'LineWidth', 2);

    set(B(4), 'FaceColor', [0.839, 0.153, 0.157]);
    set(E(4), 'Color', [0.1, 0.1, 0.1]);
    set(E(4), 'LineWidth', 2);

    %title(saveData.plotTitle, 'FontSize', 24);
    xlabel(saveData.Xlabel, 'FontSize', 24);
    ylabel(saveData.Ylabel, 'FontSize', 24);
    set(gca, 'FontSize', 24);
    set(gcf, 'Position', get(0,'Screensize'));

    l = legend(B, 'Population effect', 'Climate effect', 'Interaction effect', 'Total exposure');
    set(l, 'FontSize', 24, 'Location', 'best');

    ylim([0, inf]);

    %eval(['export_fig ' saveData.fileTitle '.' saveData.exportFormat ' -m2;']);
    %save([saveData.fileTitle '.mat'], 'saveData');
    %close all;

end