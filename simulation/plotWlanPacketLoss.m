% This function plots the WIFI packet loss of the different WLAN standards.
% This function was adopted from Matlab's demo function
% 'hCompareWlanThroughputs' and was changed for the needs of this project.

function plotWlanPacketLoss( ...
  packetloss802_11n, ...  % a row vector representing the 802.11n packet loss measurements
  packetloss802_11ac, ... % a row vector representing the 802.11ac packet loss measurements
  packetloss802_11ax ...  % a row vector representing the 802.11ax packet loss measurements
)

fig = figure;
matlab.graphics.internal.themes.figureUseDesktopTheme(fig)

bar([packetloss802_11n; packetloss802_11ac; packetloss802_11ax]')
legend(["802.11n AP" "802.11ac AP" "802.11ax AP"],Location="southoutside")

title("Packet loss of Each WLAN AP")
xlabel("Number of APs")
ylabel("Packet Loss (%)")


grid on
end