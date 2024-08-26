% run the simulation with the given number of APs

function [statThroughput, staPacketLoss, nodeStatistics] = runSimulation( ...
    numberOfAPs, ...            % number of APs for the simulation
    apStandard, ...             % standard of the measurement AP
    t_simulation, ...           % simulation time
    channelBandwidth, ...       % the bandwidth of the channel
    useDifferentBssColor ...    % use different BSS colors for the 802.11ax APs
)

% check the input parameters
if numberOfAPs < 0
    return
elseif numberOfAPs > 27
    return
elseif apStandard < 4
    return
elseif apStandard > 6
    return
end

%% define global variables

% set the distance between the APs and the distance from AP to each STA
distanceAPs = 20;
distanceSTAs = 5;


%% initialize project settings

% create a grid for the AP positions with the given distance and order them by the distance to the center
positions = generateGrid(distanceAPs);
% get the first element as a position center (here will the AP for the measurements be located
positionCenter = positions(1,:);

staPoints = loadStaDistances(distanceSTAs);


%% handle the APs and their positions
apNodes(numberOfAPs) = wlanNode;
% set all positions
for i = 1 : numberOfAPs
    apNodes(1,i).Position = positions(i,:);
end


%% Handle the AP measurements

% add the wireless network simulator (make sure that this variable has to be handed over to the functions that create new APs and STAs)
networkSimulator = wirelessNetworkSimulator.init();

apNode80211 = createApNodeWithEqualChannel(networkSimulator, 1, 1, positionCenter, apStandard, channelBandwidth);
apNodes(1) = apNode80211;
staNodes = addSTAsToAP(networkSimulator, staPoints, apNode80211, true);

% create a list of all nodes
nodes = [apNode80211 staNodes];
%nodesToMeasure = nodes;

%% Add an AP at each iteration and perform the measurements

% add more APs to the measurement
if numberOfAPs > 1
    % create the results of each measurement
    for i = 2 : numberOfAPs
        currentPosition = positions(i,:);
        if useDifferentBssColor
            bssColor = i;
        else
            bssColor = 1;
        end

        % select a different standard number each iteration
        wifiStandard = selectWifiStandard(i, channelBandwidth);

        % add a new AP to the measurements with the selected 802.11 standard
        % do nothing, if the AP for the measurements is selected
        currentAP = createApNodeWithEqualChannel(networkSimulator, bssColor, i, currentPosition, wifiStandard, channelBandwidth);

        % add STA nodes to the current position in each direction with the given distance
        staNodes = addSTAsToAP(networkSimulator, staPoints, currentAP, true);

        % load the AP to the list of APs
        apNodes(1,i) = currentAP;

        % setup all nodes
        %nodesFromIterator = [currentAP staNodes];
        nodes = [nodes currentAP staNodes];
    end
end

% add channel to the model
% the functions 'hSLSTGaxMultiFrequencySystemChannel' and 'hPerformanceViewer' are methods from the example project 'Spatial Reuse with BSS Coloring in 802.11ax Network Simulation'
channel = hSLSTGaxMultiFrequencySystemChannel(nodes);
addChannelModel(networkSimulator, channel.ChannelFcn);

%% simulate the results
addNodes(networkSimulator, nodes);
perfViewerObj = hPerformanceViewer(nodes, t_simulation);
run(networkSimulator, t_simulation);

nodeStatistics = statistics(nodes);
statThroughput = throughput(perfViewerObj, apNode80211.ID);
staPacketLoss = packetLossRatio(perfViewerObj, apNode80211.ID);

end