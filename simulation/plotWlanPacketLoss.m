% This function plots the WIFI packet loss of the different WLAN standards.
% This function was adopted from Matlab's demo function
% 'hCompareWlanThroughputs' and was changed for the needs of this project.

function plotWlanPacketLoss( ...
    packetLoss802_11n, ...      % a row vector representing the 802.11n packet loss measurements
    packetLoss802_11ac, ...     % a row vector representing the 802.11ac packet loss measurements
    packetLoss802_11ax, ...     % a row vector representing the 802.11ax packet loss measurements
    packetLoss802_11axBss ...   % a row vector representing the 802.11ax packet loss measurements using different BSS colors
)

fig = figure;
matlab.graphics.internal.themes.figureUseDesktopTheme(fig)

bar([packetLoss802_11n; packetLoss802_11ac; packetLoss802_11ax; packetLoss802_11axBss]')
legend(["802.11n AP" "802.11ac AP" "802.11ax AP" "802.11ax AP with BSS"],Location="southoutside")

title("Packet loss of Each WLAN AP")
xlabel("Number of APs")
ylabel("Packet Loss (%)")


grid on
end