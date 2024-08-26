classdef hSLSTGaxSystemChannelBase < handle
%hSLSTGaxSystemChannelBase Create a hSLSTGaxSystemChannelBase object
%
%   CM = hSLSTGaxSystemChannelBase(CHAN,NUMANTENNAS) returns a channel
%   manager object for the specified channel configuration object CHAN and 
%   an array containing the number of antennas per node NUMANTENNAS. This 
%   assumes all nodes can transmit and receive and channels between the 
%   nodes are reciprocal.
%
%   CHAN is a wlanTGaxChannel, wlanTGacChannel or wlanTGnChannel object. 
%   The ChannelFiltering property must be set to false and the NumSamples
%   property must be set. The channel configuration is assumed to be the
%   same between all nodes.
%
%   hSLSTGaxSystemChannelBase properties:
%
%   Links       - Array of structures containing the channel for
%           each link with the following fields:
%           Channel - Fading channel object. The channel
%                 sample rate is set to the lowest
%                 possible to generate samples given
%                 Doppler requirements of the channel.
%                 You can edit channel properties, in
%                 which case call the reset() method of
%                 hSLSTGaxAbstractChannel to update the
%                 channel sampling rate.
%           Node1   - Identifier of the first node in the link
%           Node2   - Identifier of the second node in the
%                link
%           SampleRate - Sample rate in Hz used to generate
%                  path gains.
%           ShadowFading - Shadow fading in dB.
%   CenterFrequency  - Center frequency of all channels in Hertz
%   ShadowFadingStandardDeviation - Shadow fading standard deviation
%                   in dB
%   PathLossModel  - Path loss model
%   PathLossModelFcn - Custom path loss model function handle
%
%   hSLSTGaxSystemChannelBase methods:
%
%   getChannelStatistics - returns the channel stats between a pair of
%              nodes
%   reset        - calculate channel sampling rates and random
%              shadow fading for all links

