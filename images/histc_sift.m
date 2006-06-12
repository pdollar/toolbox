% Creates a series of locally position dependent histograms of the values in I.
%
% Inspired by David Lowe's SIFT descriptor.  Takes I, divides it into a number of regions,
% and creates a histogram for each region. I is divided into approximately equally sized
% hyper-rectangular regions so that together these hyper-rectangles cover I.  The
% hyper-rectangles are actually 'soft', in that each region is actually defined by a
% gaussian mask, for details see mask_gaussians. pargmask, parameters to mask_gaussians,
% controls details about how the masks are created.  Optionally, each value in I may have
% associated weight given by weightmask, which should have the same exact dimensions as I. 
%
% INPUTS
%   I           - M1xM2x...xMk numeric array
%   edges       - either nbins+1 length vector of quantization bounds, or nbins
%   pargmask    - cell of parameters to mask_gaussians
%   weightmask  - [optional] size(I) numeric array of weights
%
% OUTPUTS
%   hs          - histograms (array of size nbins x nmasks)
%
% EXAMPLE
%   G = filter_gauss_nD([100 100],[],[],0);
%   hs = histc_sift( G, 5, {2,.6,.1,0} ); figure(1); im(hs)
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also HISTC_1D, MASK_GAUSSIANS, HISTC_SIFT_ND

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function hs = histc_sift( I, edges, pargmask, weightmask )
    if( nargin<4 ) weightmask=[]; end;
    hs = histc_sift_nD( I, edges, pargmask, weightmask, 0 );
    
