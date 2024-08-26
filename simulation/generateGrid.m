% Create a 3 x 3 x 3 grid with the given distance, using the point (0/0/0)
% as a center. The list of points will be ordered by the distance to the
% center. If two points have the same distance to the center, the negative
% value is used before. If these two points have the same distance, the
% points are ordered by the x, y and z axis.

function sortedCoords = generateGrid( ...
    distance ...  % the distance from one point to another
)

% define the range for the cube (min:interval:max) and create the grid
range = -distance:distance:distance;
[X, Y, Z] = ndgrid(range, range, range);

% Reshape the matrices into column vectors and calculate distances
coords = [X(:), Y(:), Z(:)];
distances = sqrt(sum(coords.^2, 2));

% combine coordinates and distances and order them by the center distance
data = [coords, distances];
sortedData = sortrows(data, [4, 1, 2, 3]);
sortedCoords = sortedData(:, 1:3);

end