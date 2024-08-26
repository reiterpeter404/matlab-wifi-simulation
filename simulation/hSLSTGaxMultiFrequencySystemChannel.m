classdef hSLSTGaxMultiFrequencySystemChannel < handle
%hSLSTGaxMultiFrequencySystemChannel Create a system channel object
%
% CHAN = hSLSTGaxMultiFrequencySystemChannel(NODES) returns a system
% channel object for an array of wlanNode objects, NODES. This assumes all
% nodes can transmit and receive and channels between the nodes are
% reciprocal.
%
% CHAN = hSLSTGaxMultiFrequencySystemChannel(NODES,PROTLINKCHAN) uses the
% prototype channel for a link PROTLINKCHAN to create channels between all
% nodes. PROTLINKCHAN is a wlanTGaxChannel, wlanTGacChannel or
% wlanTGnChannel object.
%
% CHAN =
% hSLSTGaxMultiFrequencySystemChannel(...,ShadowFadingStandardDeviation=val)
% sets the shadow fading standard deviation in dB. The default is 0 dB (no
% shadow fading).
%
% CHAN = hSLSTGaxMultiFrequencySystemChannel(...,PathLossModel=model)
% sets the path loss model to 'free-space', 'residential', or 'enterprise'.
% The default is 'free-space').
%
%   hSLSTGaxMultiFrequencySystemChannel properties:
%
%   Channels   - Array of system channels; one channel per frequency.
%   ChannelFcn - Function handle to channel for all nodes and links in
%                the simulation
%
%   hSLSTGaxMultiFrequencySystemChannel methods:
%
%   getChannelStatistics - Returns the channel statistics between a
%                          pair of nodes

