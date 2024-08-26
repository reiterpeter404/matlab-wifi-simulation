% Create an AP node with the given parameters

function [apNode] = createApNodeWithOverlappingChannel( ...
    networkSimulator, ... % the network simulator of the project
    colorIndex, ...       % the color index of the AP (if 802.11ax)
//     obssThreshold, ...    % the OBSS threshold of the AP
    apIndex, ...          % the index of the AP
    position, ...         % the position of the AP
    wifiStandard, ...     % the selected 802.11 standard (n/ac/ax)
    channelBandwidth ...  % the channel bandwidth
)

% select the 5 GHz channel depending on the AP index
switch (mod(apIndex, 10))
    case 0:
        selectedChannel = [5 116];
    case 1:
        selectedChannel = [5 120];
    case 2:
        selectedChannel = [5 112];
    case 3:
        selectedChannel = [5 124];
    case 4:
        selectedChannel = [5 108];
    case 5:
        selectedChannel = [5 128];
    case 6:
        selectedChannel = [5 104];
    case 7:
        selectedChannel = [5 132];
    case 8:
        selectedChannel = [5 100];
    case 9:
        selectedChannel = [5 136];
end

deviceConfig = wlanDeviceConfig();
deviceConfig.Mode = "AP";
deviceConfig.BandAndChannel = selectedChannel;
deviceConfig.DisableRTS = true;
deviceConfig.ChannelBandwidth = channelBandwidth;

switch (wifiStandard)
    case 4  % 802.11n configuration
        deviceConfig.TransmissionFormat = 'HT-Mixed';
        deviceConfig.MCS=0;
        deviceConfig.BSSColor = 0;

    case 5  % 802.11ac configuration
        deviceConfig.TransmissionFormat = 'VHT';
        deviceConfig.MCS=3;
        deviceConfig.BSSColor = 0;

    case 6  % 802.11ax configuration
        deviceConfig.TransmissionFormat = 'HE-SU';
        deviceConfig.MCS=4;
        deviceConfig.BSSColor = colorIndex;
//         deviceConfig.OBSSPDThreshold = obssThreshold;

    % throw exception, if an incorrect number is selected for the 802.11 standard
    otherwise
        throw(MException('CreateAPNode:outOfRange', 'Variable %s out of range!', wifiStandard))
end

apNode = wlanNode( ...
    Name=strcat("AP",num2str(apIndex)), ...
    Position=position ,...
    DeviceConfig=deviceConfig ...
);
end