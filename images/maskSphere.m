function mask = maskSphere( d, r, show )
% Creates an 'image' of a n-dimensional hypersphere.
%
% Useful for testing visualization procedures.
%
% Create a d-dimensional matrix mask of dimensions [s x s x s x ... x s]
% where s=2r+1.  Each element mask(x1,x2...,xd) is 1 if (x1,...xd) falls
% inside the centered hypersphere of rad r.
%
% In 1d this corresponds to a vector of the form [.. 0 1 1 1 1 1 0 ..]
% In 2d this corresponds to an image of a white circle.
% In 3d and 4d, well try it and 'see' what it looks like.
% 
% USAGE
%  mask = maskSphere( d, r, [show] )
%
% INPUTS
%  d         - dimension (any positive integer)
%  r         - sphere integer radius 
%  show      - [] figure in which to display results
%
% OUTPUTS
%  mask      - [s x s x s x ... x s] hypersphere image
%
% EXAMPLE
%  mcircle = maskSphere( 2, 20, 1 );
%  msphere = maskSphere( 3, 10, 2 );
%  msphere = maskSphere( 4, 10, 3 );
%
% See also MASKCIRCLE, MONTAGE2
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.0
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<3 || isempty(show) ); show = 1; end

xs=cell(1,d); 
for i=1:d; xs{i}=-r:r; end
if( d>1 ); [xs{:}] = ndgrid(xs{:}); else xs{1}=xs{1}'; end
mask=xs{1}.^2; 
for i=2:d; mask=mask+xs{i}.^2; end
mask = double( mask < (r+1)^2 );

if( show )
  figure(show); clf;
  if( d<=2 ) 
    im( mask );
  elseif any(d==3:4)
    montage2( mask );
  else 
    disp('no visualization available for d>4');
  end
end
