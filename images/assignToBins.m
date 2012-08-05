function B = assignToBins( A, edges )
% Quantizes A according to values in edges.
%
% assignToBins replaces each value in A with a value between [0,nBins] where
% nBins=length(edges)-1.  edges must be a vector of monotonically
% increasing values.  Each element v in A gets converted to a discrete
% value q such that edges(q)<=v< edges(q+1). If v==edges(end) then q=nBins.
% If v does not fall into any bin, then q=0. See histc2 for more details
% about edges.  For even spaced edges can get away with rounding A
% appropriately, see example below.
%
% USAGE
%  B = assignToBins( A, edges )
%
% INPUTS
%  A      - numeric array of arbitrary dimension
%  edges  - quantization bounds, see histc2
%
% OUTPUTS
%  B      - size(A) array of quantization levels, ints between [0,nBins]
%
% EXAMPLE
%  A = rand(5,5);
%  B1 = assignToBins(A,[0:.1:1]);
%  B2 = ceil(A*10); B1-B2
%
% See also HISTC2
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

if(~isa(A,'double')); A = double(A); end;

if( length(edges)==1 )  % if nBins given instead of edges calculate edges
  edges = linspace( min(A(:))-eps, max(A(:))+eps, edges+1 ); end;

B = assignToBins1( A, edges );  % assign bin number
B = B + 1;                      % convert to 1 indexed
B = reshape( B, size(A) );      % resize B to have correct shape
B( B==(length(edges)) ) = 0;    % vals outside or range get bin 0
