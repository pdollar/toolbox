% Creates a series of locally position dependent histograms of values in I.
%
% Inspired by David Lowe's SIFT descriptor.  Takes I, divides it into a
% number of regions, and creates a histogram for each region. I is divided
% into approximately equally sized hyper-rectangular regions so that
% together these hyper-rectangles cover I.  The hyper-rectangles are
% actually 'soft', in that each region is actually defined by a gaussian
% mask, for details see mask_gaussians. parGmask, parameters to
% mask_gaussians, controls details about how the masks are created.
% Optionally, each value in I may have associated weight given by
% weightMask, which should have the same exact dimensions as I.
%
% USAGE
%  hs = histc_sift( I, edges, parGmask, [weightMask] )
%
% INPUTS
%  I           - M1xM2x...xMk numeric array
%  edges       - either nbins+1 vec of quantization bounds, or scalar nbins
%  parGmask    - cell of parameters to mask_gaussians
%  weightMask  - [] size(I) numeric array of weights
%
% OUTPUTS
%  hs          - histograms (array of size nbins x nmasks)
%
% EXAMPLE
%  G = filterGauss([100 100],[],[],0);
%  hs = histc_sift( G, 5, {2,.6,.1,0} ); figure(1); im(hs)
%
% See also HISTC_1D, MASK_GAUSSIANS, HISTC_SIFT_ND

% Piotr's Image&Video Toolbox      Version 1.5
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function hs = histc_sift( I, edges, parGmask, weightMask )

if( nargin<4 ); weightMask=[]; end;
hs = histc_sift_nD( I, edges, parGmask, weightMask, 0 );

