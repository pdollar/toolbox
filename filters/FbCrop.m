function FBC = FbCrop( FB, delta )
% Crop a 2D filterbank (adjusting filter norms).
%
% Takes a filter bank and crops it by cropping off delta pixels from each
% side. Ensures that the mean response of each filter is 0 and that the L1
% norm is 1, i.e. sum(sum(abs(F)))==1.
%
% USAGE
%  FBC = FbCrop( FB, delta )
%
% INPUTS
%  FB       - original filterbank
%  delta    - amount to crop by
%
% OUTPUTS
%  FBC      - cropped filterbank
%
% EXAMPLE
%  load FbDoG.mat;  FBC=FbCrop(FB,4);
%  figure(1); montage2(FB,struct('extraInfo',1));
%  figure(2); montage2(FBC,struct('extraInfo',1));
%
% See also FBAPPLY2D
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.0
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

nd = ndims(FB);
if( nd~=2 && nd~=3 ); error('I must an MxNxK array'); end

cropsiz = size(FB);
cropsiz = [cropsiz(1:2)-2*delta, cropsiz(3)];
FBC = arrayToDims( FB, cropsiz );

for f=1:size(FB,3)
  FC = FBC(:,:,f);
  FC = FC - sum(sum(FC)) / numel(FC); % 0 mean
  FC = FC / sum(sum(abs(FC))); % L1 norm == 1
  FBC(:,:,f) = FC;
end
