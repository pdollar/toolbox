function out = fevalDistr( funNm, jobs, varargin )
% Run simple jobs locally or in distributed fashion using queue.
%
% Runs "feval(funNm,jobs{i}{:})" for each job either locally or across
% cluster. Distibuted queuing system must be installed separately. If
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
% to use the distributed cluster code (must be installed separately).
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
%
% OUTPUTS
%  out        - 1 if jobs completed successfully
%
% EXAMPLE
%
% See also controller, queue
%
% Piotr's Image&Video Toolbox      Version NEW
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

dfs={'type','local','pLaunch',[]};
[type,pLaunch]=getPrmDflt(varargin,dfs,1);
if(strcmp(type,'distr') && ~exist('controller.m','file'))
  warning(['distributed queuing not installed,' ...
    ' switching to type=''local''.']); type='local';  %#ok<WNTAG>
end
nJob = length( jobs );
switch type
  case 'local'
    % run jobs locally using single computational thread
    for i=1:nJob, feval(funNm,jobs{i}{:}); end; out=1;
  case 'parfor'
    % run jobs locally using multiple computational threads
    parfor i=1:nJob, feval(funNm,jobs{i}{:}); end; out=1;
  case 'distr'
    % run jobs using queuing system
    controller('launchQueue',pLaunch{:});
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
