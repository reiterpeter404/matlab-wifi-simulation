classdef hSLSTGaxSystemChannel < hSLSTGaxSystemChannelBase
%hSLSTGaxSystemChannel Create a channel manager object for full PHY
%
% CM = hSLSTGaxSystemChannel(CHAN,NUMANTSPERNODE) returns a channel
% manager object for the specified channel configuration object CHAN
% and an array containing the number of antennas per node
% NUMANTSPERNODE. This assumes all nodes can transmit and receive and
% channels between the nodes are reciprocal.
%
% CHAN is a wlanTGaxChannel, wlanTGacChannel or wlanTGnChannel object.
% The ChannelFiltering property must be set to false and the NumSamples
% property must be set. The channel configuration is assumed to be the
% same between all nodes.
%
%   hSLSTGaxSystemChannel properties:
%
%   Links       - Array of structures containing the channel for
%           each link
%   CenterFrequency - Center frequency of all channels in Hertz
%
%   hSLSTGaxSystemChannel methods:
%
%   applyChannelToWaveform    - filters a waveform through a
%                   channel between two nodes
%   applyChannelToSignalStructure - filters a waveform in a signal
%                   structure through a channel between
%                   two nodes

%   Copyright 2022-2023 The MathWorks, Inc.

  properties (Access=private)
    ChannelFilter;
  end

  methods
    function obj = hSLSTGaxSystemChannel(varargin)
      % CM = hSLSTGaxSystemChannel(CHAN,NUMANTENNAS) returns a
      % channel object for the specified channel configuration object
      % CHAN and an array containing the number of antennas per node
      % NUMANTENNAS. This assumes all nodes can transmit and receive
      % and channels between the nodes are reciprocal.
      obj = obj@hSLSTGaxSystemChannelBase(varargin{:})

      obj.initialize();
    end

    function initialize(obj)
      obj.ChannelFilter = cell(obj.NumChannels,2);
    end

    function [sig,pg,chanInfo] = applyChannelToSignalStructure(obj,sig,rxInfo)
      % SIG = applyChannelToSignalStructure(OBJ,SIG,RXIFNO) filters
      % the waveform in a signal structure SIG through the channel
      % between two nodes. The receiver is specified by the structure
      % RXINFO.

      chanFilt = getChannelFilter(obj,sig.TransmitterID,rxInfo.ID);
      chanInfo = info(chanFilt);

      % Add trailing zeros to allow for channel delay
      filterLen = size(chanInfo.ChannelFilterCoefficients,2);
      numPadSamples = filterLen-1;
      dataPad = [sig.Data; zeros(numPadSamples,size(sig.Data,2))];

      % Get path gains for all samples of input data
      numSamplesToSim = height(dataPad);
      simTime = sig.StartTime; % seconds
      pg = getPathGains(obj,sig.TransmitterID,rxInfo.ID,numSamplesToSim,simTime);

      % Reset filter as we assume one packet filtered at a time and
      % we are jumping ahead in time and we don't want any internal
      % state
      reset(chanFilt);

      % Filter waveform
      filteredData = chanFilt(dataPad,pg);

      % Remove implementation delay
      sig.Data = filteredData(chanInfo.ChannelFilterDelay+1:end,:);
      pg = pg(chanInfo.ChannelFilterDelay+1:end,:,:,:);

      % Add trailing transient to packet duration in seconds
      numTransientSamples = filterLen-1-chanInfo.ChannelFilterDelay;
      sig.Duration = sig.Duration+(numTransientSamples/chanFilt.SampleRate);
    end

    function [y,pg] = applyChannelToWaveform(obj,x,txIdx,rxIdx,varargin)
      % Y = applyChannelToWaveform(OBJ,X,TXIDX,RXIDX,[TIMEOFFSET])
      % filters the waveform X through the channel between node index
      % TXIDX and RXIDX. TIMEOFFSET is optional and specifies the
      % time of the first sample to pass through the channel in
      % seconds. If a time offset is specified the channel filter is
      % reset as time is assumed to progress beyond the filter group
      % delay.

      chanFilt = getChannelFilter(obj,txIdx,rxIdx);

      if nargin>4
        % If time offset provided reset filter as we assume one
        % packet filtered at a time and we are jumping ahead in
        % time and we don't want any internal state.
        reset(chanFilt);
      end
      % Get path gains for the required number of samples.
      numSamplesToSim = size(x,1);
      pg = getPathGains(obj,txIdx,rxIdx,numSamplesToSim,varargin{:});
      %  Filter waveform
      y = chanFilt(x,pg);
    end
  end

  methods (Access=private)
    function chanFilt = getChannelFilter(obj,txIdx,rxIdx)
      % CHANFILT = getChannelFilter(OBJ,TXIDX,RXIDX) returns the
      % channel filter between node index TXIDX and RXIDX.

      [idx,switched] = sub2chanInd(obj,txIdx,rxIdx);

      if isempty(obj.ChannelFilter{idx,1})
        % Create a separate channel filter for uplink and downlink
        % if filter not created already
        fs = obj.Links(idx).SampleRate; % Sample rate of each channel
        obj.ChannelFilter{idx,1} = comm.ChannelFilter('PathDelays',double(getPathDelays(obj,idx)),'SampleRate',fs,'NormalizeChannelOutputs',obj.Links(idx).Channel.NormalizeChannelOutputs);
        obj.ChannelFilter{idx,2} = clone(obj.ChannelFilter{idx,1});
      end

      if switched
        % Downlink channel filter
        chanFilt = obj.ChannelFilter{idx,2};
      else
        % Uplink channel filter
        chanFilt = obj.ChannelFilter{idx,1};
      end
    end
  end
end