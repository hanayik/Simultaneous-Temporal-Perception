% Hours	=[0.50	0.75	1.00	1.25	1.50	1.75	1.75	2.00	2.25	2.50	2.75	3.00	3.25	3.50	4.00	4.25	4.50	4.75	5.00	5.50];
% Pass	=[0	0	0	0	0	0	1	0	1	0	1	0	1	0	1	1	1	1	1	1];
% Hours = Hours';
% Pass= Pass';
% n = ones(size(Pass));
% b = glmfit(Hours,[Pass n],'binomial','link','logit');
% yfit = glmval(b,Hours,'logit');
% plot(Hours, Pass./n,'o',Hours,yfit./n,'-','LineWidth',2)
% p = 0.7;
% h = (log(p/(1-p)) + b(1))/b(2)
% h = (log(p/(1-p)) + abs(b(1)))/b(2)






nodetect = normrnd(0.4, 0.1,10,1);
detect = normrnd(0.2, 0.1,10,1);
acc = [zeros(size(nodetect)); ones(size(detect))];
stimVals = [nodetect; detect];
n = ones(size(acc));
b = glmfit(stimVals,[acc n],'binomial','link','logit');
yfit = glmval(b,stimVals,'logit');
[yfits, I] = sort(yfit);
plot(stimVals(I), acc(I)./n,'o',stimVals(I),yfits./n,'-','LineWidth',2)



cf = 1000;                  % carrier frequency (Hz)
sf = 44100;                 % sample frequency (Hz)
d = 1.0;                    % duration (s)
n = sf * d;                 % number of samples
s = (1:n) / sf;             % sound data preparation
s = sin(2 * pi * cf * s);   % sinusoidal modulation
%sound(s, sf);               % sound presentation
%pause(d + 0.5);             % waiting for sound end


cf2 = 1200;
sf = 44100;                 % sample frequency (Hz)
d = 1.0;                    % duration (s)
n = sf * d;                 % number of samples
s2 = (1:n) / sf;             % sound data preparation
s2 = sin(2 * pi * cf2 * s2);   % sinusoidal modulation

sound2Chan = [s;s2];

sound(sound2Chan, sf);
pause(d + 0.5);
