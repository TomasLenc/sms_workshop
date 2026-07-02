function tap_times = simulate_tapping(stim_times, varargin)
% Simulate sensorimotor synchronization using a linear error correction
% model.
%
% This function generates a sequence of tap (response) times given a series
% of stimulus onset times. The model incorporates phase correction,
% period correction, and timekeeper noise.
%
% Parameters
% ----------
% stim_times : vector
%     A numeric vector of stimulus onset times.
%
% Name-Value Pairs
% ----------------
% alpha : double, optional (default = 0)
%     Phase correction parameter controlling how strongly timing errors
%     shift the next tap.
%
% beta : double, optional (default = 0)
%     Period correction parameter controlling adaptation of the internal
%     timekeeper interval.
%
% Tvar : double, optional (default = 0)
%     Variance of the Gaussian timekeeper noise.
%
% Tinit : double or empty, optional (default = [])
%     Initial value of the internal timekeeper. If empty, the first
%     inter-onset interval (IOI) is used to initialize the timekeeper.
%     If provided, this value overrides the IOI-based initialization.
%
% Returns
% -------
% tap_times : vector
%     Simulated response (tap) onset times. The first two entries are NaN,
%     as valid responses begin from index i = 2 onward.
%
% Notes
% -----
% - The internal timekeeper is initialized either from the first IOI or
%   from the user-provided Tinit.
% - Motor noise is currently disabled (set to zero).
% - The model produces valid taps starting from the second stimulus.
%
% Example
% -------
% stim = 0:0.5:10;
% taps = simulate_tapping(stim, ...
%     'alpha', 0.2, 'beta', 0.1, 'Tvar', 0.01, 'Tinit', 0.5);

parser = inputParser; 

addParameter(parser, 'alpha', 0); 
addParameter(parser, 'beta', 0); 
addParameter(parser, 'Tvar', 0); 
addParameter(parser, 'Tinit', []); 

parse(parser, varargin{:}); 

alpha = parser.Results.alpha; 
beta = parser.Results.beta; 
Tvar = parser.Results.Tvar; 
Tinit = parser.Results.Tinit; 


%% Set arrays

% Generate Arrays
n_stim = length(stim_times);

stim_iois = diff(stim_times); 

% Timekeeper vector
T = zeros(n_stim,1); % Default (initial) timekeeper value

if isempty(Tinit)
    T(1) = stim_iois(1); % Assume initial sounds set the timekeeper
else
    T(1) = Tinit; % use a manually set initial value for the timekeeper
end

% Noise Vectors
T_noise = Tvar * randn(n_stim, 1); % Timekeeper noise

M_noise = zeros(n_stim,1);% Motor noise, set to zero for simulation paper
% Try uncommenting the below code to explore the effect of motor noise,
% assumed to follow a gamma distribution
% M = gamrnd(4,2.5,n_stim,1);

% Response Onset Vector
tap_times = nan(n_stim,1); % Initialise Response vector based on expected onsets from the initial timekeeper estimates
tap_times(1:2) = [0, T(1)]; 

%% Start Sequence

for i = 2:n_stim-1
    
    % Calculate Error
    e = tap_times(i) - stim_times(i);

    % Perform Period Correction
    T(i) = T(i-1) - beta .* e;

    % Perform phase correction and set onset time for next response
    tap_times(i+1) = tap_times(i) + T(i) - alpha .* e + T_noise(i) + M_noise(i+1) - M_noise(i);

end

%%

tap_times(1:2) = nan; 




