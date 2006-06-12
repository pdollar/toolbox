% Calculates histograms at every point in an array I.  
%
% The qth bin of each histogram contains the count of the number of locations in I that
% have value in between edges(q)<=v< edges(q+1).  HS(i,j,...,k,:) will contain the
% histogram at location (i,j,...,k), as calculated by weighing values in I by placing
% weightmask at that location.  For example, if weightmask is ones(window_size) then the
% histogram at every location will simply be a histogram of the pixels within that window.
%
% See histc_1D for more details about edges and nbins. 
%
% The shape flag specifies what to do at boundaries.  See convn_fast for
% possible flags such as 'same', 'valid', 'full, or 'smooth'.
%
% INPUTS
%   I           - Array with integer values [see above]
%   edges       - either nbins+1 length vector of quantization bounds, or nbins
%   weightmask  - numeric array of weights, or cell array of seperable weight kernels
%   shape       - [optional] 'valid', ['full'], 'same', or 'smooth'
%
% OUTPUTS
%   HS          - ~size(I)xQ array where each ~size(I) elt is a Q element
%                 histogram (~size(I) because depends on val of shape)
%
% EXAMPLE
%   load trees;
%   L = conv2(X, filter_DOG_2D(10,4,1,0), 'valid' ); 
%   f1=filter_gauss_1D([],5);   HS1 = histc_image( L, 15, {f1,f1'}, 'same' ); 
%   f2=ones(1,15);              HS2 = histc_image( L, 15, {f2,f2'}, 'same' ); 
%   figure(1); im(X); figure(2); im(L);   figure(3); montage2(HS1,1,1); 
%   figure(4); montage2(HS2,1,1);         figure(5); montage2(HS1-HS2,1,1);
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also ASSIGN2BINS, HISTC_1D

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function HS = histc_image( I, edges, weightmask, shape )
    if( nargin<4 || isempty(shape) )  shape = 'full';  end;
    if( ~iscell(weightmask) ) weightmask={weightmask}; end;
    
    % split I into channels
    I = assign2bins( I, edges );
    nbins=length(edges)-1; if(nbins==0) nbins=edges; end;
    nd = ndims(I); siz=size(I);  maxI = max(I(:));
    if( nd==2 && siz(2)==1) nd=1; siz=siz(1); end;
    QI = logical( zeros( [siz maxI] ) );
    inds = {':'}; inds = inds(:,ones(1,nd));
    for i=1:nbins  QI(inds{:},i)=I==i; end;
    HS = double( QI );
    
    % convolve with weightmask to get histograms, scale appropriately
    for i=1:length(weightmask)
        weightmaski = weightmask{i};
        for d=1:ndims(weightmaski) weightmaski = flipdim(weightmaski,d); end;
        weightmaski = weightmaski / sum(weightmaski(:));
        HS = convn_fast( HS, weightmaski, shape );
    end;
    
    
