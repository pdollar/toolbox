% Creates a stack of images from a matlab movie M.
%
% Repeatedly calls frame2im. Useful for playback with playMovie.
%
% USAGE
%  I = movieToImages( M )
%
% INPUTS
%  M   - a matlab movie
%
% OUTPUTS
%  I   - MxNxT array (of images)
%
% EXAMPLE
%  load( 'images.mat' );
%  M = playMovie( videos );
%  I = movieToImages(M);
%  playMovie(I);
%
% See also PLAYMOVIE

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function I = movieToImages( M )

I = fevalArrays( M, @frame2Ii );


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function I = frame2Ii( F )

[I,map] = frame2im( F );
if( isempty(map) )
  if( size(I,3)==3 )
    classname = class( I );
    I = sum(I,3)/3;
    I = feval( classname, I );
  end
else
  I = ind2gray( I, map );
end
