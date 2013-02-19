function fevalDistrDisk( funNm, jobDir, jobId )
% Helper for fevalDistr (do no call directly).
%
% USAGE
%  fevalDistrDisk( funNm, jobDir, jobId )
%
% INPUTS
%
% OUTPUTS
%
% EXAMPLE
%
% See also fevalDistr
%
% Piotr's Image&Video Toolbox      Version 3.02
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]
jobId=[jobDir int2str2(str2double(jobId),10)];
fIn=[jobId '-in.mat']; if(exist(fIn,'file')~=2), return; end
job=load(fIn); job=job.job;
r=feval(funNm,job{:}); save([jobId '-out'],'r'); %#ok<NASGU>
f=fopen([jobId '-done'],'w'); fclose(f);
end
