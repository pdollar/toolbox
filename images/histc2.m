% Multidimensional histogram count with allows weighted values.
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
% and the last to inf.  If h = histc2( A, nbins, ...), edges are
% automatically generated and have bins equally spaced between min(A) and
% max(A). That is edges is generated via: 'edges = linspace( minI-eps,
% maxI+eps, nbins+1 )'.
%
% See histc for more information.
%
% USAGE
%  h = histc2( A, edges, [wtMask] )
%
% INPUTS
%  A           - 2D numeric array [n x nd]
%  edges       - either nbins+1 vec of quantization bounds, or scalar nbins
%  wtMask      - [] n length vector of weights
%
% OUTPUTS
%  h           - histogram (array of size nbins1xnbins2x...)
%
% EXAMPLE - 1D histograms
%  A=filterGauss([1000 1000],[],[],0); A=A(:);
%  h1 = histc2( A, 25 );                  figure(1); bar(h1);
%  h2 = histc2( A, 25, ones(size(A)) );   figure(2); bar(h2);
%  h3 = histc2( A, 25, A );               figure(3); bar(h3);
%
% EXAMPLE - 2D histograms
%  A=filterGauss([1000 1000],[],[],0); A=A(:);
%  h=histc2( [A A], 25 ); figure(1); im(h);    % decreasing along diag
%  h=histc2( [A A], 25, A ); figure(2); im(h); % constant along diag
%  h=histc2( [randn(size(A)) A], 5 ); figure(3); im(h); % roughly symmetric
%
% See also HISTC, ASSIGN2BINS, BAR

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function h = histc2( A, edges, wtMask )

if( nargin<3 ); wtMask=[]; end;
if( ~isa(A,'double') ); A=double(A); end;
[n nd] = size(A);
if( ~isempty(wtMask) && n~=numel(wtMask) )
  error( 'wtMask must have n elements (A is nxnd)' ); end

if( nd==1 )
  % if nbins given instead of edges calculate edges
  if(length(edges)==1)
    edges = linspace(min(A)-eps,max(A)+eps,edges+1);
  end

  % create 1d histogram
  if(isempty(wtMask))
    h = histc( A, edges );
    h(end-1) = h(end-1)+h(end);
    h = h(1:end-1); h = h / sum(h);
  else
    h = histc_nD_c( A, wtMask, edges );
    h = h / sum(h);
  end

else
  % if nbins given instead of edges calculate edges per dimension
  if( ~iscell(edges ) )
    edges=repmat({edges},[1 nd]);
  elseif( length(edges)~=nd )
    error( 'Illegal dimensions for edges' );
  end
  for i=1:length( edges );
    if(length(edges{i})==1)
      edges{i}=linspace(min(A(:,i))-eps,max(A(:,i))+eps,edges{i}+1);
    end
  end

  % create multidimensional histogram
  if( isempty(wtMask) ); wtMask=ones(1,n); end;
  h = histc_nD_c( A, wtMask, edges{:} );
  h = h / sum(h(:));
end

