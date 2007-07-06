% Crop a 2D filterbank (adjusting filter norms).
%
% Takes a filter bank and crops it by cropping off delta pixels from each
% side. Ensures that the mean response of each filter is 0 and that the L1
% norm is 1, i.e. sum(sum(abs(F)))==1.
%
% USAGE
%  FBC = FB_crop( FB, delta )
%
% INPUTS
%  FB       - original filterbank
%  delta    - amount to crop by
%
% OUTPUTS
%  FBC      - cropped filterbank
%
% EXAMPLE
%  load FB_DoG.mat;  FBC=FB_crop(FB,4);
%  figure(1); montage2(FB,1,1);
%  figure(2); montage2(FBC,1,1);
%
% See also FB_APPLY_2D

% Piotr's Image&Video Toolbox      Version 1.5
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!
 
function FBC = FB_crop( FB, delta )

nd = ndims(FB);
if( nd~=2 && nd~=3 ); error('I must an MxNxK array'); end

cropsiz = size(FB);
cropsiz = [cropsiz(1:2)-2*delta, cropsiz(3)];
FBC = arraycrop2dims( FB, cropsiz );

for f=1:size(FB,3)
  FC = FBC(:,:,f);
  FC = FC - sum(sum(FC)) / numel(FC); % 0 mean
  FC = FC / sum(sum(abs(FC))); % L1 norm == 1
  FBC(:,:,f) = FC;
end

