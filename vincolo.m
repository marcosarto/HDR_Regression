function [c, ceq]=vincolo(y)

%global hsol;
%tol = 10^(-2);
%global kurtotemp;
global summax;
global x0;

%c = [-kurtosis(y)+hsol-tol kurtosis(y)-hsol-tol];
c = sum(abs(y-x0))-summax;
ceq = [];%kurtosis(y)-hsol;

% norm(x0-y)
