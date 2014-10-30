function X = imNormalize( X, flag )
% Various ways to normalize a (multidimensional) image.
%
% X may have arbitrary dimension (ie an image or video, etc).  X is treated
% as a vector of pixel values.  Hence, the mean of X is the average pixel
% value, and likewise the standard deviation is the std of the pixels from
% the mean pixel.
%
% USAGE
%  X = imNormalize( X, flag )
%
% INPUTS
%  X       - n dimensional array to standardize
%  flag    - [1] determines normalization procedure. Sets X to:
%            1: have zero mean and unit variance
%            2: range in [0,1]
%            3: have zero mean 
%            4: have zero mean and unit magnitude
%            5: zero mean/unit variance, throws out extreme values 
%               and also normalizes to [0,1]
%
% OUTPUTS
%  X       - X after normalization.
%
% EXAMPLE
%  I = double(imread('cameraman.tif'));
%  N = imNormalize(I,1);
%  [mean(I(:)), std(I(:)), mean(N(:)), std(N(:))]
%
% See also FEVALARRAYS
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.0
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

if (isa(X,'uint8')); X = double(X); end
if (nargin<2 || isempty(flag)); flag=1; end
siz = size(X);

if( flag==1 || flag==3 || flag==4 )
  % set X to have zero mean
  X = X(:);  n = length(X);
  meanX = sum(X)/n;
  X = X - meanX;

  % set X to have unit std
  if( flag==1 || flag==4 )
    sumX2 = sum(X.^2);
    if( sumX2>0 )
      if( flag==4 )
        X = X / sqrt(sumX2);
      else
        X = X / sqrt(sumX2/n);
      end
    end
  end
  X = reshape(X,siz);

elseif(flag==2)
  % set X to range in [0,1]
  X = X - min(X(:));  X = X / max(X(:));

elseif( flag==5 )
  X = imNormalize( X, 1 );
  t=2;
  X( X<-t )= -t;
  X( X >t )=  t;
  X = X/2/t + .5;

else
  error('Unknown standardization procedure');
end
