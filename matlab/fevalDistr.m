function [out,res] = fevalDistr( funNm, jobs, varargin )
% Wrapper for embarrassingly parallel function evaluation.
%
% Runs "r=feval(funNm,jobs{i}{:})" for each job in a parallel manner. jobs
% should be a cell array of length nJob and each job should be a cell array
% of parameters to pass to funNm. funNm must be a function in the path and
% must return a single value (which may be a dummy value if funNm writes
% results to disk). Different forms of parallelization are supported
% depending on the hardware and Matlab toolboxes available. The type of
% parallelization is determined by the parameter 'type' described below.
%
% type='LOCAL': jobs are executed using a simple "for" loop. This implies
% no parallelization and is the default fallback option.
%
% type='PARFOR': jobs are executed using a "parfor" loop. This option is
% only available if the Matlab *Parallel Computing Toolbox* is installed.
% Make sure to setup Matlab workers first using "matlabpool open".
%
% type='DISTR': jobs are executed on the Caltech cluster. Distributed
% queuing system must be installed separately. Currently this option is
% only supported on the Caltech cluster but could easily be installed on
% any Linux cluster as it requires only SSH and a shared filesystem.
% Parameter pLaunch is used for controller('launchQueue',pLaunch{:}) and
% determines cluster machines used (e.g. pLaunch={48,401:408}).
%
% type='COMPILED': jobs are executed locally in parallel by first compiling
% an executable and then running it in background. This option requires the
% *Matlab Compiler* to be installed (but does NOT require the Parallel
% Computing Toolbox). Compiling can take 1-10 minutes, so use this option
% only for large jobs. (On Linux alter startup.m by calling addpath() only
% if ~isdeployed, otherwise will get error about "CTF" after compiling).
% Note that relative paths will not work after compiling so all paths used
% by funNm must be absolute paths.
%
% type='WINHPC': jobs are executed on a Windows HPC Server 2008 cluster.
% Similar to type='COMPILED', except after compiling, the executable is
% queued to the HPC cluster where all computation occurs. This option
% likewise requires the *Matlab Compiler*. Paths to data, etc., must be
% absolute paths and available from HPC cluster. Parameter pLaunch should
% have two fields 'scheduler' and 'shareDir' that define the HPC Server.
% For example, at MSR one possible cluster is defined by scheduler =
% 'MSR-L25-DEV21' and shareDir = '\\msr-arrays\scratch\msr-pool\L25-dev21'.
%
% USAGE
%  [out,res] = fevalDistr( funNm, jobs, [varargin] )
%
% INPUTS
%  funNm      - name of function that will process jobs
%  jobs       - [1xnJob] cell array of parameters for each job
%  varargin   - additional params (struct or name/value pairs)
%   .type       - ['local'], 'parfor', 'distr', 'compiled', 'winhpc'
%   .pLaunch    - [] extra params for type='distr' or type='winhpc'
%   .group      - [1] send jobs in batches (only relevant if type='distr')
%
% OUTPUTS
%  out        - 1 if jobs completed successfully
%  res        - [1xnJob] cell array containing results of each job
%
% EXAMPLE
%  % Note: in this case parallel versions are slower since conv2 is so fast
%  n=16; jobs=cell(1,n); for i=1:n, jobs{i}={rand(500),ones(25)}; end
%  tic, [out,J1] = fevalDistr('conv2',jobs,'type','local'); toc,
%  tic, [out,J2] = fevalDistr('conv2',jobs,'type','parfor'); toc,
%  tic, [out,J3] = fevalDistr('conv2',jobs,'type','compiled'); toc
%  [isequal(J1,J2), isequal(J1,J3)], figure(1); montage2(cell2array(J1))
%
% See also matlabpool mcc
%
% Piotr's Image&Video Toolbox      Version NEW
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

dfs={'type','local','pLaunch',[],'group',1};
[type,pLaunch,group]=getPrmDflt(varargin,dfs,1);
if(strcmp(type,'distr') && ~exist('controller.m','file'))
  warning(['distributed queuing not installed,' ...
    ' switching to type=''local''.']); type='local';  %#ok<WNTAG>
