function clrs = uniqueColors( m, n, show )
% Generate m*n visually distinct RGB colors suitable for display.
%
% Useful when more than the 6 standard 'rgbcym' colors are needed for
% display. Generate m*n colors by sampling at constant intervals in HSV in
% the H and S channels (while keeping V fixed at 1). In addition, for every
% other level of saturation the H values are offset by half an interval to
% further distinguish each color. Inspired by a blog entry by Bart Mossey
% http://fob.po8.org/node/398, HOWTO: Picking "random colors".
%
% USAGE
%  clrs = uniqueColors( m, n, [show] )
%
% INPUTS
%  m      - number of saturation levels
%  n      - number of distinct hues to use
%  show   - optional display of colors
%
% OUTPUTS
%  clrs   - [m*n x 3] array of rgb colors
%
% EXAMPLE - standard 6 fully saturated colors
%  clrs = uniqueColors(1,6,1);
%
% EXAMPLE - 24 colors used to plot some points
%  clrs = uniqueColors(4,6,1);
%  figure(2); clf; hold on; n=size(clrs,1);
%  for i=1:n, plot(mod(i-1,6),i,'.','color',clrs(i,:)); end
%
% See also HSV2RGB
%
% Piotr's Image&Video Toolbox      Version 2.20
% Copyright 2009 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

if(nargin<3 || isempty(show)), show=0; end

% generate n evenly spaced HUE values
H=0:1/n:1; H=H(ones(1,m),1:end-1);

% stradle every other row of HUES to further differentiate them
H(2:2:end,:)=mod(H(2:2:end,:)+1/n/2,1);

% generate m saturation levels starting (omit 0)
S=linspace(0,1,m+1); S=repmat(S(:,end:-1:2)',1,n);

% always set the value to 1.0
V=1.0*ones(m,n);

% create HSV image
clrs=hsv2rgb(cat(3,H,S,V));

% optionally display
if(show), figure(show); clf; imagesc(clrs); axis image; end

% flatten
clrs = permute(clrs,[2 1 3]);
clrs = reshape(clrs,m*n,3);

end

