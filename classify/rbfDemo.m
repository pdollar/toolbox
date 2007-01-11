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
% DATESTAMP
%  09-Jan-2007  1:00pm
%
% See also RBFCOMPUTEBASIS, RBFCOMPUTEFEATURES

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 

function rbfDemo( dataType, noiseSig, scale, k, cluster, show )

  %%% generate train/test data
  if( 1 )
    [Xtrain,ytrain] = rbfToyData( 500, noiseSig, dataType );
    [Xtest,ytest]   = rbfToyData( 100, noiseSig, dataType );
  end;

  %%% train/apply rbfs
  rbfBasis = rbfComputeBasis( Xtrain, k, cluster, scale, show )
  rbfWeight = rbfComputeFeatures(Xtrain,rbfBasis) \ ytrain;
  yTrainRes = rbfComputeFeatures(Xtrain,rbfBasis) * rbfWeight;
  yTestRes  = rbfComputeFeatures(Xtest,rbfBasis) * rbfWeight;

  %%% get relative errors
  fracErrorTrain = sum((ytrain-yTrainRes).^2) / sum(ytrain.^2)
  fracErrorTest  = sum((ytest-yTestRes).^2) / sum(ytest.^2)

  %%% visualize surface
  minX = min([Xtrain; Xtest],[],1);  maxX = max([Xtrain; Xtest],[],1);
  if( size(Xtrain,2)==1 )
    xs = linspace( minX, maxX, 1000 )';
    ys = rbfComputeFeatures(xs,rbfBasis) * rbfWeight;
    figure(show+1); clf; hold on;  plot( xs, ys ); 
    plot( Xtrain, ytrain, '.b' );  plot( Xtest, ytest, '.r' ); 
  elseif( size(Xtrain,2)==2 )
    xs1 = linspace(minX(1),maxX(1),25); 
    xs2 = linspace(minX(2),maxX(2),25);
    [xs1,xs2] = ndgrid( xs1, xs2 );
    ys = rbfComputeFeatures([xs1(:) xs2(:)],rbfBasis) * rbfWeight;
    figure(show+1); clf; hold on;  surf( xs1, xs2, reshape(ys,size(xs1)) ); 
    plot3( Xtrain(:,1), Xtrain(:,2), ytrain, '.b' );
    plot3( Xtest(:,1), Xtest(:,2), ytest, '.r' );
  end;

  
  
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

function [X,y] = rbfToyData( N, noiseSig, dataType )
  %% generate data
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