% Various ways to normalize a (multidimensional) image.
%
% Sets image X to have zero mean and unit variance (if flag==1). 
% Sets image X to range in [0,1] (if flag==2). 
% Sets image X to have zero mean (if flag==3). 
% Sets image X to have zero mean and unit magnitude (if flag==4). 
% Sets image X to have zero mean and unit variance, furthermore throws out 
%   extreme values and normalized to [0,1] (if flag==5)
%
% X may have arbitrary dimension (ie an image or video, etc).  X is treated as a vector of
% pixel values.  Hence, the mean of X is the average pixel value, and likewise the
% standard deviation is the std of the pixels from the mean pixel.
%
% INPUTS
%   X       - n dimensional array to standardize
%   flag    - [optional] determines normalization procedure
%
% OUTPUTS
%   X       - X after normalization.
%
% DATESTAMP
%   18-Jan-2006  5:15pm
%
% EXAMPLE
%   I = double(imread('cameraman.tif'));
%   N = imnormalize(I,1);
%   mean(I(:)), std(I(:)), mean(N(:)), std(N(:))
%
% See also FEVAL_ARRAYS

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function X = imnormalize( X, flag )
    if (isa(X,'uint8')) X = double(X); end;
    if (nargin<2 || isempty(flag)) flag=1; end;
    siz = size(X); nd = ndims(X);  
    
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
        X = imnormalize( X, 1 );
        t=2; 
        X( X<-t )= -t;  
        X( X >t )=  t; 
        X = X/2/t + .5;
       
    else
        error('Unknown standardization procedure');    
    end
