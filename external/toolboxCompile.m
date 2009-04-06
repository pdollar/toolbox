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
% Piotr's Image&Video Toolbox      Version 2.12
% Copyright 2009 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

disp('Compiling.......................................');

% general compile options
opts0 = {'-outdir'};
%opts0=['CXX=g++-4.1' 'CC=g++-4.1' 'LD=g++-4.1' opts0];

dir='classify/private/'; opts=[opts0 dir];
mex([dir 'meanShift1.c'],           opts{:} );

dir='images/private/'; opts=[opts0 dir];
mex([dir 'assignToBins1.c'],        opts{:} );
mex([dir 'histc2c.c'],              opts{:} );
mex([dir 'ktHistcRgb_c.c'],         opts{:} );
mex([dir 'ktComputeW_c.c'],         opts{:} );
mex([dir 'maskEllipse1.c'],         opts{:} );
mex([dir 'nlfiltersep_max.c'],      opts{:} );
mex([dir 'nlfiltersep_sum.c'],      opts{:} );
mex([dir 'nlfiltersep_blocksum.c'], opts{:} );

dir='images/private/'; opts=[opts0 'images/'];
mex([dir 'imResample.c'],         opts{:} );

try
  % requires c++ compiler
  dir='matlab/private/'; opts=[opts0 'matlab' '-output' 'dijkstra'];
  mex([dir 'fibheap.cpp'],[dir 'dijkstra.cpp'], opts{:} );
catch ME
  fprintf(['Dijkstra''s shortest path algorithm compile failed,\n' ...
    'most likely due to lack of a C++ compiler.\n' ...
    'Run ''mex -setup'' to specify a C++ compiler if available.\n'...
    'Or, on LINUX specify a specific C++ compiler using, e.g.:\n' ...
    'mex CXX=g++-4.1 CC=g++-4.1 LD=g++-4.1 ' ...
    'dijkstra.cpp fibheap.cpp fibheap.h\n']);
end

disp('..................................Done Compiling');
