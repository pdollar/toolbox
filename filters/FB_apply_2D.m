% Applies each of the filters in the filterbank FB to the image I.
%
% To apply to a stack of images:
%   IFS = feval_arrays( images, @FB_apply_2D, FB, 'valid' );
%
% INPUTS
%   I       - 2D input array
%   FB      - MxNxK set of K filters
%   shape   - [optional] option for conv2 'same', 'valid', ['full']
%   show    - [optional] figure to use for display (no display if == 0)
%
% OUTPUTS
%   IF      - 3D set of filtered images
%
% EXAMPLE
%   load trees; X=imresize(X,.5);
%   load FB_DoG.mat;
%   IF = FB_apply_2D( X, FB, 'same', 1 );
%
% DATESTAMP
%   30-Apr-2006  2:00pm

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function IF = FB_apply_2D( I, FB, shape, show )
    if( nargin<3 || isempty(shape)) shape = 'full'; end;
    if( nargin<4 || isempty(show)) show=0; end;
    
    siz = size(I); nd=ndims(I);  ndf=ndims(FB);  nf=size(FB,3);
    if( nd~=2  ) error('I must be an MxN array'); end;
    if( ndf~=2 && ndf~=3 ) error('FB must be an MxN or MxNxK array'); end;    
    if( ~isa(I,'double')) I = double(I); end;

    %%% apply filter bank
    if( ndf==2 )
        IF = conv2( I, FB, shape );
    else % don't use feval_arrays for efficiency.
        IF = repmat( conv2(I,FB(:,:,1),shape), [1 1 nf] );
        for i=2:nf IF(:,:,i)=conv2(I,FB(:,:,i),shape); end;
    end

    %%% optionally show
    if( show )
        figure(show); im(I);
        figure(show+1); montage2(FB,1,1);
        figure(show+2); montage2(IF,1,1);
    end;
