% Select a WLAN standard by the given number. The possible options are 802.11n/ac/ax.

function [wifiStandard] = selectWifiStandard( ...
  cnt, ...             % the selector for the standard
  channelBandwidth ... % 802.11n does not support 80e6 or more
)

selections = 3;
% use only 802.11ac and 802.11ax on channel bandwidth above 40 MHz
if channelBandwidth > 40e6
  selections = 2;
end

switch(mod(cnt, selections))
  case 0
    wifiStandard = 5;
  case 1
    wifiStandard = 6;
  case 2
    wifiStandard = 4;
  otherwise
    throw(MException('SelectWlanStandard:outOfRange', 'Variable %s out of range!', cnt))
end
end