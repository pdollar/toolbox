% Compiles all the private routines
%
% assumes located in toolbox root directory
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
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

disp('Compiling.......................................');

optionsLinux = {};
if  strcmp(computer,'GLNX86')
  optionsLinux  = { 'CXX=g++-4.1' 'CC=g++-4.1' 'LD=g++-4.1' };
end

dir = 'classify/private/';
options = { '-outdir' dir optionsLinux{:} };
mex([dir 'meanShift1.c'],           options{:} );

dir = 'images/private/';
options = { '-outdir' dir optionsLinux{:} };
mex([dir 'assignToBins1.c'],        options{:} );
mex([dir 'histc2c.c'],              options{:} );
mex([dir 'ktHistcRgb_c.c'],         options{:} );
mex([dir 'ktComputeW_c.c'],         options{:} );
mex([dir 'maskEllipse1.c'],         options{:} );
mex([dir 'nlfiltersep_max.c'],      options{:} );
mex([dir 'nlfiltersep_sum.c'],      options{:} );
mex([dir 'nlfiltersep_blocksum.c'], options{:} );
mex([dir 'imDownsample.c'],         options{:} );

try
  % requires c++ compiler
  dir='matlab/private/';
  options={'-output', 'dijkstra', '-outdir', 'matlab', optionsLinux{:} };
  mex([dir 'fibheap.cpp'],[dir 'dijkstra.cpp'], options{:} );
catch ME
  fprintf(['Dijkstra''s shortest path algorithm compile failed,\n' ...
    'most likely due to lack of a C++ compiler.\n' ...
    'Run ''mex -setup'' to specify a C++ compiler if available.\n'...
    'Or, on LINUX specify a specific C++ compiler using, e.g.:\n' ...
    'mex CXX=g++-4.1 CC=g++-4.1 LD=g++-4.1 ' ...
    'dijkstra.cpp fibheap.cpp fibheap.h\n']);
end

disp('.......................................Done Compiling');
