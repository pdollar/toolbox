function X = fevalMats( fHandle, matCont, prm, srcDir, prefix )
% Used to apply the same operation to all .mat files in given directory.
%
% For each mat in srcDir, loads the mat file, extracts the variables
% denoted by matCont, applies the function fHandle and stores the
% result.  matCont must be a cell array of strings, where each string
% denotes the variable stored in the mat files. For example, if each mat
% file contains two variables y and z, then matCont should be
% {'y','z'}.  For long operations shows progress info.
%
% fHandle must point to a function that takes two inputs: vals and prm.
% vals is a cell array that contains the values for the variables denoted
% by matCont and contained in the mat file, and prm are the
% additional static parameters passed to fevalArrays.  Continuing the
% example above vals would be {y,z} - (use deal to extract):
%  x=feval(fHandle,{y,z},prm)
% Each returned x must have the same dimensions, X is a concatentation of
% the returned x's along the (d+1) dimension.
%
% USAGE
%  X = fevalMats( fHandle, matCont, prm, srcDir, [prefix] )
%
% INPUTS
%  fHandle  - function to apply to contents of each mat file [see above]
%  matCont  - cell array of strings of expected contents of each mat file
%  prm      - cell array of additional parameters to fHandle (may be {})
%  srcDir   - directory containg mat files
%  prefix   - [] only consider mat files in srcDir of the form prefix_*.mat
%
% OUTPUTS
%  X        - output array [see above]
%
% EXAMPLE
%
% See also FEVALIMAGES, FEVALARRAYS, DEAL
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.0
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

narginchk( 4, 5 );

%%% Check if srcDir is valid and add '/' at end if needed
if( ~isempty(srcDir) )
  if(~exist(srcDir,'dir'));
    error(['fevalMats: dir ' srcDir ' not found']); end
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
ticId = ticStatus('fevalMats',[],40);
nCont = length( matCont );
for i=1:n
  % load mat file and get contents
  S = load( [srcDir fileNames{i}] );
  errmsg = ['Unexpected contents for mat file: ' fileNames{i}];
  if( length(fieldnames(S))<nCont); error( errmsg ); end
  inputs = cell(1,nCont);
  for j=1:nCont
    if( ~isfield(S,matCont{j}) ); error( errmsg ); end
    inputs{j} = S.(matCont{j});
  end; clear S;

  % apply fHandle
  x = feval( fHandle, inputs, prm );
  if (i==1)
    ndx = ndims(x);
    if(ndx==2 && size(x,2)==1); ndx=1; end;
    onesNdx = ones(1,ndx);
    X = repmat( x, [onesNdx,n] );
    indsX = {':'}; indsX = indsX(onesNdx);
  else
    X(indsX{:},i) = x;
  end;
  tocStatus( ticId, i/n );
end
