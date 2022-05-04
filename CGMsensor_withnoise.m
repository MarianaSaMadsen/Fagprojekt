%%
% Fagprojekt - Diabetes 
% 23/03/22
% Emma Mona og Mariana

% Given N+1 state vectors and the parameters in the Medtronic Virtual
% Patient (MVP) model, evaluate the blood glucose concentrations subcutanius and apply gaussian noise. 

%INPUT: 
%   X - a vector of state variables
%   ph - a vector parameters

%OUTPUT:
%   G   - the blood glucose concentrations subcutanius with Gaussian noise

%%
function h = CGMsensor_withnoise(t,X,ph)

% The blood glucose concentrations subcutanius
h = X(7, :);

% Creating the Gaussian noise
std=1.5; % standard deviation of 2%
meanValue=0; % mean=0
Noise_signal_h = h + std*randn(size(h)) + meanValue;

h = Noise_signal_h;
end