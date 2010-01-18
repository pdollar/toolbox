function out = fevalDistr( funNm, jobs, varargin )
% Run simple jobs locally or in distributed fashion using queue.
%
% Runs "feval(funNm,jobs{i}{:})" for each job either locally or across
% cluster. Distributed queuing system must be installed separately. If
% queuing system is not installed, this function can still be called with
% either the 'local' or 'pafor' options. jobs should be a cell array of
% length nJob. Each job itself should be a cell array of parameters to pass
% to funNm. funNm must be a valid function in the path. The function funNm
% must return a dummy value, although this value will be ignored. Instead,
% typically funNm should write its results to disk.
%
% If using type='local', jobs are executed using simple for loop. If using
% type='parfor', the for loop is a parfor loop, make sure to setup matlab
% workers first using "matlabpool open nWorkers". If type='distr' attempts
% to use the distributed cluster code (must be installed separately);
% defaults to 'local' if cluster code not found.
%
% USAGE
%  out = fevalDistr( funNm, jobs, [varargin] )
%
% INPUTS
%  funNm      - name of function that will process jobs
%  jobs       - [1xnJob] cell array of parameters for each job
%  varargin   - additional params (struct or name/value pairs)
%   .type       - ['local'], 'parfor' or 'distr'
%   .pLaunch    - [] parameter to controller('launchQueue',pLaunch{:})
%   .group      - [1] send jobs in batches (only relevant if type='distr')
%
% OUTPUTS
%  out        - 1 if jobs completed successfully
%
% EXAMPLE
%
% See also controller, queue
%
% Piotr's Image&Video Toolbox      Version 2.41
% Copyright 2009 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

dfs={'type','local','pLaunch',[],'group',1};
[type,pLaunch,group]=getPrmDflt(varargin,dfs,1);
if(strcmp(type,'distr') && ~exist('controller.m','file'))
  warning(['distributed queuing not installed,' ...
    ' switching to type=''local''.']); type='local';  %#ok<WNTAG>
end
nJob=length(jobs); if(nJob==0), out=1; return; end
switch type
  case 'local'
    % run jobs locally using single computational thread
    tid=ticStatus('collecting jobs'); out=1;
    for i=1:nJob, feval(funNm,jobs{i}{:}); tocStatus(tid,i/nJob); end
  case 'parfor'
    % run jobs locally using multiple computational threads
    parfor i=1:nJob, feval(funNm,jobs{i}{:}); end; out=1;
  case 'distr'
    % run jobs using queuing system
    controller('launchQueue',pLaunch{:});
    if( group>1 )
      nJobGrp=ceil(nJob/group); jobsGrp=cell(1,nJobGrp); k=0;
      for i=1:nJobGrp, k1=min(nJob,k+group);
        jobsGrp{i}={funNm,jobs(k+1:k1),'type','local'}; k=k1; end
      nJob=nJobGrp; jobs=jobsGrp; funNm='fevalDistr';
    end
    jids=controller('jobsAdd',nJob,funNm,jobs);
    disp('Sent jobs...'); tid=ticStatus('collecting jobs'); k=0;
    while( 1 )
      jids1=controller('jobProbe',jids);
      if(isempty(jids1)), pause(.1); continue; end
      jid=jids1(1); [d,err]=controller('jobRecv',jid);
      if(~isempty(err)), disp('ABORTING'); out=0; break; end
      k=k+1; tocStatus(tid,k/nJob); if(k==nJob), out=1; break; end
    end; controller('closeQueue');
  otherwise, assert(false);
end
end
