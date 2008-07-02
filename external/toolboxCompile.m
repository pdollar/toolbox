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
% Piotr's Image&Video Toolbox      Version 2.10
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

disp('Compiling.......................................');

dir = 'classify/private/';
mex([dir 'meanShift1.c'],           '-outdir', dir );

dir = 'images/private/';
mex([dir 'assignToBins1.c'],        '-outdir', dir );
mex([dir 'histc2c.c'],              '-outdir', dir );
mex([dir 'ktHistcRgb_c.c'],         '-outdir', dir );
mex([dir 'ktComputeW_c.c'],         '-outdir', dir );
mex([dir 'maskEllipse1.c'],         '-outdir', dir );
mex([dir 'nlfiltersep_max.c'],      '-outdir', dir );
mex([dir 'nlfiltersep_sum.c'],      '-outdir', dir );
mex([dir 'nlfiltersep_blocksum.c'], '-outdir', dir );

try
  % requires c++ compiler
  dir='matlab/private/';
  options={'-output', 'dijkstra', '-outdir', 'matlab'};
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
