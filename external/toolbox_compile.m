
%%% assumes located in toolbox root directory

dir = 'classify/private/';
mex([dir 'meanshift1.c'],'-outdir',dir);

dir = 'images/private/';
mex([dir 'assign2binsc.c'],'-outdir',dir);
mex([dir 'histc_nD_c.c'],'-outdir',dir);
mex([dir 'mask_ellipse1.c'],'-outdir',dir);
mex([dir 'rnlfilt_max.c'],'-outdir',dir);
mex([dir 'rnlfilt_sum.c'],'-outdir',dir);
mex([dir 'rnlfiltblock_sum.c'],'-outdir',dir);
