% Compiles all the private routines
%
% assumes located in toolbox root directory
%
% USAGE
%  toolbox_compile
%
% INPUTS
%
% OUTPUTS
%
% EXAMPLE
%
% See also

% Piotr's Image&Video Toolbox      Version 1.03   PPD
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

dir = 'classify/private/';
mex([dir 'meanshift1.c'],'-outdir',dir);

dir = 'images/private/';
mex([dir 'assign2binsc.c'],'-outdir',dir);
mex([dir 'histc_nD_c.c'],'-outdir',dir);
mex([dir 'mask_ellipse1.c'],'-outdir',dir);
mex([dir 'rnlfilt_max.c'],'-outdir',dir);
mex([dir 'rnlfilt_sum.c'],'-outdir',dir);
mex([dir 'rnlfiltblock_sum.c'],'-outdir',dir);

dir = 'external/dijkstra/private/';
mex([dir 'fibheap.cpp'],'-outdir',dir);
