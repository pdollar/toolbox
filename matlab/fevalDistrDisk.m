function fevalDistrDisk( funNm, jobNm )
% Helper for fevalDistr (do no call directly).
%
% USAGE
%  fevalDistrDisk( funNm, jobNm )
%
% INPUTS
%
% OUTPUTS
%
% EXAMPLE
% 
% See also fevalDistr
% 
% Piotr's Image&Video Toolbox      Version NEW
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]
job=load([jobNm '-in']); job=job.job;
r=feval(funNm,job{:}); save([jobNm '-out'],'r'); %#ok<NASGU>
f=fopen([jobNm '-done'],'w'); fclose(f);
end
