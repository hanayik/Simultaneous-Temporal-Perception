clear all;
clc;
A = simpleStair('create', 'initialVal', 0.1, 'minVal', 0.01, 'maxVal', 0.8, 'stepSize', 0.01, 'targetAcc', 0.7, 'name', 'CL');
n = 40;
r = randperm(n);
t = repmat([0 1], 1, n/2);
t = t(r);
noise = 1.1;
for i = 1:n
    threshold = A.stimulusVal;
    perceived = threshold+((rand()-0.3)*noise);
    acc = perceived > threshold;
    A = simpleStair('update', 'data', A, 'accuracy', acc);
end