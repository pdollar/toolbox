% Quantizes I according to values in edges.  
%
% assign2bins replaces each value in I with a value between [0,nbins] where
% nbins=length(edges)-1.  edges must be a vector of monotonically increasing values.  Each
% element v in I gets converted to a discrete value q such that edges(q)<=v< edges(q+1).
% If v==edges(end) then q=nbins.  If v does not fall into any bin, then q=0. 
%
% See histc_1D for more details about edges and nbins. 
%
% INPUTS
%   I           - numeric array of arbitrary dimension
%   edges       - either nbins+1 length vector of quantization bounds, or scalar nbins
%
% OUTPUTS
%   B           - size(I) array of quantization levels, int values between [0,nbins]
%
% EXAMPLE
%   I = rand(5,5)
%   B = assign2bins(I,[0:.1:1])
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%   
% See also HISTC_1D

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function B = assign2bins( I, edges )
    if(~isa(I,'double')) I = double(I); end;

    if( length(edges)==1 )  % if nbins given instead of edges calculate edges
        edges = linspace( min(I(:))-eps, max(I(:))+eps, edges+1 ); end;

    B = assign2binsc( I, edges );   % assign bin number
    B = B + 1;                      % convert to 1 indexed
    B = reshape( B, size(I) );      % resize B to have correct shape
    B( B==(length(edges)) ) = 0;    % vals outside or range get bin 0
