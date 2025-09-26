% SNR_count.m
% custom code used in section 3.20
% calculates SNR of in vivo elphys data

%% Counting SNR from 10 weeks


load('data_10weeks.mat');
load('t.mat'); % time scale
load('T_1.mat'); % time scale for 1st measurement 

%% Lecomte et al. method
% SNR = A/ 2*SDnoise
% A: peak-to-peak V of mean waveform
% noise: raw-filtered data with 200 Hz low-pass

%  immobile periods 
% rest_times = [75, 232, 55, 155, 165, 143, 175, 60, 0, 95]; % X548
rest_times = [90, 105, 60, 140, 10, 160, 230, 10, 160, 15]; % X549
% rest_times = [50, 140, 160, 200, 70, 170, 10, 255, 170, 150]; % X550


jel = []; % signal
jel2 = []; % signal2
zaj = []; % noise
R = [];
% jel_zaj = []; % signal_noise

%fc/(fs/2)
[b1, a1] = butter(5,0.14,'low'); % 200 Hz lowpass - 0.2 /  11Hz - 0.0110
[b2, a2] = butter(3,0.0035,'high'); % 1 Hz highpass - 1.e-03 / 3.5Hz - 0.0035


t_signal = t{1,1};
% rep_x = [];
% rep_y = [];
for ch = [1,2,3,5,7,8,9,11,12,13,14,15,17,19,21,23,28,29,30] % channels
    % 1st measurement (different timescale) 
    if ch ==1
        t_signal = T_1{1,1};
    else
        t_signal = t{1,1};
    end
    
    
    
    for i= 1:10 % weeks
        % ms conversion, adding 30 seconds 
        idx =(t_signal >= rest_times(i)*1000) & (t_signal <= (rest_times(i)+30)*1000);
        
        x = t_signal(idx);
        y = data{i,ch}(idx);
        y1= filter(b1,a1,y);
        y2= filter(b2,a2,y1);
%         
%         if i == 5 && ch == 28
%             figure;
%             plot(x,y2,'LineWidth',1.5);
%             rep_x = x;
%             rep_y = y2;
%         end
        noise = y-y2;
        
        ptp = dsp.PeakToPeak;
        jel(ch,i) = ptp(y2);
        jel2(ch,i) = peak2peak(y2);
        zaj(ch,i) = std(noise);
        R(ch,i) = snr(jel(ch,i),zaj(ch,i));
        %         p = pspectrum(y2);
        %         mu = mean(p);
        %         sigma = std(p);
        %         jel_zaj(ch,i) = 10*log10(mu^2 / sigma^2);
    end
    
end
%jel( all(~jel,2), : ) = [];
%zaj( all(~zaj,2), : ) = [];
SNR = jel./(2.*zaj);

%% 1-200 Hz signal and 3.5-11 Hz theta 
rx = rep_x(find(rep_x == 32000) : find(rep_x == 34000));
ry = rep_y(find(rep_x == 32000) : find(rep_x == 34000))

tx = theta_x(find(theta_x == 32000) : find(theta_x == 34000));
ty = theta_y(find(theta_x == 32000) : find(theta_x == 34000));

gx = gamma_x(find(gamma_x == 32000) : find(gamma_x == 34000));
gy = gamma_y(find(gamma_x == 32000) : find(gamma_x == 34000));

figure; 
plot(rx, ry + 400, 'k', 'LineWidth',1.5);
hold on;
plot(tx, ty , 'k', 'LineWidth',2);
plot(gx, gy -200, 'k','LineWidth',1.5);
axis off