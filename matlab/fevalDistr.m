function [out,res] = fevalDistr( funNm, jobs, varargin )
% Run simple jobs locally or in distributed fashion using queue.
%
% Runs "r=feval(funNm,jobs{i}{:})" for each job either locally or across
% cluster. Distributed queuing system must be installed separately. If
% queuing system is not installed, this function can still be called with
% either the 'local' or 'parfor' options. jobs should be a cell array of
% length nJob. Each job should be a cell array of parameters to pass to
% funNm. funNm must be a function in the path and must return a single
% value (which may be a dummy value if funNm writes its results to disk).
%
% If using type='local', jobs are executed using simple for loop. If using
% type='parfor', the for loop is a parfor loop, make sure to setup matlab
% workers first using "matlabpool open nWorkers". If type='distr' attempts
% to use the distributed cluster code (must be installed separately);
% defaults to 'local' if cluster code not found.
%
% USAGE
%  [out,res] = fevalDistr( funNm, jobs, [varargin] )
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
%  res        - [1xnJob] cell array containing results of each job
%
% EXAMPLE
%  n=16; jobs=cell(1,n); for i=1:n, jobs{i}={rand(500),ones(25)}; end
%  tic, [out,J] = fevalDistr('conv2',jobs,'type','local'); toc,
%  tic, [out,J] = fevalDistr('conv2',jobs,'type','parfor'); toc,
%  pDistr={'type','distr','pLaunch',{48,401:408}};
%  tic, [out,J] = fevalDistr('conv2',jobs,pDistr{:}); toc
%  figure(1); montage2(cell2array(J))
%
% See also controller, queue
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
switch type
  case 'local'
    % run jobs locally using for loop
    tid=ticStatus('collecting jobs'); out=1;
    for i=1:nJob, r=feval(funNm,jobs{i}{:});
      if(store), res{i}=r; end; tocStatus(tid,i/nJob); end
    
  case 'parfor'
    % run jobs locally using parfor loop
    parfor i=1:nJob, r=feval(funNm,jobs{i}{:});
      if(store), res{i}=r; end; end; out=1;
    
  case 'parallel-windows'
    % run jobs locally using multiple threads by compiling windows exe
    t=clock; t=mod(t(end),1); t=round((t+rand)/2*1e15);
    tDir=sprintf('temp-%15i\\',t); mkdir(tDir); fprintf('Compiling...\n');
    mcc('-m','fevalDistrDisk','-d',tDir,'-a',funNm);
    cmd=['start /B /min ' tDir 'fevalDistrDisk.exe ' funNm];
    Q=feature('numCores'); q=0; i=0; k=0; tid=ticStatus('collecting jobs');
    while( 1 )
      while( q<Q && i<nJob ), q=q+1; i=i+1;
        job=jobs{i}; save([tDir int2str2(i,5) '-in'],'job'); %#ok<NASGU>
        system([cmd ' ' tDir int2str2(i,5)]);
      end
      fs=dir([tDir '*-done']); fs={fs.name}; k1=length(fs); k=k+k1; q=q-k1;
      for i1=1:k1
        i2=str2double(fs{i1}(end-9:end-5)); f=[tDir int2str2(i2,5)];
        if(store), r=load([f '-out']); res{i2}=r.r; end
        delete([f '-in.mat'],[f '-out.mat'],[f '-done']);
      end
      tocStatus(tid,k/nJob); if(k==nJob), out=1; break; end
    end
    for i=1:10, try rmdir(tDir,'s'); catch, pause(1), end; end %#ok<CTCH>
    
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
    
  otherwise, assert(false);
end
end
