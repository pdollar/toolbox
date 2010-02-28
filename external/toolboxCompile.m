% Compiles all the private routines
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
% Piotr's Image&Video Toolbox      Version NEW
% Copyright 2010 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

disp('Compiling.......................................');
rd=fileparts(mfilename('fullpath')); rd=rd(1:end-9);

% general compile options (can make architecture specific)
opts = {'-output'};

% compile c functions
fs={'assignToBins1','histc2c','ktHistcRgb_c','ktComputeW_c',...
  'nlfiltersep_max','nlfiltersep_sum','imResample1','meanShift1'};
ds=[repmat({'images'},1,7),'classify'];
for i=1:length(fs), mex([rd '/' ds{i} '/private/' fs{i} '.c'],...
    opts{:},[rd '/' ds{i} '/private/' fs{i} '.' mexext]); end

% compile c++ functions
try
  f=[rd '/images/private/hog1']; mex([f '.cpp'],opts{:},[f '.' mexext]);
  d=[rd '/matlab/private/']; mex([d 'fibheap.cpp'],[d 'dijkstra1.cpp'], ...
    opts{:}, [d 'dijkstra1.' mexext]);
catch ME
  fprintf(['C++ mex failed, likely due to lack of a C++ compiler.\n' ...
    'Run ''mex -setup'' to specify a C++ compiler if available.\n'...
    'Or, one can specify a specific C++ explicitly (see mex help).\n']);
end

disp('..................................Done Compiling');
