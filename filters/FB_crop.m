% Crop a 2D filterbank (adjusting filter norms).
%
% Takes a filter bank and crops it by cropping off delta from each side. Ensuresthat the
% mean response of each filter is 0 and that the L1 norm is 1, i.e. sum(sum(abs(F)))==1.  
%
% INPUTS
%   FB      - original filterbank
%   delta   - amount to crop by
%
% OUTPUTS
%   FBC - cropped filterbank
%
% DATESTAMP
%   29-Sep-2005  2:00pm

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function FBC = FB_crop( FB, delta )
    nd = ndims(FB);
    if( nd~=2 || nd~=3  ) error('I must an MxNxK array'); end;

    cropsiz = size(FB);  cropsiz = [cropsiz(1:2)-2*delta, cropsiz(3)];
    FBC = arraycrop2dims( FB, cropsiz ); % crop

    for f=1:size(FB,3)
        FC = FBC(:,:,f);
        FC = FC - sum(sum(FC)) / prod(size(FC)); % 0 mean
        FC = FC / sum(sum(abs(FC))); % L1 norm == 1 
        FBC(:,:,f) = FC;
    end;
