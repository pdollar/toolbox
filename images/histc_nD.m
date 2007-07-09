% Generalized, multidimensional version of normalized histc
%
% Generalized version of normalized histc (histogram count) that allows for
% weighted pixels and also multiple channels.  For example, suppose A is a
% nx2 array (n samples, 2 channels). Then histc_nD creates a 2D histogram
% such that h(q1,q2) contains the weighted count of values [v1;v2] in A
% such that edges1(q1)<=v1<edges1(q1+1) and edges2(q2)<=v2<edges2(q2+1).
%
% The histogram edge vectors can be specified in a number of ways.  If
% edges is a scalar, it is treated as a desired number of bins per
% dimension and a separate edges vector is generated for each dimension,
% for details on how this works see histc_1D.  If edges is a vector, than
% this vector is used as the edges vector along every dimension.  Finally,
% to specify a different set of edges along each dimension use a cell
% vector of length nd where each element is again a scalar or vector.
% Finally h is normalized so that sum(h(:))==1.
%
% See histc_1D for more details about edges and nbins.
%
% USAGE
%  h = histc_nD( A, edges, [weightMask] )
%
% INPUTS
%  A           - 2D numeric array [n x nd]
%  edges       - either nbins+1 vec of quantization bounds, or scalar nbins
%  weightMask  - [] n length vector of weights
%
% OUTPUTS
%  h           - histogram (array of size nbins1xnbins2x...)
%
% EXAMPLE
%  G = filterGauss([1000 1000],[],[],0); G=G(:);
%  h=histc_nD( [G G], 25 ); figure(1); im(h); %decreasing vals along diag
%  h=histc_nD( [G G], 25, G ); figure(2); im(h); %constants along diag
%  h=histc_nD( [randn(size(G)) G], 5 ); figure(3); im(h); % symmetric
%
% See also HISTC_1D

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function h = histc_nD( A, edges, weightMask )

if (nargin<3), weightMask=[]; end;
if( ~isa(A,'double') ); A=double(A); end;

[n nd] = size(A);
if( ~iscell(edges ) )
  edges=repmat({edges},[1 nd]);
elseif( length(edges)~=nd )
  error( 'Illegal dimensions for edges' );
end
if( ~isempty(weightMask) && length(weightMask)~=n )
  error( 'Illegal dimensions for weightMask' ); end

% if nbins given instead of edges calculate edges
% minI = min(A,[],1); maxI = max(A,[],1);
for i=1:length( edges );
  if(length(edges{i})==1)
    edges{i}=linspace(min(A(:,i))-eps,max(A(:,i))+eps,edges{i}+1);
  end
end

% create histogram
if( isempty(weightMask) ); weightMask=ones(1,n); end;
h = histc_nD_c( A, weightMask, edges{:} );
h = h / sum(h(:));
