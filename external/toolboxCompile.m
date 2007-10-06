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

% Piotr's Image&Video Toolbox      Version 2.0
% Copyright (C) 2007 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Liscensed under the Lesser GPL [see external/lgpl.txt]

dir = 'classify/private/';
mex([dir 'meanShift1.c'],           '-outdir', dir );

dir = 'images/private/';
mex([dir 'assignToBins1.c'],        '-outdir', dir );
mex([dir 'histc2c.c'],              '-outdir', dir );
mex([dir 'maskEllipse1.c'],         '-outdir', dir );
mex([dir 'nlfiltersep_max.c'],      '-outdir', dir );
mex([dir 'nlfiltersep_sum.c'],      '-outdir', dir );
mex([dir 'nlfiltersep_blocksum.c'], '-outdir', dir );

% requires c++ compiler
% dir = 'external/dijkstra/private/';
% mex([dir 'fibheap.cpp'],            '-outdir', dir );