end
nJob=length(jobs); res=cell(1,nJob); store=(nargout==2);
if(nJob==0), out=1; return; end
switch lower(type)
  case 'local'
    % run jobs locally using for loop
    tid=ticStatus('collecting jobs'); out=1;
    for i=1:nJob, r=feval(funNm,jobs{i}{:});
      if(store), res{i}=r; end; tocStatus(tid,i/nJob); end
    
  case 'parfor'
    % run jobs locally using parfor loop
    parfor i=1:nJob, r=feval(funNm,jobs{i}{:});
      if(store), res{i}=r; end; end; out=1;
    
  case 'compiled'
    % run jobs locally in background in parallel using compiled code
    t=clock; t=mod(t(end),1); t=round((t+rand)/2*1e15);
    tDir=sprintf('temp-%015i/',t); mkdir(tDir);
    fprintf('Compiling (this may take a while)...\n');
    mcc('-m','fevalDistrDisk','-d',tDir,'-a',funNm);
    cmd=[tDir 'fevalDistrDisk ' funNm ' ' tDir ' ']; i=0; k=0;
    Q=feature('numCores'); q=0; tid=ticStatus('collecting jobs');
    while( 1 )
      while(q<Q && i<nJob), q=q+1; i=i+1; jobSave(tDir,jobs{i},i);
        if(ispc), system2(['start /B /min ' cmd int2str2(i,10)],0);
        else system2([cmd int2str2(i,10) ' &'],0); end
      end
      fs=dir([tDir '*-done']); fs={fs.name}; k1=length(fs); k=k+k1; q=q-k1;
      for i1=1:k1, [ind,r]=jobLoad(tDir,fs{i1},store); res{ind}=r; end
      pause(1); tocStatus(tid,k/nJob); if(k==nJob), out=1; break; end
    end
    for i=1:10, try rmdir(tDir,'s');break;catch,pause(1),end;end %#ok<CTCH>
    
  case 'winhpc'
    % run jobs using Windows HPC Server
    dfs={'shareDir','REQ','scheduler','REQ'};
    [shareDir,scheduler]=getPrmDflt(pLaunch,dfs,1);
    t=clock; t=mod(t(end),1); t=round((t+rand)/2*1e15);
    tDir=[shareDir sprintf('\\temp-%015i\\',t)]; mkdir(tDir);
    fprintf('Compiling (this may take a while)...\n');
    mcc('-m','fevalDistrDisk','-d',tDir,'-a',funNm);
    for i=1:nJob, jobSave(tDir,jobs{i},i); end
    scheduler=[' /scheduler:' scheduler ' '];
    m=system2(['job new /failontaskfailure:true' scheduler],1);
    jid=m(isstrprop(m,'digit')); nJobStr=int2str(nJob);
    system2(['job add ' jid ' -workdir:' tDir ' -parametric:1-' nJobStr ...
      scheduler ' fevalDistrDisk ' funNm ' ' tDir ' *'],1);
    system2(['job submit /id:' jid scheduler],1);
    tid=ticStatus('collecting jobs'); k=0;
    while( 1 )
      m=system2(['job view ' jid scheduler],0);
      [~,j]=regexp(m,'State\s*: '); m1=m(j+1:j+6);
      if(strcmpi('failed',m1)), disp('ABORTING'); out=0; break; end
      fs=dir([tDir '*-done']); fs={fs.name}; k1=length(fs); k=k+k1;
      for i1=1:k1, [ind,r]=jobLoad(tDir,fs{i1},store); res{ind}=r; end
      pause(1); tocStatus(tid,k/nJob); if(k==nJob), out=1; break; end
    end
    for i=1:10, try rmdir(tDir,'s');break;catch,pause(1),end;end %#ok<CTCH>
    
  case 'distr'
    % run jobs using Linux queuing system
    controller('launchQueue',pLaunch{:});
    if( group>1 )
      nJobGrp=ceil(nJob/group); jobsGrp=cell(1,nJobGrp); k=0;
      for i=1:nJobGrp, k1=min(nJob,k+group);
        jobsGrp{i}={funNm,jobs(k+1:k1),'type','local'}; k=k1; end
      nJob=nJobGrp; jobs=jobsGrp; funNm='fevalDistr';
    end
    jids=controller('jobsAdd',nJob,funNm,jobs); k=0;
    fprintf('Sent %i jobs...\n',nJob); tid=ticStatus('collecting jobs');
    while( 1 )
      jids1=controller('jobProbe',jids);
      if(isempty(jids1)), pause(.1); continue; end
      jid=jids1(1); [r,err]=controller('jobRecv',jid);
      if(~isempty(err)), disp('ABORTING'); out=0; break; end
      k=k+1; if(store), res{jid==jids}=r; end
      tocStatus(tid,k/nJob); if(k==nJob), out=1; break; end
    end; controller('closeQueue');
    
  otherwise, error('unkown type: ''%s''',type);
end
end

function jobSave( tDir, job, ind ) %#ok<INUSL>
% Helper: save job to temporary file for use with fevalDistrDisk()
save([tDir int2str2(ind,10) '-in'],'job');
end

function [ind,r] = jobLoad( tDir, f, store )
% Helper: load job and delete temporary files from fevalDistrDisk()
ind=str2double(f(end-14:end-5)); f=[tDir int2str2(ind,10)];
if(store), r=load([f '-out']); r=r.r; else r=[]; end
fs={[f '-done'],[f '-in.mat'],[f '-out.mat']};
delete(fs{:}); pause(.1); exist1=@(f) exist(f,'file')==2;
while( exist1(fs{1}) || exist1(fs{2}) || exist1(fs{3}) )
  warning('Waiting for files to delete.'); pause(5); end %#ok<WNTAG>
end

function msg = system2( cmd, show )
% Helper: wraps system() call
[status,msg]=system(cmd); msg=msg(1:end-1);
if(status), error(msg); end
if(show), disp(msg); end
end
