function logitTest

startVal = 0.7;
maxVal = 1;
minVal = 0;
standard = 0.5;

n = 30;
nextVal = startVal;
%pad with zeors and ones
prevVals = [];
prevAcc = [];
for i = 1:n
    [perceived, acc] = simulateResp(nextVal);
    if i > 1
        [nextVal, prevVals, prevAcc, b, nobs] = logitMethod(prevVals, prevAcc, perceived, acc);
    else
        prevVals = [prevVals; nextVal];
        prevAcc = [prevAcc; acc];
    end
end
yfit = glmval(b, prevVals,'logit');
save_to_base(1)
[sortPrevVals, I] = sort(prevVals);
plot(sortPrevVals, prevAcc(I)./nobs,'o',sortPrevVals,yfit(I)./nobs,'-','LineWidth',2)

end

% Hours	=[0.50	0.75	1.00	1.25	1.50	1.75	1.75	2.00	2.25	2.50	2.75	3.00	3.25	3.50	4.00	4.25	4.50	4.75	5.00	5.50]
% Pass	=[0	0	0	0	0	0	1	0	1	0	1	0	1	0	1	1	1	1	1	1]
% Hours = Hours';
% Pass= Pass';
% n = ones(size(Pass));
% b = glmfit(Hours,[Pass n],'binomial','link','logit');
% yfit = glmval(b,2,'logit');
% plot(Hours, Pass./n,'o',Hours,yfit./n,'-','LineWidth',2)
% yfit = glmval(b,Hours,'logit');
% plot(Hours, Pass./n,'o',Hours,yfit./n,'-','LineWidth',2)
% p = 0.7;
% h = (log(p/(1-p)) + b(1))/b(2)
% h = (log(p/(1-p)) + abs(b(1)))/b(2)

function [nextVal, prevVals, prevAcc, b, n] = logitMethod(prevVals, prevAcc, inVal, inAcc)
p = 0.7;
maxVal = 1;
minVal = 0;
if size(prevVals,1) == 1
    x = prevVals'; %make column vector
    y = prevAcc'; %make column vector
else
    x = prevVals;
    y = prevAcc;
end
n = ones(size(y));
size(y)

b = glmfit(x, [y, n], 'binomial', 'link', 'logit');
predictedY = glmval(b, inVal,'logit');
nextVal = (log(p/(1-p)) + abs(b(1)))/b(2);
if nextVal > maxVal
    nextVal = 1;
end
if nextVal < minVal
    nextVal = 0;
end
prevVals = [x; nextVal];
prevAcc = [y; inAcc];
n = ones(size(prevAcc));
end


function [perceived, accuracy] = simulateResp(threshold,noise)
if nargin < 2
    noise = 1.1;
end
p = 0.7;
perceived = threshold+((rand()-(1-p))*noise);
accuracy = perceived > threshold;
end %simulateResp