% Creates several STA nodes next to the given AP node with a given list of positions.

function [staNodes] = addSTAsToAP( ...
  networkSimulator, ... % the network simulator of the project
  staPositions, ...     % all positions of the STAs using x,y and z
  apNode ...            % the AP node, to connect the STAs
)

import wlanWaveformGenerator.*

% Packet generation rate in Kbps
dataRate = 1024 * 1024; % resultierende Datenrate = 1 Gbps
packetSize = 1500;

% load the number of positions for the STAs
[numRows,~] = size(staPositions);
staNodes(numRows) = wlanNode;

for i=1 : numRows
  % get the current position of the AP and create a STAs position
  staPosition = apNode.Position + staPositions(i,:);

  % add the position to the array
  staID = apNode.ID + i;
  staNode = createStaNode( ...
    networkSimulator, ...
    apNode.DeviceConfig, ...
    staID, ...
    staPosition ...
  );
  staNodes(i) = staNode; % for analysis
        
  % apply the STA node to the current AP
  associateStations(apNode, staNode, FullBufferTraffic="off");

  % add traffic from AP to STA
  apTraffic = networkTrafficOnOff(DataRate=dataRate, PacketSize=packetSize, GeneratePacket=true);
  addTrafficSource(apNode, apTraffic, DestinationNode=staNode);
end
end