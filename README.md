# matlab-wifi-simulation

## General information

Creates a Wireless Fidelity (WiFi) simulation in Matlab with access points (APs) of different standards in a dense area.
The simulation runs an AP of the selected standard and simulates a data transfer to six different stations (STAs) in the
specified distance. The AP is used as a device under test (DUT) for the simulation, where the throughput and the packet
loss of the device is measured.

The measurements are taken with APs of these standards:

* 802.11n
* 802.11ac
* 802.11ax

After the measurement with an AP of each standard, an additional AP is installed in the same area, and the measurements
on the DUT is repeated. Adding new APs to the simulation is repeated, until the _positionCount_ is reached. At the end
of the simulation, a comparison of the throughput and packet loss is viewed in a bar graph.

## References

The program in this repository was created by the Matlab example code
of [Spatial Reuse with BSS Coloring in 802.11ax Network Simulation](https://www.mathworks.com/help/wlan/ug/spatial-reuse-with-bss-coloring-in-an-802.11ax-network-simulation.html).
All functions from this example are marked with the copyright of The MathWorks, Inc.

## Parameters

| Parameter        | type   | Description                                                                                                                                                                                           |
|------------------|--------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| positionCount    | number | Maximum number of APs that are installed in the simulation (including the DUT).                                                                                                                       |
| t_simulation     | number | Duration of the simulation in seconds.                                                                                                                                                                |
| channelBandwidth | number | Bandwidth of the channel for the measurement in Hz. This value is 20e6, 40e6 and 80e6. Please consider that 802.11n does not support 80e6. If this bandwidth is selected, no 802.11n AP is installed. |
|                  |        |                                                                                                                                                                                                       |
|                  |        |                                                                                                                                                                                                       |
|                  |        |                                                                                                                                                                                                       |
|                  |        |                                                                                                                                                                                                       |
|                  |        |                                                                                                                                                                                                       |
|                  |        |                                                                                                                                                                                                       |
|                  |        |                                                                                                                                                                                                       |
|                  |        |                                                                                                                                                                                                       |
|                  |        |                                                                                                                                                                                                       |