% load the distancne of the stations relatively to the AP
function [staPoints] = loadStaDistances( ...
  distnace ...  % the distance to the AP
)

staPoints = [
  -distnace, 0 ,0;
  distnace, 0, 0;
  0, -distnace, 0;
  0, distnace, 0;
  0, 0, -distnace;
  0, 0, distnace;
];
end