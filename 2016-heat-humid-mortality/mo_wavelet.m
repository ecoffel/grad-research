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

data = deaths;

time = 1:length(data);
variance = std(data)^2;
dt = time(2)-time(1);

djs = [0.25];               % this will do 4 sub-octaves per octave
s0s = [2*dt];               % this says start at a scale of 6 months
j1s = [8];                  % this says do 7 powers-of-two with dj sub-octaves each
lag1s = [0.75];             % lag-1 autocorrelation for red noise background

figure('Color', [1, 1, 1]);

for dj = djs
    for s0 = s0s
        for j1cur = j1s
            for lag1 = lag1s
                j1 = round(j1cur/dj);
                n = length(deaths);
                
                pad = 1;                                        % pad the time series with zeroes (recommended)                            
                mother = 'Dog';

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

                xAxis = linspace(1987, 2001, length(time));
                xlim = [xAxis(1), xAxis(end)];                    % plotting range
                
                %--- Plot time series
                subplot(2, 1, 1)
                hold on;
                plot(xAxis, data)
                plot(xAxis, deathsMovAvg, 'r', 'LineWidth', 2);
                set(gca,'XLim',xlim(:), 'FontSize', 20)
                xlabel('Year', 'FontSize', 24)
                ylabel('Deaths/day', 'FontSize', 24)
                title('NYC deaths', 'FontSize', 30)
                legend('Daily mortality', '30-day moving average');
                hold off

                %--- Contour plot wavelet power spectrum
                subplot(2, 1, 2)
                hold on;
                levels = [0.0625,0.125,0.25,0.5,1,2,4,8,16];
                Yticks = 2.^(fix(log2(min(period))):fix(log2(max(period))));
                contour(xAxis,log2(period),log2(power),log2(levels));  %*** or use 'contourfill'
                %imagesc(time,log2(period),log2(power));  %*** uncomment for 'image' plot
                xlabel('Year', 'FontSize', 24);
                ylabel('Period (days)', 'FontSize', 24);
                title('NYC deaths wavelet power spectrum', 'FontSize', 30)
                set(gca,'XLim',xlim(:))
                set(gca,'YLim',log2([min(period),max(period)]), ...
                    'YDir','reverse', ...
                    'YTick',log2(Yticks(:)), ...
                    'YTickLabel',Yticks, ...
                    'FontSize', 20)


                % % 95% significance contour, levels at -99 (fake) and 1 (95% signif)
                hold on
                contour(xAxis,log2(period),sig95,[-99,1],'k');
                hold on
                % cone-of-influence, anything "below" is dubious
                plot(xAxis,log2(coi),'k')
                hold off

                %eval(['export_fig ' filename '.png']);
            end
        end
    end
end

