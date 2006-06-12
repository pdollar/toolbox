% Creates a series of locally position dependent histograms.
%
% Creates a series of locally position dependent histograms of the values in the mutiple
% channel multidimensional array I (this is a generalized version of histc_sift that
% allows for multiple channels).
%
% I is an M1xM2x...xMkxnd array, it consists of nd channels each of dimension
% (M1xM2x...xMk).  histc_sift_nD works by dividing a (M1xM2x...xMk) array into seperate
% regions and creating a 1D histogram for each using histc_1D.  histc_sift_nD does the same
% thing except each region now has multiple channels, and an nd-dimensional histogram is
% created for each using histc_nD.
%
% INPUTS
%   I           - M1xM2x...xMkxnd array, (nd channels each of dim M1xM2x...xMk)
%   edges       - parameter to histc_nD, [either scalar, vector, or cell vector]
%   pargmask    - cell of parameters to mask_gaussians
%   weightmask  - [optional] M1xM2x...xMk numeric array of weights
%   multch      - [optional] if 0 this becomes same as histc_sift.m (nd==1)
%
% OUTPUTS
%   hs          - histograms (array of size nmasks x nbins)
%
% EXAMPLE
%   G = filter_gauss_nD([100 100],[],[],0); 
%   hs = histc_sift_nD( cat(3,G,G), 5, {2,.6,.1,0} ); 
%   hs = histc_sift_nD( cat(3,G,randn(size(G))),5,{2,.6,.1,0}); 
%   figure(1); montage2(hs,1);  figure(2); montage2(hs,1);
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also HISTC_1D, HISTC_SIFT, MASK_GAUSSIANS, HISTC_ND

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function hs = histc_sift_nD( I, edges, pargmask, weightmask, multch )
    if( nargin<4 ) weightmask=[]; end;
    if( nargin<5 ) multch=1; end;
    
    %%% set up for either multiple channels or 1 channel
    siz = size(I); nd=ndims(I);
    if( multch )
        nch=siz(end); siz=siz(1:end-1); nd=nd-1;
    else
        nch=1;
    end;
    
    %%% create masks [slow but cached]
    [masks,keeplocs] = mask_gaussians( siz, pargmask{:} ); 
    nmasks = size(masks,nd+1);
    if( ~isempty(weightmask) )
        masks = masks .* repmat(weightmask,[ones(1,nd) nmasks]); end;
    if(length(edges)==1) nbins=edges; else nbins=length(edges)-1; end;

    %%% flatten
    I = reshape( I, [], nch );
    masks = reshape( masks, [], nmasks );
    keeplocs = reshape( keeplocs, [], nmasks );
    
    %%% amount to smoothe each histogram by [help alleviate quantization errors]
    fsmooth = [0.0003 0.1065 0.7866 0.1065 0.0003]; %$P: gauss w std==.5
    
    %%% create all the histograms 
    inds={':'};  indshs=inds(:,ones(1,nch));  
    for m=1:nmasks
        
        % remove locations not contributing to minimze work for histc
        % [[wierd code, because optimized]]
        keeplocsi = keeplocs(:,m); 
        maski = masks(:,m); maski=maski(keeplocsi); 
        Ii = reshape( I(repmat(keeplocsi,[1,nch])), [], nch );
        
        % create histograms
        if( nch==1 )
            h = squeeze(histc_1D( Ii, edges, maski ));
        else
            h = histc_nD( Ii, edges, maski );
        end;

        % smooth [if nch==1 or 2 do locally for speed]
        if( nch==1 )
            h = conv2( h, fsmooth, 'same' ); 
        elseif( nch==2 )
            h = conv2( h, fsmooth', 'same' ); 
            h = conv2( h, fsmooth , 'same' ); 
        elseif( nch==3 )
            h = gauss_smooth( h, .5, 'same', 2.5 );
        else
            % no smoothing, too slow 
            %h = gauss_smooth( h, .5, 'same', 2.5 );
        end;
        
            
        % store results
        if( m==1 ) 
            hs=repmat(h, [ones(1,nch), nmasks] ); 
        else
            hs(indshs{:},m) = h; 
        end;
    end; 

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