%   Copyright 2022-2023 The MathWorks, Inc.

  %#codegen

  properties (Access=private)
    PathGains;   % Path gains for generated channels
    PathFilters; % Path filters for all channels
    PathDelays;  % Path delays for all channels
    ChanIndLUT;  % Array used to map channel index

    Channels;  % Object for each channel
    PathTimes;
    LastPathTime;
    SampleTimeOffset;
    PathTimeOffset;
  end

  properties (Access=protected)
    NumChannels;
  end

  properties
    %Links Array of structures containing channels for each link
    Links;
    %CenterFrequency Channel operating frequency in Hz
    CenterFrequency;
    %ShadowFadingStandardDeviation Shadow fading standard deviation in
    %dB
    %  Set to 0 for no shadow fading
    ShadowFadingStandardDeviation = 0;
    %PathLossModel Path loss model
    %  Set to 'free-space', 'enterprise', 'residential', or 'custom'.
    %  'enterprise' and  'residential' use the formulas given in IEEE
    %  802.11-14/0980r16. 'custom' uses the path loss function
    %  handled PathLossModelFcn. The default is 'free-space'.
    PathLossModel = 'free-space';
    % PathLossModelFcn Custom path loss model function handle
    %  Function handle which returns path loss in dB:
    %  PathLossModelFcn(sig,rxInfo). sig is a structure containing
    %  information about the transmitted packet and transmitter.
    %  rxInfo is a structure containing information about the
    %  receiver.
    PathLossModelFcn;
  end

  properties (Constant, Hidden=true)
    PacketIterationSimTime = 10e-3; % Simulate 10 ms of channel at a time
    LightSpeed = physconst('lightspeed');
  end

  methods
    function obj = hSLSTGaxSystemChannelBase(chan,numAntennas,varargin)
      % CM = hSLSTGaxSystemChannelBase(CHAN,NUMANTENNAS) returns a
      % channel manager object for the specified channel
      % configuration object CHAN and an array containing the number
      % of antennas per node NUMANTENNAS. This assumes all nodes can
      % transmit and receive and channels between the nodes are
      % reciprocal.
      %
      % CM =
      % hSLSTGaxSystemChannelBase(...,ShadowFadingStandardDeviation=val)
      % sets the shadow fading standard deviation in dB. The default
      % is 0 dB (no shadow fading).

      for i = 1:2:nargin-3
        obj.(varargin{i}) = varargin{i+1};
      end

      % Generate downlink and uplink channels between transmitters
      % and receivers assuming they may have different numbers of
      % antennas.
      numNodes = numel(numAntennas);

      % Generate channels between all transmitters and receivers.
      % * Assume a transmitter and receiver are the same node,
      %   therefore do not generate a channel between a node and
      %   itself.
      % * Assume the channel is reciprocal between a transmitter
      %   and receiver, but antenna configuration can be different.
      % 
      % Create a mapping function to map requested channel between a
      % pair of nodes (tx,rx) to a channel. Each row contains the
      % transmitter index and receiver index of a channel. The
      % transmitter index will always be lower than the receiver
      % index.
      obj.ChanIndLUT = nchoosek(1:numNodes,2);

      % Allocate arrays to store channels generated
      obj.NumChannels = height(obj.ChanIndLUT);
      obj.Links = repmat(struct('Channel',[],'Node1',[],'Node2',[],'SampleRate',chan.SampleRate,'ShadowFading',[]),1,obj.NumChannels);
      obj.Channels = cell(1,obj.NumChannels);
      obj.PathDelays = cell(obj.NumChannels,1);
      obj.PathFilters = cell(obj.NumChannels,1);
      obj.PathGains = cell(obj.NumChannels,1);
      obj.CenterFrequency = chan.CarrierFrequency;

      % Generate channels
      release(chan);
      for ichan = 1:obj.NumChannels
        txIdx = obj.ChanIndLUT(ichan,1);
        rxIdx = obj.ChanIndLUT(ichan,2);
        numTx = numAntennas(txIdx);
        numRx = numAntennas(rxIdx);
        if isnan(numTx) || isnan(numRx)
          % No link so skip
          continue
        end

        obj.Channels{ichan} = clone(chan);
        obj.Channels{ichan}.ChannelFiltering = false; % Disable channel filtering as will be done externally
        obj.Channels{ichan}.NumTransmitAntennas = numTx;
        obj.Channels{ichan}.NumReceiveAntennas = numRx;

        % Create public array of channels user can control
        obj.Links(ichan).Node1 = txIdx;
        obj.Links(ichan).Node2 = rxIdx;
        obj.Links(ichan).Channel = obj.Channels{ichan};

        % Log-normal shadow fading in dB
        obj.Links(ichan).ShadowFading = obj.ShadowFadingStandardDeviation*randn;
      end

      % Reset channels and calculate Doppler dependent parameters
      reset(obj);
    end

    function reset(obj,varargin)
      % reset(OBJ) reset all channel models reset(OBJ,TXIDX,RXIDX)
      % channel model specified by transmit and receive index

      if nargin>1
        txIdx = varargin{1};
        rxIdx = varargin{2};
        channelsToSet = obj.sub2chanInd(txIdx,rxIdx);
      else
        channelsToSet = 1:obj.NumChannels;
      end

      % Set sample rate and number of samples for each channel at
      % lowest rate given Doppler frequency
      for ichan = channelsToSet
        % Reset
        obj.PathGains{ichan} = [];
        obj.PathTimes{ichan} = [];
        obj.PathDelays{ichan} = [];
        obj.PathFilters{ichan} = [];
        obj.SampleTimeOffset(ichan) = 0;
        obj.LastPathTime(ichan) = -1;
        obj.PathTimeOffset(ichan) = 0;

        if isempty(obj.Channels) || isempty(obj.Channels{ichan})
          % No channel exists
          continue
        end

        % Log-normal shadow fading in dB
        if obj.ShadowFadingStandardDeviation>0
          obj.Links(ichan).ShadowFading = obj.ShadowFadingStandardDeviation*randn;
        end

        release(obj.Channels{ichan});
        obj.Channels{ichan}.SampleRate = obj.Links(ichan).SampleRate; % Reset sample rate for regenerating path filters as potentially reduced by code.
        obj.Channels{ichan}.ChannelFiltering = false; % Disable channel filtering as will be done externally

        % Set channel sampling rate required for Doppler component
        wavelength = 3e8/obj.Channels{ichan}.CarrierFrequency;
        fdoppler = (obj.Channels{ichan}.EnvironmentalSpeed*(5/18))/wavelength; % Cut-off frequency (Hz), cChange km/h to m/s
        normalizationFactor = 1/300;
        fc = fdoppler/normalizationFactor; % Channel sampling frequency
        if fc>0
          fc = fc+1e-6; % Add to avoid numeric issues comparing oversampled and input sample rates when filtering
        end
        interpolationFactor = 1/40; % Interpolation required for Fluorescent effect

        % Set sample rate of channel to lowest possible to generate
        % path gains based on Doppler frequency
        obj.Channels{ichan}.SampleRate = max(fc/interpolationFactor,1e-3); % minimum very low sample rate (TODO handle 0 speed better)

        % Calculate how many path gain samples to generate so that
        % it will have at least as many required for one packet
        % step time
        numPathGainSamples = max(ceil(obj.PacketIterationSimTime*obj.Channels{ichan}.SampleRate),2); % At least 2 samples required
        while (numPathGainSamples-1)/obj.Channels{ichan}.SampleRate < obj.PacketIterationSimTime
          % As the first sample is time 0, make sure we have
          % enough samples to capture the simulation time
          numPathGainSamples = numPathGainSamples+1;
        end
        obj.Channels{ichan}.NumSamples = numPathGainSamples;
      end
    end

    function initialize(obj)
      % Reset channels and parameters and calculate first path gains

      reset(obj);

      for ichan = 1:obj.NumChannels
        if isempty(obj.Channels{ichan})
          % No channel exists
          continue
        end
        txIdx = obj.ChanIndLUT(ichan,1);
        rxIdx = obj.ChanIndLUT(ichan,2);

        % Evolving channel, get path gain for desired simulation
        % time
        numSamples = 1;
        interpMethod = 0; % 0 = closest, 1 = linear
        simTime = 0;
        getPathGains(obj,txIdx,rxIdx,numSamples,simTime,interpMethod);
      end
    end

    function pd = getPathDelays(obj,varargin)
      % PD = getPathDelays(OBJ,TXIDX,RXIDX) calculates channel path
      % delays between node index TXIDX and RXIDX.
      %
      % PD = getPathDelays(OBJ,CHANIDX) calculates the path delays
      % for the channel index CHANIDX.

      idx = channelIndex(obj,varargin{:});

      if isempty(obj.PathDelays{idx})
        % Get path delays and filters if they do not already exist
        chanInfo = info(obj.Channels{idx});
        obj.PathDelays{idx} = chanInfo.PathDelays;
      end
      pd = obj.PathDelays{idx};
    end

    function [pf,pd] = getPathFilters(obj,varargin)
      % PF = getPathFilters(OBJ,TXIDX,RXIDX) calculates channel path
      % filters between node index TXIDX and RXIDX.
      %
      % PF = getPathFilters(OBJ,CHANIDX) calculates the path filters
      % for the channel index CHANIDX.
      %
      % [PF,PD] = getPathFilters(...) additionally returns the path
      % delays.

      idx = channelIndex(obj,varargin{:});

      if isempty(obj.PathFilters{idx})
        % Get path delays and filters if they do not already exist
        chanInfo = info(obj.Channels{idx});
        obj.PathDelays{idx} = chanInfo.PathDelays;

        % Channel filter in obj.Channel may be configured for
        % lowest sample rate, so calculate path filters externally
        channelFilter = comm.ChannelFilter( ...
          'SampleRate', obj.Links(idx).SampleRate, ...
          'PathDelays', double(getPathDelays(obj,idx)), ...
          'NormalizeChannelOutputs', obj.Channels{idx}.NormalizeChannelOutputs);
        obj.PathFilters{idx} = info(channelFilter).ChannelFilterCoefficients;
      end
      pf = obj.PathFilters{idx};
      pd = obj.PathDelays{idx};
    end

    function [pg,st] = getPathGains(obj,txIdx,rxIdx,numSamples,varargin)
      % [PG,ST] = getPathGains(OBJ,TXIDX,RXIDX,NUMSAMPLES) calculates
      % channel path gains and associated sample time between node
      % index TXIDX and RXIDX for NUMSAMPLES since the last call.
      % Linear interpolation is used to generate path gains at the
      % required sample rate.
      %
      % [PG,ST] =
      % getPathGains(OBJ,TXIDX,RXIDX,NUMSAMPLES,STARTTIME,METHOD)
      % specifies the STARTTIME of path gains.
      %
      % METHOD controls the interpolation method: 0 - returns closest
      % path gain for each sample time 2 - interpolate path gains
      % over sample times (linear)
      %
      % [PG,ST] = getPathGains(OBJ,TXIDX,RXIDX,2,[STARTTIME
      % ENDTIME],1) calculates channel path gains and associated
      % sample times. Returns all path gains within the sample
      % period, and one either side to allow for interpolation given
      % STARTIME and ENDTIME.

      interpMethod = 2; % linear

      % Extract channel information
      [idx,switched] = obj.sub2chanInd(txIdx,rxIdx);

      fs = obj.Links(idx).SampleRate;
      samplesSimTime = numSamples/fs;

      lastPathTime = obj.LastPathTime(idx);
      pathTimeOffset = obj.PathTimeOffset(idx);
      if nargin>4
        if nargin>5 && varargin{2} == 1 % method = start stop (1)
          % getPathGains(OBJ,TXIDX,RXIDX,NUMSAMPLES,TIME,1)
          assert(numSamples==2)
          assert(numel(varargin{1})==2)
          waveformStartTime = varargin{1}(1);
          waveformEndTime = varargin{1}(2);
          interpMethod = 1; % Start stop
        else
          % getPathGains(OBJ,TXIDX,RXIDX,NUMSAMPLES,STARTTIME,[METHOD])
          sampleTimeOffset = varargin{1};
          if nargin>5
            interpMethod = varargin{2};
            assert(any(interpMethod==[0 2]),'Expected interpolation method to be linear or closest')
          end
        end
      else
        % getPathGains(OBJ,TXIDX,RXIDX,NUMSAMPLES) Continue from
        % where we left off
        sampleTimeOffset = obj.SampleTimeOffset(idx);
      end

      if interpMethod == 1 % start end
        sampleTimes = ([waveformStartTime waveformEndTime]);
      else
        % Update the times for each sample to generate
        sampleTimes = sampleTimeOffset+((0):(1/fs):(samplesSimTime-(1/fs)));
      end
      obj.SampleTimeOffset(idx) = sampleTimes(end)+(1/fs);

      while sampleTimes(end)>lastPathTime
        % Generate new path gains if required
        chan = obj.Channels{idx};
        pgFc = chan();

        % Simulation time for each sample
        pathTimes = cast(pathTimeOffset+((0):(1/chan.SampleRate):((chan.NumSamples-1)/chan.SampleRate)),chan.OutputDataType);
        lastPathTime = pathTimes(end);
        pathTimeOffset = lastPathTime+(1/chan.SampleRate);

        if ~isempty(obj.PathTimes{idx})
          % Keep path gains at times which are still needed,
          % discard rest. Note we need 1 less than the minimum
          % sample time to allow interpolation
          keepIdx = find((obj.PathTimes{idx}>=sampleTimes(1))',1);
          keepIdx = max(keepIdx-1,1);
          if isempty(keepIdx)
            % Keep at least one path time to make sure we will
            % always have one that is one before the
            % lastPathTime
            keepIdx = numel(obj.PathTimes{idx});
          end
          obj.PathTimes{idx} = [obj.PathTimes{idx}(keepIdx:end); pathTimes.'];
          obj.PathGains{idx} = [obj.PathGains{idx}(keepIdx:end,:,:,:); pgFc];
        else
          % First time
          obj.PathTimes{idx} = pathTimes.';
          obj.PathGains{idx} = pgFc;
        end
        obj.LastPathTime(idx) = lastPathTime;
        obj.PathTimeOffset(idx) = pathTimeOffset;
      end

      % Channel path gains are generated (and stored) for one
      % direction. Therefore if the reciprocal channel is required
      % switch the transmit and receive antenna dimension.
      pgUse = obj.PathGains{idx};
      if switched
        pgUse = permute(pgUse,[1 2 4 3]);
      end

      switch interpMethod
        case 0 % closest
          % Return path closest to time requested
          [~,closestInd] = min(abs(obj.PathTimes{idx}-sampleTimes));
          pg = pgUse(closestInd,:,:,:);
          st = obj.PathTimes{idx}(closestInd)';
        case 1
          % Return path gains which in packet duration, and one
          % before and after to allow for interpolation
          firstIdx = find(obj.PathTimes{idx}<=waveformStartTime,1,'last');
          lastIdx = find(obj.PathTimes{idx}>=waveformEndTime,1,'first');
          st = obj.PathTimes{idx}(firstIdx:lastIdx)';
          pg = pgUse(firstIdx:lastIdx,:,:,:);
        otherwise % linear
          % Interpolate path gains over sample times
          st = sampleTimes';
          pg = double(interp1(obj.PathTimes{idx},pgUse,sampleTimes'));
      end
    end

    function l = getShadowFading(obj,txIdx,rxIdx)
      % L = getShadowFading(OBJ,TXIDX,RXIDX) returns shadow fading in
      % dB between node index TXIDX and RXIDX.

      % Extract channel information
      idx = obj.sub2chanInd(txIdx,rxIdx);

      l = obj.Links(idx).ShadowFading;
    end

    function pl = getPathLoss(obj, sig, rxInfo)
      %pathLoss Calculates path loss based on the signal and receiver
      %information

      d = norm(sig.TransmitterPosition - rxInfo.Position);

      switch obj.PathLossModel
        case 'free-space'
          pl = freeSpacePathLoss(obj, d);
        case 'residential'
          pl = tgaxResidentialPathLoss(obj, d);
        case 'enterprise'
          pl = tgaxEnterprisePathLoss(obj, d);
        case 'custom'
          pl = obj.PathLossModelFcn(sig,rxInfo);
      end
    end
  end

  methods (Access=protected)
    function [idx,switched] = sub2chanInd(obj,txIdx,rxIdx)
      % Returns the channel index given the transmit and receive node
      % indices
      [txIdxUse,rxIdxUse,switched] = sub2chanIndRecip(txIdx,rxIdx);
      idx = all(obj.ChanIndLUT == [txIdxUse rxIdxUse],2);
      % Check that the channel has been created, if not it will be
      % NaNs. A channel does not exist between a node and itself.
      if ~any(idx) || isempty(obj.Links(idx).Channel)
        error('hSLSTGaxSystemChannelBase:NoChannelExists','Channel does not exist between node #%d and #%d.',txIdx,rxIdx)
      end
    end
  end

  methods (Access=private)
    function pl = tgaxEnterprisePathLoss(obj, d)
      %tgaxEnterprisePathLoss Apply distance-based path loss on the
      %packet and update relevant fields of the output data. As per
      %IEEE 802.11-14/0980r16

      d = max(d,1);
      W = 0; % Number of walls penetrated
      % Enterprise
      dBP = 10; % breakpoint distance
      pl = 40.052 + 20*log10((obj.CenterFrequency/1e9)/2.4) + 20*log10(min(d,dBP)) + (d>dBP) * 35*log10(d/dBP) + 7*W;
    end

    function pl = tgaxResidentialPathLoss(obj, d)
      %tgaxResidentialPathLoss Apply distance-based path loss on the
      %packet and update relevant fields of the output data. As per
      %IEEE 802.11-14/0980r16

      d = max(d,1);
      F = 0; % Number of floors penetrated
      W = 0; % Number of walls penetrated
      % Residential
      dBP = 5;
      pl = 40.052 + 20*log10((obj.CenterFrequency/1e9)/2.4) + 20*log10(min(d,dBP)) + (d>dBP) * 35*log10(d/dBP) + 18.3*F^((F+2)/(F+1)-0.46) + 5*W;
    end

    function pl = freeSpacePathLoss(obj, d)
      %freeSpacePathLoss Apply free space path loss on the packet and
      %update relevant fields of the output data

      % Calculate free space path loss (in dB)
      pl = fspl(d, obj.LightSpeed/obj.CenterFrequency);
    end

    function idx = channelIndex(obj,varargin)
      %channelIndex returns the channel index given either the
      %channel index or transmitter and receiver node index.
      if nargin==2
        idx = varargin{1};
      else
        % Extract channel information
        txIdx = varargin{1};
        rxIdx = varargin{2};
        idx = obj.sub2chanInd(txIdx,rxIdx);
      end
    end
  end

end

function [txIdxUse,rxIdxUse,switched] = sub2chanIndRecip(txIdx,rxIdx)
% Channel is reciprocal and channel has been generated for rxIdx being
% always greater than txIdx.
if txIdx>rxIdx
  rxIdxUse = txIdx;
  txIdxUse = rxIdx;
  switched = true;
else
  rxIdxUse = rxIdx;
  txIdxUse = txIdx;
  switched = false;
end
end
