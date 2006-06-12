%MONTAGES2 [4D] Used to display R sets of T images each.  
%
% Displays one montage (see montage2) per row.  Each of the R image sets is flattened to
% a single long image by concatenating the T images in the set.
% Alternative to montages.
%
% INPUTS
%   IS                  - MxNxTxR or MxNx1xTxR or MxNx3xTxR array 
%   montage2params      - [optional] params for montage2; ex: {showlines, extrainfo}
%   padsize             - [optional] total amount of vertical or horizontal padding
%
% OUTPUTS
%   I                   - 3D or 4D array of flattened images, displayed with montage2
%   mm                  - #montages/row
%   nn                  - #montages/col
%
% EXAMPLE
%   load( 'images.mat' );
%   imageclusters = clustermontage( images, IDXi, 16, 1 );
%   montages2( imageclusters );
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also MONTAGES, MAKEMOVIES, MONTAGE2, CLUSTERMONTAGE

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function varargout = montages2( IS, montage2params, padsize )
    if( nargin<2 || isempty(montage2params) ) montage2params = {}; end;
    if( nargin<3 || isempty(padsize) ) padsize = 4; end;
    [padsize,er] = checknumericargs( padsize,[1 1], 0, 1 ); error(er);
    
    %%% get/test image format info
    nd = ndims(IS);  siz = size(IS);
    if( nd==3 ) %MxNxTx1
        nmontages = 1; 
    elseif( nd==4 )  %MxNxTxR
        nmontages = size(IS,4);
    elseif( nd==5 )  %MxNx1xTxR or MxNx3xTxR
        nmontages = size(IS,5);
        nch = size(IS,3);  
        if( nch~=1 && nch~=3 ) error('illegal image stack format'); end;        
        if( nch==1 ) IS = squeeze(IS); nd=4; siz=size(IS); end;
    else
        error('unsupported dimension of IS');
    end;
    
    
    %%% reshape IS so that each 3D element is concatentated to a 2D image, adding padding
    padelement = max(IS(:)); 
    IS=arraycrop2dims(IS, [siz(1)+padsize siz(2:end)], padelement ); %UD pad
    siz=size(IS); 
    if(nd==3) % reshape bw single
        IS=squeeze( reshape( IS, siz(1), [] ) ); 
    elseif(nd==4) % reshape bw
        IS=squeeze( reshape( IS, siz(1), [], siz(4) ) ); 
    else % reshape color
        IS=squeeze( reshape( permute(IS,[1 2 4 3 5]), siz(1), [], siz(3), siz(5) ) ); 
    end; siz = size(IS);
    IS=arraycrop2dims(IS, [siz(1) siz(2)+padsize siz(3:end)], padelement);  %LR pad
    siz=size(IS); 

    
    %%% show using montage2
    varargout = cell(1,nargout); 
    if( nargout) varargout{1}=IS; end;
    [varargout{2:end}] = montage2( IS, montage2params{:} ); 
    title(inputname(1)); 
    
