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
% Piotr's Image&Video Toolbox      Version 2.41
% Copyright 2009 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

disp('Compiling.......................................');
savepwd=pwd; cd(fileparts(mfilename('fullpath'))); cd('../');

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
mex([dir 'nlfiltersep_max.c'],      opts{:} );
mex([dir 'nlfiltersep_sum.c'],      opts{:} );

dir='images/private/'; opts=[opts0 'images/'];
mex([dir 'imResample.c'],         opts{:} );

try
  % requires c++ compiler
  dir='images/private/'; opts=[opts0 'images/'];
  mex([dir 'hog.cpp'], opts{:} );
  dir='matlab/private/'; opts=[opts0 'matlab' '-output' 'dijkstra'];
  mex([dir 'fibheap.cpp'],[dir 'dijkstra.cpp'], opts{:} );
catch ME
  fprintf(['C++ mex failed, likely due to lack of a C++ compiler.\n' ...
    'Run ''mex -setup'' to specify a C++ compiler if available.\n'...
    'Or, on LINUX specify a specific C++ explicitly (see opts above).\n']);
end

cd(savepwd); disp('..................................Done Compiling');
