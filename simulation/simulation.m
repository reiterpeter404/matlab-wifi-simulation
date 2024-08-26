clc;
clear;
close all;

% specify the number of APs for the simulation
positionCount = 6;

% simulation time in seconds
t_simulation = 20;
statsList = [];

if canUseParallelPool
    disp("Parallel Computing Toolbox is installed.")
else
    disp("Parallel Computing Toolbox is not installed.")
    disp("Program will be stopped, due to missing performance.")
    return;
end

%% Initialize project settings
tStart = tic;

% create the APs for the measurements
measurements_802_11n_throughput20 = zeros(1, positionCount);
measurements_802_11n_packetloss20 = zeros(1, positionCount);
measurements_802_11n_throughput40 = zeros(1, positionCount);
measurements_802_11n_packetloss40 = zeros(1, positionCount);
measurements_802_11n_throughput80 = zeros(1, positionCount);
measurements_802_11n_packetloss80 = zeros(1, positionCount);

measurements_802_11ac_throughput20 = zeros(1, positionCount);
measurements_802_11ac_packetloss20 = zeros(1, positionCount);
measurements_802_11ac_throughput40 = zeros(1, positionCount);
measurements_802_11ac_packetloss40 = zeros(1, positionCount);
measurements_802_11ac_throughput80 = zeros(1, positionCount);
measurements_802_11ac_packetloss80 = zeros(1, positionCount);

measurements_802_11ax_throughput20 = zeros(1, positionCount);
measurements_802_11ax_packetloss20 = zeros(1, positionCount);
measurements_802_11ax_throughput40 = zeros(1, positionCount);
measurements_802_11ax_packetloss40 = zeros(1, positionCount);
measurements_802_11ax_throughput80 = zeros(1, positionCount);
measurements_802_11ax_packetloss80 = zeros(1, positionCount);

measurements_802_11ax_throughput20Bss = zeros(1, positionCount);
measurements_802_11ax_packetloss20Bss = zeros(1, positionCount);
measurements_802_11ax_throughput40Bss = zeros(1, positionCount);
measurements_802_11ax_packetloss40Bss = zeros(1, positionCount);
measurements_802_11ax_throughput80Bss = zeros(1, positionCount);
measurements_802_11ax_packetloss80Bss = zeros(1, positionCount);

% specify the channel bandwidth
channelBandwidth = 20e6;

%% simulate the results for 802.11n
disp("Starting 802.11n simulations")
parfor numOfAPs=1 : positionCount 
    [throughput, packetloss, stats] = runSimulation(numOfAPs, 4, t_simulation, channelBandwidth, false);
    measurements_802_11n_throughput20(1,numOfAPs) = throughput;
    measurements_802_11n_packetloss20(1,numOfAPs) = packetloss;
end

%% simulate the results for 802.11ac
disp("Starting 802.11ac simulations")
parfor numOfAPs=1 : positionCount 
    [throughput, packetloss, stats] = runSimulation(numOfAPs, 5, t_simulation, channelBandwidth, false);
    measurements_802_11ac_throughput20(1,numOfAPs) = throughput;
    measurements_802_11ac_packetloss20(1,numOfAPs) = packetloss;
end

%% simulate the results for 802.11ax
disp("Starting 802.11ax simulations")
parfor numOfAPs=1 : positionCount 
    [throughput, packetloss, stats] = runSimulation(numOfAPs, 6, t_simulation, channelBandwidth, false);
    measurements_802_11ax_throughput20(1,numOfAPs) = throughput;
    measurements_802_11ax_packetloss20(1,numOfAPs) = packetloss;
end

%% simulate the results for 802.11ax
disp("Starting 802.11ax simulations with BSS")
parfor numOfAPs=1 : positionCount
    [throughput, packetloss, stats] = runSimulation(numOfAPs, 6, t_simulation, channelBandwidth, true);
    measurements_802_11ax_throughput20Bss(1,numOfAPs) = throughput;
    measurements_802_11ax_packetloss20Bss(1,numOfAPs) = packetloss;
end

%% retry with different bandwidth
channelBandwidth = 40e6;

