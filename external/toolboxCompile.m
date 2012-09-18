% Compiles all mex routines that are part of toolbox.
%
% USAGE
%  toolboxCompile
%
% INPUTS
%
% OUTPUTS
%
% EXAMPLE
%
% See also
%
% Piotr's Image&Video Toolbox      Version 3.01
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

disp('Compiling.......................................');
rd=fileparts(mfilename('fullpath')); rd=rd(1:end-9);

% general compile options (can make architecture specific)
opts = {'-output'};
if(exist('OCTAVE_VERSION','builtin')), opts={'-o'}; end

% if you get warnings on linux, you can set the gcc version using:
% opts = {'CXX=g++-4.1' 'CC=g++-4.1' 'LD=g++-4.1' '-l' ...
%   'mwlapack' '-l' 'mwblas' '-output' };

% compile c functions
fs={'assignToBins1','histc2c','ktHistcRgb_c','ktComputeW_c',...
  'nlfiltersep_max','nlfiltersep_sum','imtransform2_c',...
  'meanShift1','fernsInds1'};
ds=[repmat({'images'},1,7),repmat({'classify'},1,2)];
for i=1:length(fs), fs{i}=[rd '/' ds{i} '/private/' fs{i}]; end
for i=1:length(fs), mex([fs{i} '.c'],opts{:},[fs{i} '.' mexext]); end

% compile c++ functions
try
  fs={'convConst','gradientMex','rgbConvertMex','imResampleMex',...
    'imPadMex','opticalFlowHsMex','forestFindThr','forestInds'};
  ds=[repmat({'channels'},1,5) 'images' repmat({'classify'},1,2)];
  for i=1:length(fs), fs{i}=[rd '/' ds{i} '/private/' fs{i}]; end
  for i=1:length(fs), mex([fs{i} '.cpp'],opts{:},[fs{i} '.' mexext]); end
catch ME
  fprintf(['C++ mex failed, likely due to lack of a C++ compiler.\n' ...
    'Run ''mex -setup'' to specify a C++ compiler if available.\n'...
    'Or, one can specify a specific C++ explicitly (see mex help).\n']);
end

disp('..................................Done Compiling');
