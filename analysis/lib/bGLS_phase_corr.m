function [alphas, st, sm, logp] = bGLS_phase_corr(...
                ITI, asynchronies, mean_asynchrony, mean_ITI)
% This function computes the bGLS for cases without significant tempo
% changes - based on Nori Jacoby's bGLS toolbox (2015), adapted by Gal
% Vishne (2019-2021) to deal with missing or excluded values Missing \
% excluded taps are nan in As and R (both the interval after and the
% interval before) then we simply erase the relevant rows and columns in
% the covariance matrix of the noise - so all relevant connections between
% variables are just part of the unmodelled noise.
%
% For more information about the method see:
% Jacoby, Tishby, Repp, Ahissar and Keller (2015)
% and Vishne, Jacoby et al. (2021)
% Please cite if you use this code
%
% Let OR(t) be the response onset at time t
% Let OS(t) be the stimulus onset at time t
% Let R(t) be the interesponse interval R(t)=OR(t)-OR(t-1)
% 
% Note that R is is slightly diffrent than the notation of 
% Vorberg and Shultze 2002 where:
% I(t)=OR(t+1)-OR(t)=R(t+1)
% 
% The empirical means should be computed outside.
% 
% CODE BY: Nori Jacoby (nori.viola@gmail.com) & Gal Vishne (gal.vishne@gmail.com)
% Additional comments and formatting added by Tomas Lenc (tomas.lenc@gmail.com)

ITER = 20; % set parameters

TRESH = 1e-3; %this is the maximal difference between old solution and new solution. 
% in the iteration if we get a change smaller than TRESH we simply stop (we
% obtaine a local maximum).

N = size(ITI,1)-1; % number of datapoints
P = size(asynchronies,2);  % number of partners

assert(size(ITI,1)==size(asynchronies,1));
assert(size(mean_asynchrony,2)==P);
assert(size(mean_asynchrony,1)==1);

% subtract mean for each partner
for p=1:P
    asynchronies(:,p) = asynchronies(:,p)-mean_asynchrony(p);
end

% prepare data
b3 = ITI(2:end)-mean_ITI;
A3 = [asynchronies(1:(end-1),:)];
    
% make sure we'll remove any data with NaNs
missing_inds = isnan(b3) | isnan(A3);
b3(missing_inds)=[];
A3(missing_inds)=[];

% init acvf
K11=1;
K12=0;

zold = zeros(P,1)-9999; %init to invalid value

% do the BGLS iterations
for iter=1:ITER
    
        CC = diag(K11*ones(1,N),0) + ...
             diag(K12*ones(1,N-1),1) + ...
             diag(K12*ones(1,N-1),-1);
        
        CC(missing_inds,:)=[];
        CC(:,missing_inds)=[]; % this is the whole change with missing values
        
        iC = inv(CC);
        z = inv((A3')*iC*A3) * ((A3')*iC*b3); % compute GLS
        
        d = A3*z - b3; % compute residual noise
        
        K=cov(d(1:(end-1)),d(2:end));    %estimate residual acvf
        K11=(K(1,1)+K(2,2))/2;
        K12=K(1,2);

        % apply bound
        if K12>0
            K12=0;
        end
        if K11<(-3*K12)
            K11=(-3*K12);
        end
       
        % if allready obtain local maxima there is no point to continue...
        if (sum(abs(z-zold))<TRESH)
            break;
        end
        zold = z;
        
end % end of bGLS iterations.

% output variables
% ----------------

% phase correction (alpha)
alphas = -z';

% motor noise
sm = sqrt(-K12);

% timekeeper noise
st = sqrt(K11-2*(sm^2));
    
% log likelihood
d = d';
const = -0.5 * length(d) * log(2*pi);
term1 = -0.5 * sum((d / CC) .* d, 2); % N x 1
term2 = const - sum(log(diag(chol(CC))));    % scalar
logp = term1' + term2;
