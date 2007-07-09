% Generalized, version of histc (histogram count), allows weighted values.
%
% Creates a histogram h of the values in A, with edges as specified.  h
% will have length nbins, where nbins=length(edges)-1.  Each value in A has
% associated weight given by wtMask, which should have the same
% dimensions as A. h(q) contains the weighted count of values v in A such
% that edges(q) <= v < edges(q+1). h(nbins) additionally contains the
% weighted count of values in A such that v==edges(nbins+1) -- which is
% different then how histc treates the boundary condition. Finally, h is
% normalized so that sum(h(:))==1.
%
% It usually makes sense to specify edges explicitly, especially if
% different histograms are going to be compared.  In general, edges must
% have monotonically non-decreasing values.  Also, if the exact bounds are
% unknown then it is convenient to set the first element in edges to -inf
% and the last to inf.  If h = histc_1D( A, nbins, ...), edges are
% automatically generated and have bins equally spaced between min(A) and
% max(A). That is edges is generated via: 'edges = linspace( minI-eps,
% maxI+eps, nbins+1 )'.
%
% See histc for more information.
%
% USAGE
%  h = histc_1D( A, edges, [wtMask] )
%
% INPUTS
%  A           - numeric array [treated as a vector]
%  edges       - either nbins+1 vec of quantization bounds, or scalar nbins
%  wtMask      - [] size(A) numeric array of weights
%
% OUTPUTS
%  h           - [nbins x 1] histogram
%
% EXAMPLE
%  A = filterGauss([1000 1000],[],[],0);
%  h1 = histc_1D( A, 25 );    figure(1); bar(h1);
%  h2 = histc_1D( A, 25, A ); figure(2); bar(h2);
%
% See also HISTC, ASSIGN2BINS

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function h = histc_1D( A, edges, wtMask )

if( nargin<3 ); wtMask=[]; end;
if( ~isa(A,'double') ); A=double(A); end

% if nbins given instead of edges calculate edges
if(length(edges)==1)
  edges = linspace(min(A(:))-eps,max(A(:))+eps,edges+1);
end

% create histogram
if(isempty(wtMask))
  % If no wtMask specified then basically call histc and normalize
  h = histc( A(:), edges );
  h(end-1) = h(end-1)+h(end);
  h = h(1:end-1); h = h / sum(h);
else
  % create masked histograms
  h = histc_nD_c( A(:), wtMask(:), edges );
  h = h / sum(h);
end