%% simulate the results for 802.11n
disp("Starting 802.11n simulations")
parfor numOfAPs=1 : positionCount 
    [throughput, packetloss, stats] = runSimulation(numOfAPs, 4, t_simulation, channelBandwidth, false);
    measurements_802_11n_throughput40(1,numOfAPs) = throughput;
    measurements_802_11n_packetloss40(1,numOfAPs) = packetloss;
end

%% simulate the results for 802.11ac
disp("Starting 802.11ac simulations")
parfor numOfAPs=1 : positionCount 
    [throughput, packetloss, stats] = runSimulation(numOfAPs, 5, t_simulation, channelBandwidth, false);
    measurements_802_11ac_throughput40(1,numOfAPs) = throughput;
    measurements_802_11ac_packetloss40(1,numOfAPs) = packetloss;
end

%% simulate the results for 802.11ax
disp("Starting 802.11ax simulations")
parfor numOfAPs=1 : positionCount 
    [throughput, packetloss, stats] = runSimulation(numOfAPs, 6, t_simulation, channelBandwidth, false);
    measurements_802_11ax_throughput40(1,numOfAPs) = throughput;
    measurements_802_11ax_packetloss40(1,numOfAPs) = packetloss;
end

%% simulate the results for 802.11ax
disp("Starting 802.11ax simulations with BSS")
parfor numOfAPs=1 : positionCount
    [throughput, packetloss, stats] = runSimulation(numOfAPs, 6, t_simulation, channelBandwidth, true);
    measurements_802_11ax_throughput40Bss(1,numOfAPs) = throughput;
    measurements_802_11ax_packetloss40Bss(1,numOfAPs) = packetloss;
end

%% retry with different bandwidth
channelBandwidth = 80e6;

%% simulate the results for 802.11ac
disp("Starting 802.11ac simulations")
parfor numOfAPs=1 : positionCount 
    [throughput, packetloss, stats] = runSimulation(numOfAPs, 5, t_simulation, channelBandwidth, false);
    measurements_802_11ac_throughput80(1,numOfAPs) = throughput;
    measurements_802_11ac_packetloss80(1,numOfAPs) = packetloss;
end

%% simulate the results for 802.11ax
disp("Starting 802.11ax simulations")
parfor numOfAPs=1 : positionCount 
    [throughput, packetloss, stats] = runSimulation(numOfAPs, 6, t_simulation, channelBandwidth, false);
    measurements_802_11ax_throughput80(1,numOfAPs) = throughput;
    measurements_802_11ax_packetloss80(1,numOfAPs) = packetloss;
end

%% simulate the results for 802.11ax
disp("Starting 802.11ax simulations with BSS")
parfor numOfAPs=1 : positionCount
    [throughput, packetloss, stats] = runSimulation(numOfAPs, 6, t_simulation, channelBandwidth, true);
    measurements_802_11ax_throughput80Bss(1,numOfAPs) = throughput;
    measurements_802_11ax_packetloss80Bss(1,numOfAPs) = packetloss;
end



%% plot the data
% 20 MHz
plotWlanPacketLoss(measurements_802_11n_packetloss20, measurements_802_11ac_packetloss20, measurements_802_11ax_packetloss20, measurements_802_11ax_packetloss20Bss);
plotWlanThroughput(measurements_802_11n_throughput20, measurements_802_11ac_throughput20, measurements_802_11ax_throughput20, measurements_802_11ax_throughput20Bss);

% 40 MHz
plotWlanPacketLoss(measurements_802_11n_packetloss40, measurements_802_11ac_packetloss40, measurements_802_11ax_packetloss40, measurements_802_11ax_packetloss40Bss);
plotWlanThroughput(measurements_802_11n_throughput40, measurements_802_11ac_throughput40, measurements_802_11ax_throughput40, measurements_802_11ax_throughput40Bss);

% 80 MHz
plotWlanPacketLoss(measurements_802_11n_packetloss80, measurements_802_11ac_packetloss80, measurements_802_11ax_packetloss80, measurements_802_11ax_packetloss80Bss);
plotWlanThroughput(measurements_802_11n_throughput80, measurements_802_11ac_throughput80, measurements_802_11ax_throughput80, measurements_802_11ax_throughput80Bss);