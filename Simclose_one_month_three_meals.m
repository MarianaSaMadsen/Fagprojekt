%% Sim closed loop
% Perform a closed-loop simulation with a PID controller with a single meal for the Medtronic

clear all 
clc 
close all

%% Making path
% addpath(genpath(fullfile(pwd, './src')));

%% Formatting the plots 

fs = 11; % Font size
lw = 3; % Line width
set(groot, 'DefaultAxesFontSize',   fs); % Set default font size

% Set default line widths
set(groot, 'DefaultLineLineWidth',  lw);
set(groot, 'DefaultStairLineWidth', lw);
set(groot, 'DefaultStemLineWidth',  lw);

%reset(groot);

%%  Conversion factors 

h2min = 60;      % Convert from h   to min 
min2h = 1/h2min; % Convert from min to h 
U2mU  = 1e3;     % Convert from U   to mU 
mU2U  = 1/U2mU;  % Convert from mU  to U 

%% Inizializing parameters

p = [49,47,20.1,0.0106,0.0081,0.0022,1.33,253,47,5]; % Parameters at steady state
Gs = 108; % [mg/dL]: Steady state blood glucose concentration
ts = [];

%% Computing steadty state

[xs, us, flag] = computeSteadyStateMVPModel(ts, p, Gs);

% If fsolve did not converge, throw an error
if(flag ~= 1), error ('fsolve did not converge!'); end


%% Intital and final time for the simulation over 18 hours

t0 =  0;       % min - start time
tf = 720*h2min; % min - end time
Ts = 5;        % min - Sampling time

%% Number of contral intervals

N = (tf - t0)/Ts; % [#]

%% Number of time steps in each control/sampling interval
Nk = 10;

%% Time span
tspan = 5*(0:N);

%% Initial condition
x0 = xs;

%% Inizialising the function to handles 
% Control algorithm
ctrlAlgorithm = @PIDControl;

% Simulation model
simModel = @MVPmodel;

% Observed variables
observationModel = @CHMsensor;

% Simulation method/function
simMethod = @ExplicitEuler;

%% Controller parameters and state
ctrlPar = [
      5.0;    % [min]     Sampling time
      0.05;   %           Proportional gain
      0.0005; %           Integral gain
      0.2500; %           Derivative gain
    108.0;    % [mg/dL]   Target blood glucose concentration
    NaN
    50.0;
    25.0;
    ];     % [mU/min]  Nominal basal rate (overwritten below)

ctrlState = [
      0.0;  %          Initial value of integral
    108.0]; % [mg/dL] Last measurements (dummy value)

%% Updating the nominal basal rate at steady state 

ctrlPar(6) = us(1);

%% Disturbance variables
D = zeros(1, N);

%% Meal and meal bolus after 1 hour
tMeal1           = 7*h2min;          % [min]
tMeal2           = 12*h2min;
tMeal3           = 18*h2min;
idxMeal1         = tMeal1  /5 + 1;   % [#]
idxMeal2         = tMeal2  /5 + 1;   % [#]
idxMeal3         = tMeal3  /5 + 1;   % [#]

% Lopping over 30 days (one month)
for i = 0:29
    D(1, (idxMeal1+24*h2min/Ts*i))   = 40     /Ts;       % [g CHO/min]
    D(1, (idxMeal2+24*h2min/Ts*i))   = 80     /Ts;       % [g CHO/min]
    D(1, (idxMeal3+24*h2min/Ts*i))   = 110    /Ts;       % [g CHO/min]
end 

%% Simulate
% Closed-loop simulation
[T, X, Y, U] = ClosedLoopSimulation(tspan,x0,D,p, ... 
    ctrlAlgorithm, simMethod, simModel, observationModel, ctrlPar,ctrlState,Nk);

% Blood glucose concentration
Gsc = Y; % [mg/dL]

%% Visualize
% Create figure with absolute size for reproducibility
figure;

% Plot blood glucose concentration
subplot(411);
plot(T*min2h, Gsc);
xlim([t0, tf]*min2h);
ylim([10 250])
ylabel({'CGM measurements', '[mg/dL]'});

% Plot meal carbohydrate
subplot(412);
stem(tspan(1:end-1)*min2h, Ts*D(1, :), 'MarkerSize', 0.1);
xlim([t0, tf]*min2h);
ylim([0 100])
ylabel({'Meal carbohydrates', '[g CHO]'});

% Plot basal insulin flow rate
subplot(413);
stairs(tspan*min2h, U(1, [1:end, end]));
xlim([t0, tf]*min2h);
ylim([20 50])
ylabel({'Basal insulin', '[mU/min]'});

% Plot bolus insulin
subplot(414);
stem(tspan(1:end-1)*min2h, Ts*mU2U*U(2, :), 'MarkerSize', 1);
xlim([t0, tf]*min2h);
ylim([-1 1])
ylabel({'Bolus insulin', '[U]'});
xlabel('Time [h]');









