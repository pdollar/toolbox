% Used to apply the same operation to all .mat files in given directory.
%
% For each mat in srcDir, loads the mat file, extracts the variables
% denoted by matCont, applies the function fHandle and stores the
% result.  matCont must be a cell array of strings, where each string
% denotes the variable stored in the mat files. For example, if each mat
% file contains two variables y and z, then matCont should be
% {'y','z'}.  For long operations shows progress info.
%
% fHandle must point to a function that takes two inputs: vals and params.
% vals is a cell array that contains the values for the variables denoted
% by matCont and contained in the mat file, and params are the
% additional static parameters passed to feval_arrays.  Continuing the
% example above vals would be {y,z} - (use deal to extract):
%  x=feval(fHandle,{y,z},params)
% Each returned x must have the same dimensions, X is a concatentation of
% the returned x's along the (d+1) dimension.
%
% USAGE
%  X = feval_mats( fHandle, matCont, params, srcDir, [prefix] )
%
% INPUTS
%  fHandle  - function to apply to contents of each mat file [see above]
%  matCont  - cell array of strings of expected contents of each mat file
%  params   - cell array of additional parameters to fHandle (may be {})
%  srcDir   - directory containg mat files
%  prefix   - [] only consider mat files in srcDir of the form prefix_*.mat
%
% OUTPUTS
%  X        - output array [see above]
%
% EXAMPLE
%
% See also FEVAL_IMAGES, FEVAL_ARRAYS

% Piotr's Image&Video Toolbox      Version 1.03   PPD VR
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function X = feval_mats( fHandle, matCont, params, srcDir, prefix )

error(nargchk( 4, 5, nargin ));

%%% Check if srcDir is valid and add '/' at end if needed
if( ~isempty(srcDir) )
  if(~exist(srcDir,'dir'));
    error(['feval_mats: dir ' srcDir ' not found']); end
  if( srcDir(end)~='\' && srcDir(end)~='/' ); srcDir(end+1) = '/'; end
end

%%% get appropriate fileNames
if( nargin<=4 || isempty(prefix) )
  dirCont = dir( [srcDir '*.mat'] );
else
  dirCont = dir( [srcDir prefix '_*.mat'] );
end
fileNames = {dirCont.name}; n = length(dirCont);
if( n==0 ); error( ['No appropriate mat files found in ' srcDir] ); end

%%% load each mat file and apply fHandle
ticstatusid = ticstatus('feval_mats',[],40);
ncontents = length( matCont );
for i=1:n
  % load mat file and get contents
  S = load( [srcDir fileNames{i}] );
  errmsg = ['Unexpected contents for mat file: ' fileNames{i}];
  if( length(fieldnames(S))<ncontents); error( errmsg ); end
  inputs = cell(1,ncontents);
  for j=1:ncontents
    if( ~isfield(S,matCont{j}) ); error( errmsg ); end
    inputs{j} = S.matCont{j}; %getfield(S,matCont{j});
  end; clear S;

  % apply fHandle
  x = feval( fHandle, inputs, params );
  if (i==1)
    ndx = ndims(x);
    if(ndx==2 && size(x,2)==1); ndx=1; end;
    ones_ndx = ones(1,ndx);
    X = repmat( x, [ones_ndx,n] );
    indsX = {':'}; indsX = indsX(ones_ndx);
  else
    X(indsX{:},i) = x;
  end;
  tocstatus( ticstatusid, i/n );
end
