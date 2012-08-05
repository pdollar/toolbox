function [ys,ysCum] = fernsRegApply( data, ferns, inds )
% Apply learned fern regressor.
%
% USAGE
%  [ys,ysCum] = fernsRegApply( data, ferns, [inds] )
%
% INPUTS
%  data     - [NxF] N length F binary feature vectors
%  ferns    - learned fern regression model
%  inds     - [NxM] cached inds (from previous call to fernsInds)
%
% OUTPUTS
%  ys       - [Nx1] predicted output values
%  ysCum    - [NxM] predicted output values after each regressor
%
% EXAMPLE
%
% See also fernsRegTrain, fernsInds
%
% Piotr's Image&Video Toolbox      Version 2.50
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]
if( nargin<3 || isempty(inds) )
  inds = fernsInds(data,ferns.fids,ferns.thrs); end; [N,M]=size(inds);
if( nargout==1 )
  ys=zeros(N,1); for m=1:M, ys = ys + ferns.ysFern(inds(:,m),m); end
else
  ysCum=zeros(N,M+1);
  for m=1:M, ysCum(:,m+1) = ysCum(:,m) + ferns.ysFern(inds(:,m),m); end
  ysCum=ysCum(:,2:end); ys=ysCum(:,end);
end
