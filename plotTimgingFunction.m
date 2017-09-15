function plotTimgingFunction(SOA)

b1 = 0.25;
nframes = 30;
for f = 1:nframes
    nfdiv2 = nframes/2;
    if f <= nfdiv2
        bias1(f) = getBias(f/(nfdiv2),b1);
        bias2(f) = getBias(f/(nfdiv2),SOA);
    else
        bias1(f) = 1 - getBias((f - ceil(nfdiv2))/(nfdiv2),b1);
        bias2(f) = 1 - getBias((f - ceil(nfdiv2))/(nfdiv2),SOA);
    end
    
end
figure;
plot(bias1, '-r');
hold on;
plot(bias2, '-b');
hold off;

function bias = getBias(t, b)
%credit: http://demofox.org/biasgain.html
if (b <= 0) | (t <= 0), bias = 0; return; end; %#ok
if (b >= 1) | (t >= 1), bias = 1; return; end; %#ok
bias = (t / ((((1.0/b) - 2.0)*(1.0 - t))+1.0));
% (time / ((((1.0/bias) - 2.0)*(1.0 - time))+1.0));
