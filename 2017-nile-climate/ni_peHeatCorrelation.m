load 2017-nile-climate/output/pe-ncep-reanalysis.mat;

pe1 = squeeze(nanmean(nanmean(peSeasonal{1},2),1));
pe2 = squeeze(nanmean(nanmean(peSeasonal{2},2),1));
pe3 = squeeze(nanmean(nanmean(peSeasonal{3},2),1));
pe4 = squeeze(nanmean(nanmean(peSeasonal{4},2),1));

figure('Color',[1,1,1]);
hold on;
p1=plot(pe1);
if Mann_Kendall(pe1,0.05)
    f=fit((1:length(pe1))',pe1,'poly1');
    plot(1:length(pe1),f(1:length(pe1)),'--');
end

p2=plot(pe2);
if Mann_Kendall(pe2,0.05)
    f=fit((1:length(pe2))',pe2,'poly1');
    plot(1:length(pe2),f(1:length(pe2)),'--');
end

p3=plot(pe3);
if Mann_Kendall(pe3,0.05)
    f=fit((1:length(pe3))',pe3,'poly1');
    plot(1:length(pe3),f(1:length(pe3)),'--');
end

p4=plot(pe4);
if Mann_Kendall(pe4,0.05)
    f=fit((1:length(pe4))',pe4,'poly1');
    plot(1:length(pe4),f(1:length(pe4)),'--');
end
legend([p1 p2 p3 p4], {'DJF','MAM','JJA','SON'})