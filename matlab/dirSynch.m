function dirSynch( root1, root2, showOnly, flag, ignDate )
% Synchronize two directory trees (or show differences between them).
%
% If a file or directory 'name' is found in both tree1 and tree2:
%  1) if 'name' is a file in both the pair is considered the same if they
%     have identical size and identical datestamp (or if ignDate=1).
%  2) if 'name' is a directory in both the dirs are searched recursively.
%  3) if 'name' is a dir in root1 and a file in root2 (or vice-versa)
%     synchronization cannot proceed (an error is thrown).
% If 'name' is found only in root1 or root2 it's a difference between them.
%
% The parameter flag controls how synchronization occurs:
%  flag==0: neither tree1 nor tree2 has preference (newer file is kept)
%  flag==1: tree2 is altered to reflect tree1 (tree1 is unchanged)
%  flag==2: tree1 is altered to reflect tree2 (tree2 is unchanged)
% Run with showOnly=1 and different values of flag to see its effect.
%
% By default showOnly==1. If showOnly, displays a list of actions that need
% to be performed in order to synchronize the two directory trees, but does
% not actually perform the actions. It is highly recommended to run
% dirSynch first with showOnly=1 before running it with showOnly=0.
%
% USAGE
%  dirSynch( root1, root2, [showOnly], [flag], [ignDate] )
%
% INPUTS
%  root1    - root directory of tree1
%  root2    - root directory of tree2
%  showOnly - [1] show but do NOT perform actions
%  flag     - [0] 0: synchronize; 1: set root2=root1; 2: set root1==root2
%  ignDate  - [0] if true considers two files same even if have diff dates
%
% OUTPUTS
%  dirSynch( 'c:\toolbox', 'c:\toolbox-old', 1 )
%
% EXAMPLE
%
% See also
%
% Piotr's Image&Video Toolbox      Version 2.10
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

if(nargin<3 || isempty(showOnly)), showOnly=1; end;
if(nargin<4 || isempty(flag)), flag=0; end;
if(nargin<5 || isempty(ignDate)), ignDate=0; end;
% get differences between root1/root2 and loop over them
D = dirDiff( root1, root2, ignDate );
roots={root1,root2}; ticId = ticStatus;
for i=1:length(D)
  % get action
  if( flag==1 )
    if( D(i).in1 ), act=1; src1=1; else act=0; src1=2; end
  elseif( flag==2 )
    if( D(i).in2 ), act=1; src1=2; else act=0; src1=1; end
  else
    act=1;
    if(D(i).in1 && D(i).in2)
      if( D(i).new1 ), src1=1; else src1=2; end
    else
      if( D(i).in1 ), src1=1; else src1=2; end
    end
  end
  src2=mod(src1,2)+1;
  % perform action
  if( act==1 )
    if( showOnly )
      disp(['COPY ' int2str(src1) '->' int2str(src2) ': ' D(i).name]);
    else
      copyfile( [roots{src1} D(i).name],  [roots{src2} D(i).name], 'f' );
    end;
  else
    if( showOnly )
      disp(['DEL in  ' int2str(src1) ': ' D(i).name]);
    else
      fName = [roots{src1} D(i).name];
      if(D(i).isdir), rmdir(fName,'s'); else delete(fName); end
    end
  end
  if(~showOnly), tocStatus( ticId, i/length(D) ); end;
end
end

function D = dirDiff( root1, root2, ignDate )
% get differences from root1 to root2
D1 = dirDiff1( root1, root2, ignDate, '/' );
% get differences from root2 to root1
D2 = dirDiff1( root2, root1, ignDate, '/' );
% remove duplicates (arbitrarily from D2)
D2=D2(~([D2.in1] & [D2.in2]));
% swap 1 and 2 in D2
for i=1:length(D2),
  D2(i).in1=0; D2(i).in2=1; D2(i).new1=~D2(i).new1;
end
% merge
D = [D1 D2];
end

function D = dirDiff1( root1, root2, ignDate, subdir )
if(root1(end)~='/'), root1(end+1)='/'; end
if(root2(end)~='/'), root2(end+1)='/'; end
if(subdir(end)~='/'), subdir(end+1)='/'; end
fs1=dir([root1 subdir]); fs2=dir([root2 subdir]);
D=struct('name',0,'isdir',0,'in1',0,'in2',0,'new1',0);
D=repmat(D,[1 length(fs1)]); n=0; names2={fs2.name}; Dsub=[];
for i1=1:length( fs1 )
  name=fs1(i1).name; isdir=fs1(i1).isdir;
  if( any(strcmp(name,{'.','..'})) ), continue; end;
  i2 = find(strcmp(name,names2));
  if(~isempty(i2) && isdir)
    % cannot handle this condition
    if(~fs2(i2).isdir), disp([root1 subdir name]); assert(false); end;
    % recurse and record possible differences
    Dsub=[Dsub dirDiff1(root1,root2,ignDate,[subdir name])]; %#ok<AGROW>
  elseif( ~isempty(i2) && fs1(i1).bytes==fs2(i2).bytes && ...
      (ignDate || fs1(i1).datenum==fs2(i2).datenum))
    % nothing to do - files are same
    continue;
  else
    % record differences
    n=n+1;
    D(n).name=[subdir name]; D(n).isdir=isdir;
    D(n).in1=1; D(n).in2=~isempty(i2);
    D(n).new1 = ~D(n).in2 || (fs1(i1).datenum>fs2(i2).datenum);
  end
end
D = [D(1:n) Dsub];
end