%   Copyright 2022-2024 The MathWorks, Inc.

  properties
    %Channels Array of system channels; one channel per frequency
    %   The class of Channels depends on PHYAbstractionMethod specified
    %   in NODES:
    %    "none" - array of hSLSTGaxSystemChannel objects
    %    otherwise - array of hSLSTGaxAbtractSystemChannel objects
    Channels;
    %ChannelFcn Function handle to channel for all nodes and links in
    %the simulation
    ChannelFcn;
  end

  properties (Access=private)
    UseFullPHY = false;
    NodeIDs;
  end

  methods
    function obj = hSLSTGaxMultiFrequencySystemChannel(nodes,varargin)
      % CHAN = hSLSTGaxMultiFrequencySystemChannel(NODES) returns a
      % system channel object for an array of wlanNode objects, NODES.
      % This assumes all nodes can transmit and receive and channels
      % between the nodes are reciprocal.
      %
      % CHAN = hSLSTGaxMultiFrequencySystemChannel(NODES,PROTLINKCHAN)
      % uses the prototype channel for a link PROTLINKCHAN to create
      % channels between all nodes.
      %
      % CHAN =
      % hSLSTGaxMultiFrequencySystemChannel(...,ShadowFadingStandardDeviation=val)
      % sets the shadow fading standard deviation in dB. The default
      % is 0 dB (no shadow fading).

      % Set the base channel properties - this is used for all links Note
      % the number of transmit and receive antennas, and channel
      % bandwidth are sets from the node configuration.
        prototypeChannel = wlanTGaxChannel(...
        'DelayProfile','Model-D',...
        'TransmitReceiveDistance',15,...
        'ChannelFiltering',false,...
        'OutputDataType','single', ...
        'EnvironmentalSpeed',0); % 0.0890
      nvpairStart = 1;
      if nargin>1
        if isa(varargin{1}, 'wlan.internal.ChannelBase')
          prototypeChannel = varargin{1};
          nvpairStart = 2;
        end
      end
      % Select type of channel model depending on PHY abstraction
      % used
      obj.UseFullPHY = nodes(1).PHYAbstractionMethod == "none";

      nodeFreqs = [];
      nodeBWs = [];
      numNodes = numel(nodes);
      for idx = 1:numNodes
        if (nodes(idx).PHYAbstractionMethod=="none") ~= obj.UseFullPHY 
          error('All nodes must be configured to use the same PHY abstraction method')
        end
        devCfg = getDeviceConfig(nodes(idx));
        for ifcIdx = 1:numel(devCfg)
          if devCfg(ifcIdx).InterferenceModeling~="co-channel"
            % Only co-channel interferene modeling supported
            error('All devices must be configured to use "co-channel" interference modeling')
          end
          nodeFreqs(end+1) = wlanChannelFrequency(devCfg(ifcIdx).BandAndChannel(2),devCfg(ifcIdx).BandAndChannel(1)); %#ok<AGROW>
          nodeBWs(end+1) = devCfg(ifcIdx).ChannelBandwidth; %#ok<AGROW>
        end
      end
      [uniqueFreqs,~,ui] = unique(nodeFreqs);
      numFreqs = numel(uniqueFreqs);

      availableBWs = [20 40 80 160 320]*1e6;
      availableCBWs = ["CBW20" "CBW40" "CBW80" "CBW160" "CBW320"];

      % Get channel bandwidth and sample rate for each frequency
      cbwToUse = strings(1,numFreqs);
      srToUse = zeros(1,numFreqs);
      for i = 1:numel(uniqueFreqs)
        % Verify bandwidths are not mixed on each frequency
        bwForFreq = nodeBWs(ui==i);
        if ~all(bwForFreq==bwForFreq(1))
          error('All devices using the same frequency must use the same bandwidth')
        end
        cbwToUse(i) = availableCBWs(availableBWs==bwForFreq(1));
        srToUse(i) = (availableBWs(availableBWs==bwForFreq(1)));
      end

      % Create a 2D vector of size N-by-M, where N is the number of
      % nodes and M specifies unique frequencies configured for all
      % nodes. Each element in the vector represents number of
      % antennas.
      numAnts = nan(numNodes,numFreqs);
      for i = 1:numel(uniqueFreqs)
        for n = 1:numNodes
          activeFreq = nodes(n).ReceiveFrequency==uniqueFreqs(i);
          if ~any(activeFreq)
            continue
          end
          devCfg = getDeviceConfig(nodes(n));
          numAnts(n,i) = devCfg(activeFreq).NumTransmitAntennas;
        end
      end

      nodeIDs = [nodes.ID];
      obj.NodeIDs = nodeIDs(:);

      % Create a channel manager for each band
      if obj.UseFullPHY
        obj.Channels = hSLSTGaxSystemChannel.empty(1,0);
      else
        obj.Channels = hSLSTGaxAbstractSystemChannel.empty(1,0);
      end
      for i = 1:numFreqs
        prototypeChannel.SampleRate = srToUse(i);
        prototypeChannel.ChannelBandwidth = cbwToUse(i);
        prototypeChannel.CarrierFrequency = uniqueFreqs(i);
        if obj.UseFullPHY
          obj.Channels(i) = hSLSTGaxSystemChannel(prototypeChannel,numAnts(:,i),varargin{nvpairStart:end});
        else
          obj.Channels(i) = hSLSTGaxAbstractSystemChannel(prototypeChannel,numAnts(:,i),varargin{nvpairStart:end});
        end
        % Convert 1-based LUT ID of nodes within system channel to
        % node IDs
        for j = 1:numel(obj.Channels(i).Links)
          obj.Channels(i).Links(j).Node1 = lutind2nodeid(obj,obj.Channels(i).Links(j).Node1);
          obj.Channels(i).Links(j).Node2 = lutind2nodeid(obj,obj.Channels(i).Links(j).Node2);
        end
      end

      % Function handle to return impaired signal
      obj.ChannelFcn = @(rxInfo,signal)impairSignal(obj,signal,rxInfo);
    end
  end

  methods (Access=private)
    function sig = impairSignal(obj,sig,rxInfo)
      %impairSignal Apply path loss, log-normal shadow fading, and
      %frequency selective fading to the packet and update relevant
      %fields of the output data.

      % Store node ID for transmitter and convert transmitter and
      % receiver IDs to lookup table IDs.
      nodeTxID = sig.TransmitterID;
      sig.TransmitterID = nodeid2lutind(obj,sig.TransmitterID);
      rxInfo.ID = nodeid2lutind(obj,rxInfo.ID);

      channel = getChannelForSignalFrequency(obj.Channels,sig);

      % Model path loss
      sig = pathLoss(obj,channel,sig,rxInfo);

      % Model shadow fading
      sig = shadowFading(obj,channel,sig,rxInfo);

      % Model frequency-selective fading
      if obj.UseFullPHY
        sig = applyChannelToSignalStructure(channel,sig,rxInfo);
      else
        sig.Metadata.Channel = getChannelStatistics(channel,sig,rxInfo);
      end

      % Restore original transmitter node ID
      sig.TransmitterID = nodeTxID;
    end

    function sig = pathLoss(obj, channel, sig, rxInfo)
      %pathLoss Apply path loss to the packet and update relevant fields
      %of the output data.

      pl = getPathLoss(channel,sig,rxInfo); % dB

      % Apply path loss on the power of the packet
      sig.Power = sig.Power - pl;

      if obj.UseFullPHY
        % Scale signal by path loss
        sig.Data = sig.Data*db2mag(-pl);
      end
    end

    function sig = shadowFading(obj, channel, sig, rxInfo)
      %shadowFading Apply log-normal shadow fading to the packet and
      %update relevant fields of the output data.

      txIdx = sig.TransmitterID;
      rxIdx = rxInfo.ID;
      l = getShadowFading(channel,txIdx,rxIdx); % dB
      % Apply shadow fading to the power of the packet
      sig.Power = sig.Power + l; % power in dBm

      if obj.UseFullPHY
        % Scale signal by shadow fading
        sig.Data = sig.Data*db2mag(l);
      end
    end

    function lutInd = nodeid2lutind(obj, nodeID)
      % Return LUT index for node ID
      lutInd = find(nodeID==obj.NodeIDs);
    end

    function nodeID = lutind2nodeid(obj, lutInd)
      % Return node ID for LUT index
      nodeID = obj.NodeIDs(lutInd);
    end
  end
end

function channel = getChannelForSignalFrequency(channels,sig)
  %getChannelForSignalFrequency Returns the appropriate channel manager
  %object
  %
  % CHANNEL = getChannelForSignalFrequency(CHANNELS, SIG) returns the channel
  % manager object for the matching center frequency

  channelIdx = sig.CenterFrequency==[channels.CenterFrequency];
  channel = channels(channelIdx);
end

function devCfg = getDeviceConfig(node)
  %getDeviceConfig Returns the object holding MAC/PHY configuration
  %
  %   DEVCFG = getDeviceConfig(NODE) returns the object that holds the
  %   MAC/PHY configuration.
  %
  %   DEVCFG is an object of type wlanDeviceConfig if the input is a non-MLD
  %   node and it is an object of type wlanLinkConfig if the input is an MLD
  %   node.
  %
  %   NODE is an object of type wlanNode.

  if isa(node.DeviceConfig, 'wlanMultilinkDeviceConfig')
    devCfg = node.DeviceConfig.LinkConfig;
  else
    devCfg = node.DeviceConfig;
  end
end