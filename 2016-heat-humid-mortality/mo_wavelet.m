load nyMergedMortData
addpath('2016-heat-humid-mortality/wave_matlab');

deaths = mortData{2}(:,5);
wbMin = mortData{2}(:,11);
wbMax = mortData{2}(:,12);
wbMean = mortData{2}(:,13);
tMin = mortData{2}(:,14);
tMax = mortData{2}(:,15);
tMean = mortData{2}(:,16);

% remove linear trend and mean
deathsDetrend = detrend(deaths - nanmean(deaths));

% moving average
deathsMovAvg = tsmovavg(deaths, 's', 30, 1);

data = deaths-deathsMovAvg;

time = 1:length(data);
variance = std(data)^2;
dt = time(2)-time(1);

djs = [0.25];               % this will do 4 sub-octaves per octave
s0s = [2*dt];               % this says start at a scale of 6 months
j1s = [8];                  % this says do 7 powers-of-two with dj sub-octaves each
lag1s = [0.75];             % lag-1 autocorrelation for red noise background

for dj = djs
    for s0 = s0s
        for j1cur = j1s
            for lag1 = lag1s
                j1 = round(j1cur/dj);
                n = length(deaths);
                xlim = [time(1), time(end)];                    % plotting range
                pad = 1;                                        % pad the time series with zeroes (recommended)                            
                mother = 'Morlet';

                % Wavelet transform:
                [wave, period, scale, coi] = wavelet(data, dt, pad, dj, s0, j1, mother);
                power = (abs(wave)).^2 ;        % compute wavelet power spectrum


                % % Significance levels: (variance=1 for the normalized SST)
                [signif, fft_theor] = wave_signif(1.0, dt, scale, 0, lag1, -1, -1, mother);
                
                % expand signif --> (J+1)x(N) array
                sig95 = (signif')*(ones(1,n));  
                
                % where ratio > 1, power is significant
                sig95 = power ./ sig95;         


                % % Global wavelet spectrum & significance levels:
                global_ws = variance*(sum(power')/n);   % time-average over all times
                dof = n - scale;  % the -scale corrects for padding at edges
                global_signif = wave_signif(variance,dt,scale,1,lag1,-1,dof,mother);


                % % Scale-average between El Nino periods of 2--8 years
                avg = find((scale >= 2) & (scale < 8));
                Cdelta = 0.776;   % this is for the MORLET wavelet
                scale_avg = (scale')*(ones(1,n));  % expand scale --> (J+1)x(N) array
                scale_avg = power ./ scale_avg;   % [Eqn(24)]
                scale_avg = variance*dj*dt/Cdelta*sum(scale_avg(avg,:));   % [Eqn(24)]
                scaleavg_signif = wave_signif(variance,dt,scale,2,lag1,-1,[2,7.9],mother);


                %--- Plot time series
                subplot(2, 1, 1)
                plot(time, data)
                set(gca,'XLim',xlim(:))
                xlabel('Time (days)', 'FontSize', 20)
                ylabel('Deaths/day', 'FontSize', 20)
                title('NYC deaths (detrended anomalies)', 'FontSize', 24)
                hold off

                %--- Contour plot wavelet power spectrum
                subplot(2, 1, 2)
                levels = [0.0625,0.125,0.25,0.5,1,2,4,8,16];
                Yticks = 2.^(fix(log2(min(period))):fix(log2(max(period))));
                contour(time,log2(period),log2(power),log2(levels));  %*** or use 'contourfill'
                %imagesc(time,log2(period),log2(power));  %*** uncomment for 'image' plot
                xlabel('Time (days)', 'FontSize', 20);
                ylabel('Period (days)', 'FontSize', 20);
                title('NYC deaths wavelet power spectrum', 'FontSize', 24)
                set(gca,'XLim',xlim(:))
                set(gca,'YLim',log2([min(period),max(period)]), ...
                    'YDir','reverse', ...
                    'YTick',log2(Yticks(:)), ...
                    'YTickLabel',Yticks)


                % % 95% significance contour, levels at -99 (fake) and 1 (95% signif)
                hold on
                contour(time,log2(period),sig95,[-99,1],'k');
                hold on
                % cone-of-influence, anything "below" is dubious
                plot(time,log2(coi),'k')
                hold off

                %eval(['export_fig ' filename '.png']);
            end
        end
    end
end

