function rbfDemo( dataType, noiseSig, scale, k, cluster, show )
% Demonstration of rbf networks for regression.
%
% See rbfComputeBasis for discussion of rbfs.
%
% USAGE
%  rbfDemo( dataType, noiseSig, scale, k, cluster, show )
%
% INPUTS
%  dataType   - 0: 1D sinusoid
%               1: 2D sinusoid
%               2: 2D stretched sinusoid
%  noiseSig   - std of idd gaussian noise
%  scale      - see rbfComputeBasis
%  k          - see rbfComputeBasis
%  cluster    - see rbfComputeBasis
%  show       - figure to use for display (no display if == 0)
%
% OUTPUTS
%
% EXAMPLE
%  rbfDemo( 0, .2, 2, 5, 0, 1 );
%  rbfDemo( 1, .2, 2, 50, 0, 3 );
%  rbfDemo( 2, .2, 5, 50, 0, 5 );
%
% See also RBFCOMPUTEBASIS, RBFCOMPUTEFTRS
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

%%% generate trn/tst data
if( 1 )
  [Xtrn,ytrn] = rbfToyData( 500, noiseSig, dataType );
  [Xtst,ytst] = rbfToyData( 100, noiseSig, dataType );
end;

%%% trn/apply rbfs
rbfBasis = rbfComputeBasis( Xtrn, k, cluster, scale, show );
rbfWeight = rbfComputeFtrs(Xtrn,rbfBasis) \ ytrn;
yTrnRes = rbfComputeFtrs(Xtrn,rbfBasis) * rbfWeight;
yTstRes = rbfComputeFtrs(Xtst,rbfBasis) * rbfWeight;

%%% get relative errors
fracErrorTrn = sum((ytrn-yTrnRes).^2) / sum(ytrn.^2);
fracErrorTst = sum((ytst-yTstRes).^2) / sum(ytst.^2);

%%% display output
display(fracErrorTst);
display(fracErrorTrn);
display(rbfBasis);

%%% visualize surface
minX = min([Xtrn; Xtst],[],1);  maxX = max([Xtrn; Xtst],[],1);
if( size(Xtrn,2)==1 )
  xs = linspace( minX, maxX, 1000 )';
  ys = rbfComputeFtrs(xs,rbfBasis) * rbfWeight;
  figure(show+1); clf; hold on;  plot( xs, ys );
  plot( Xtrn, ytrn, '.b' );  plot( Xtst, ytst, '.r' );
elseif( size(Xtrn,2)==2 )
  xs1 = linspace(minX(1),maxX(1),25);
  xs2 = linspace(minX(2),maxX(2),25);
  [xs1,xs2] = ndgrid( xs1, xs2 );
  ys = rbfComputeFtrs([xs1(:) xs2(:)],rbfBasis) * rbfWeight;
  figure(show+1); clf; surf( xs1, xs2, reshape(ys,size(xs1)) ); hold on;
  plot3( Xtrn(:,1), Xtrn(:,2), ytrn, '.b' );
  plot3( Xtst(:,1), Xtst(:,2), ytst, '.r' );
end

function [X,y] = rbfToyData( N, noiseSig, dataType )
% Toy data for rbfDemo.
%
% USAGE
%  [X,y] = rbfToyData( N, noiseSig, dataType )
%
% INPUTS
%  N          - number of points
%  dataType   - 0: 1D sinusoid
%               1: 2D sinusoid
%               2: 2D stretched sinusoid
%  noiseSig   - std of idd gaussian noise
%
% OUTPUTS
%  X          - [N x d] N points of d dimensions each
%  y          - [1 x N] value at example i

%%% generate data
if( dataType==0 )
  X = rand( N, 1 ) * 10;
  y = sin( X );
elseif( dataType==1 )
  X = rand( N, 2 ) * 10;
  y = sin( X(:,1)+X(:,2) );
elseif( dataType==2 )
  X = rand( N, 2 ) * 10;
  y = sin( X(:,1)+X(:,2) );
  X(:,2) = X(:,2) * 5;
else
  error('unknown dataType');
end
y = y + randn(size(y))*noiseSig;
