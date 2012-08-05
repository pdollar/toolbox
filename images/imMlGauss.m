function varargout = imMlGauss( G, symmFlag, show )
% Calculates max likelihood params of Gaussian that gave rise to image G.
%
% Suppose G contains an image of a gaussian distribution.  One way to
% recover the parameters of the gaussian is to threshold the image, and
% then estimate the mean/covariance based on the coordinates of the
% thresholded points.  A better method is to do no thresholding and instead
% use all the coordinates, weighted by their value. This function does the
% latter, except in a very efficient manner since all computations are done
% in parallel over the entire image.
%
% This function works over 2D or 3D images.  It makes most sense when G in
% fact contains an image of a single gaussian, but a result will be
% returned regardless.  All operations are performed on abs(G) in case it
% contains negative or complex values.
%
% symmFlag is an optional flag that if set to 1 then imMlGauss recovers
% the maximum likelihood symmetric gaussian.  That is the variance in each
% direction is equal, and all covariance terms are 0.  If symmFlag is set
% to 2 and G is 3D, imMlGauss recovers the ML guassian with equal
% variance in the 1st 2 dimensions (row and col) and all covariance terms
% equal to 0, but a possibly different variance in the 3rd (z or t)
% dimension.
%
% USAGE
%  varargout = imMlGauss( G, [symmFlag], [show] )
%
% INPUTS
%  G        - image of a gaussian (weighted pixels)
%  symmFlag - [0] see above
%  show     - [0] figure to use for optional display
%
% OUTPUTS
%  mu       - 2 or 3 element vector specifying the mean [row,col,z]
%  C        - 2x2 or 3x3 covariance matrix [row,col,z]
%  GR       - image of the recovered gaussian (faster if omitted)
%  logl     - log likelihood of G given recov. gaussian (faster if omitted)
%
% EXAMPLE - 2D
%  R = rotationMatrix( pi/6 );  C=R'*[10^2 0; 0 20^2]*R;
%  G = filterGauss( [200, 300], [150,100], C, 0 );
%  [mu,C,GR,logl] = imMlGauss( G, 0, 1 );
%  mask = maskEllipse( size(G,1), size(G,2), mu, C );
%  figure(2); im(mask)
%
% EXAMPLE - 3D
%  R = rotationMatrix( [1,1,0], pi/4 );
%  C = R'*[5^2 0 0; 0 2^2 0; 0 0 4^2]*R;
%  G = filterGauss( [50,50,50], [25,25,25], C, 0 );
%  [mu,C,GR,logl] = imMlGauss( G, 0, 1 );
%
% See also GAUSS2ELLIPSE, PLOTGAUSSELLIPSES, MASKELLIPSE
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<2 || isempty(symmFlag) ); symmFlag=0; end;
if( nargin<3 || isempty(show) ); show=0; end;

varargout = cell(1,max(nargout,2));
nd = ndims(G);  G = abs(G);
if( nd==2 )
  [varargout{:}] = imMlGauss2D( G, symmFlag, show );
elseif( nd==3 )
  [varargout{:}] = imMlGauss3D( G, symmFlag, show );
else
  error( 'Unsupported dimension for G.  G must be 2D or 3D.' );
end

function [mu,C,GR,logl] = imMlGauss2D( G, symmFlag, show )

% to be used throughout calculations
[ gridCols, gridRows ] = meshgrid( 1:size(G,2), 1:size(G,1)  );
sumG = sum(G(:)); if(sumG==0); sumG=1; end;

% recover mean
muCol = (gridCols .* G); muCol = sum( muCol(:) ) / sumG;
muRow = (gridRows .* G); muRow = sum( muRow(:) ) / sumG;
mu = [muRow, muCol];

% recover sigma
distCols = (gridCols - muCol);
distRows = (gridRows - muRow);
if( symmFlag==0 )
  Ccc = (distCols .^ 2) .* G;   Ccc = sum(Ccc(:)) / sumG;
  Crr = (distRows .^ 2) .* G;   Crr = sum(Crr(:)) / sumG;
  Crc = (distCols .* distRows) .* G;   Crc = sum(Crc(:)) / sumG;
  C = [Crr Crc; Crc Ccc];

elseif( symmFlag==1 )
  sigSq = (distCols.^2 + distRows.^2) .* G;
  sigSq = 1/2 * sum(sigSq(:)) / sumG;
  C = sigSq*eye(2);

else
  error(['Illegal value for symmFlag: ' num2str(symmFlag)]);
end

% get the log likelihood of the data
if (nargout>2)
  GR = filterGauss( size(G), mu, C );
  probs = GR; probs( probs<realmin ) = realmin;
  logl = G .* log( probs );
  logl = sum( logl(:) );
end

% plot ellipses
if (show)
  figure(show); im(G);
  hold('on'); plotGaussEllipses( mu, C, 2 ); hold('off');
end

function [mu,C,GR,logl] = imMlGauss3D( G, symmFlag, show )

% to be used throughout calculations
[gridCols,gridRows,gridZs]=meshgrid(1:size(G,2),1:size(G,1),1:size(G,3));
sumG = sum(G(:));

% recover mean
muCol = (gridCols .* G); muCol = sum( muCol(:) ) / sumG;
muRow = (gridRows .* G); muRow = sum( muRow(:) ) / sumG;
muZ   = (gridZs .* G);   muZ = sum( muZ(:) ) / sumG;
mu = [muRow, muCol, muZ];

% recover C
distCols = (gridCols - muCol);
distRows = (gridRows - muRow);
distZs = (gridZs - muZ);
if( symmFlag==0 )
  distColsG = distCols .* G; distRowsG = distRows .* G;
  Ccc = distCols .* distColsG;    Ccc = sum(Ccc(:));
  Crc = distRows .* distColsG;    Crc = sum(Crc(:));
  Czc = distZs   .* distColsG;    Czc = sum(Czc(:));
  Crr = distRows .* distRowsG;    Crr = sum(Crr(:));
  Czr = distZs   .* distRowsG;    Czr = sum(Czr(:));
  Czz = distZs   .* distZs .* G;  Czz = sum(Czz(:));
  C = [Crr Crc Czr; Crc Ccc Czc; Czr Czc Czz] / sumG;

elseif( symmFlag==1 )
  sigSq = (distCols.^2 + distRows.^2 + distZs .^ 2) .* G;
  sigSq = 1/3 * sum(sigSq(:));
  C = [sigSq 0 0; 0 sigSq 0; 0 0 sigSq] / sumG;

elseif( symmFlag==2 )
  sigSq = (distCols.^2 + distRows.^2) .* G;  sigSq = 1/2 * sum(sigSq(:));
  tauSq = (distZs .^ 2) .* G;  tauSq = sum(tauSq(:));
  C = [sigSq 0 0; 0 sigSq 0; 0 0 tauSq] / sumG;

else
  error(['Illegal value for symmFlag: ' num2str(symmFlag)])
end

% get the log likelihood of the data
if( nargout>2 || (show) )
  GR = filterGauss( size(G), mu, C );
  probs = GR; probs( probs<realmin ) = realmin;
  logl = G .* log( probs );
  logl = sum( logl(:) );
end

% plot G and GR
if( show )
  figure(show); montage2(G);
  figure(show+1); montage2(GR);
end
