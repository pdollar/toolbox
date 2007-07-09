% Quantizes A according to values in edges.
%
% assign2bins replaces each value in A with a value between [0,nbins] where
% nbins=length(edges)-1.  edges must be a vector of monotonically
% increasing values.  Each element v in A gets converted to a discrete
% value q such that edges(q)<=v< edges(q+1). If v==edges(end) then q=nbins.
% If v does not fall into any bin, then q=0.
%
% See histc_1D for more details about edges and nbins.
%
% USAGE
%  B = assign2bins( A, edges )
%
% INPUTS
%  A      - numeric array of arbitrary dimension
%  edges  - either nbins+1 vector of quantization bounds, or scalar nbins
%
% OUTPUTS
%  B      - size(A) array of quantization levels, ints between [0,nbins]
%
% EXAMPLE
%  A = rand(5,5), B = assign2bins(A,[0:.1:1])
%
% See also HISTC_1D

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function B = assign2bins( A, edges )

if(~isa(A,'double')); A = double(A); end;

if( length(edges)==1 )  % if nbins given instead of edges calculate edges
  edges = linspace( min(A(:))-eps, max(A(:))+eps, edges+1 ); end;

B = assign2binsc( A, edges );   % assign bin number
B = B + 1;                      % convert to 1 indexed
B = reshape( B, size(A) );      % resize B to have correct shape
B( B==(length(edges)) ) = 0;    % vals outside or range get bin 0
