% Generalized, version of histc (histogram count), allows weighted values.
%
% Creates a histogram h of the values in I, with edges as specified.  h
% will have length nbins, where nbins=length(edges)-1.  Each value in I has
% associated weight given by weightMask, which should have the same
% dimensions as I. h(q) contains the weighted count of values v in I such
% that edges(q) <= v < edges(q+1). h(nbins) additionally contains the
% weighted count of values in I such that v==edges(nbins+1) -- which is
% different then how histc treates the boundary condition. Finally, h is
% normalized so that sum(h(:))==1.
%
% It usually makes sense to specify edges explicitly, especially if
% different histograms are going to be compared.  In general, edges must
% have monotonically non-decreasing values.  Also, if the exact bounds are
% unknown then it is convenient to set the first element in edges to -inf
% and the last to inf.  If h = histc_1D( I, nbins, ...), edges are
% automatically generated and have bins equally spaced between min(I) and
% max(I). That is edges is generated via: 'edges = linspace( minI-eps,
% maxI+eps, nbins+1 )'.
%
% See histc for more information.
%
% USAGE
%  h = histc_1D( I, edges, weightMask )
%
% INPUTS
%  I           - numeric array [treated as a vector]
%  edges       - either nbins+1 vec of quantization bounds, or scalar nbins
%  weightMask  - [] size(I) numeric array of weights
%
% OUTPUTS
%  h           - histogram (vector of size 1xnbins)
%
% EXAMPLE
%  G = filterGauss([1000 1000],[],[],1);
%  h1 = histc_1D( G, 25 );    figure(1); bar(h1);
%  h2 = histc_1D( G, 25, G ); figure(2); bar(h2);
%
% See also HISTC, ASSIGN2BINS

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function h = histc_1D( I, edges, weightMask )

if( nargin<3 ); weightMask=[]; end
if( ~isa(I,'double') ); I=double(I); end

% if nbins given instead of edges calculate edges
if(length(edges)==1)  
  edges = linspace(min(I(:))-eps,max(I(:))+eps,edges+1); 
end

% create histogram
if(isempty(weightMask))
  % If no weightMask specified then basically call histc and normalize
  h = histc( I(:), edges )';
  h(end-1) = h(end-1)+h(end);
  h = h(1:end-1); h = h / sum(h);
else
  % create masked histograms
  h = histc_nD_c( I(:), weightMask(:), edges );
  h = h / sum(h);
end
