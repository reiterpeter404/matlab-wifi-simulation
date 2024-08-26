% This function plots the WIFI throughput of the different WLAN standards.
% This function was adopted from Matlab's demo function
% 'hCompareWlanThroughput' and changed for the needs of this project.

function plotWlanThroughput( ...
    throughput802_11n, ...      % a row vector representing the 802.11n throughput measurements
    throughput802_11ac, ...     % a row vector representing the 802.11ac throughput measurements
    throughput802_11ax, ...     % a row vector representing the 802.11ax throughput measurements
    throughput802_11axBss ...   % a row vector representing the 802.11ax throughput measurements using different BSS colors
)

fig = figure;
matlab.graphics.internal.themes.figureUseDesktopTheme(fig)

bar([throughput802_11n; throughput802_11ac; throughput802_11ax; throughput802_11axBss]')
legend(["802.11n AP" "802.11ac AP" "802.11ax AP" "802.11ax AP using BSS"],Location="southoutside")

title("Throughput of Each WLAN AP")
xlabel("Number of APs")
ylabel("MAC Throughput (Mbps)")


grid on
end