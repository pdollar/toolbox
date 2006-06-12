% Divides a volume into softly overlapping gaussian windows.
%
% Return M^nd masks each of size siz.  Each mask represents a symmetric gaussian window
% centered at a different location.  The locations are evenly spaced throughout the array
% of size siz.  For example, if M=2, then along each dimension d the location of each mask
% is either 1/4 or 3/4 of siz(d) and likewise if M=3 that mask is at 1/6,3/6, or 5/6 of
% siz(d). For higher M the locations are: 1/2M,3/2M,...,M-1/2M. 
%
% See examples below to visualize the masks.
%
% The std of each gaussian is set to be equal to the spacing between two adjacent masks
% multiplied by windowwidth.  Reducing the widths of the gaussians causes there to be less
% overlap between masks, but if the width is reduced too far certain pixels in between
% masks receive very little weight.  A desired property of the masks is that their
% coverage (the total weight placed on the pixel by all the masks) is approximately
% constant.  Typically, we settle for having the coverage be monotonically decreasing as
% we move away from the center.  (In reality the coverage oscilates as we move past peaks,
% it's just that the oscillations tend to be tiny).  The default value of windowidth is
% .6, which minimizes overlap while still providing good overall coverage. Values lower
% tend to produce noticeable oscillations in coverage.
%
% offset (in [-1,1]) controls the spacing of the locations.  Essentially, a positive
% offset moves the locations away from the center of the array and a negative offset moves
% the windows away from the center.  Using a positive offset gives better coverage to
% areas near the borders.
%
% INPUTS
%   siz         - dimensions of each mask
%   M           - # of mask locations along each dimension [either scalar or vector]
%   windowwidth - [optional] see above - default: .6
%   offset      - [optional] see above - default: .1
%   show        - [optional] figure to use for display (no display if == 0) (nd<=3)
%
% OUTPUTS
%   masks       - [see above] array of size [siz x M^nd]
%   keeplocs    - logical array of all location where masks is (almost) nonzero
%
% EXAMPLE
%   masks = mask_gaussians( 100, 10, .6, -.1, 1 );  %1D
%   masks = mask_gaussians( [35 35], 3, .6, .1, 1 );  %2D
%   masks = mask_gaussians( [35 35 35], [2 2 4], .6, .1, 1 ); %3D
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also HISTC_SIFT

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function [masks,keeplocs] = mask_gaussians( siz, M, windowwidth, offset, show )
    nd = length(siz);
    if( nargin<3 || isempty(windowwidth)) windowwidth = .6; end;    
    if( nargin<4 || isempty(offset)) offset = .1; end;
    if( nargin<5 || isempty(show) || nd>3 ) show = 0; end;

    %%% uses a cache because operation is very slow, but often called with same inputs.
    persistent cache; if( isempty(cache) ) cache=simplecache('init'); end;
    key = [nd siz M windowwidth offset];
    [found,val] = simplecache( 'get', cache, key ); 
    if( found ) %%% get masks and keeplocs from cache
        [masks,keeplocs] = deal(val{:});
    else %%% create masks and keeplocs
        [M,er] = checknumericargs( M, [1 nd], 0, 2 ); error(er);
        inds = {':'}; inds = inds(:,ones(1,nd));  
        if( abs(offset)>1 ) error('offset too large'); end;
    
        %%% the covariance of each window
        spacing = (siz*(1+2*offset))./M;
        sigmas = spacing * windowwidth;
        C = diag(sigmas.^2);

        %%% create each mask
        masks = zeros( [siz,prod(M)] );
        for c=1:prod(M) 
            sub = ind2sub2( M, c );
            mus = (sub-.5).* spacing + .5-offset*siz;
            masks(inds{:},c) = filter_gauss_nD( siz, mus, C ); 
        end
        keeplocs = masks>1e-7;
        
        %%% place into cache
        cache = simplecache( 'put', cache, key, {masks,keeplocs} );
    end;
        
    %%% optionally display
    if( show )
        if( nd==1 )
            figure(show); clf; plot( masks );
            figure(show+1); clf; plot(sum( masks,nd+1 ));
            a=axis; a(3)=0; axis(a);
            title('coverage');
        elseif( nd==2)
            figure(show); clf; montage2( masks, 1, 1 );        
            figure(show+1); clf; im(sum( masks,nd+1));
            title('coverage');
        elseif( nd==3)
            figure(show); clf; montages2( masks, {0, 1} );        
            figure(show+1); clf; montage2(sum( masks,nd+1), 1, 1 );
            title('coverage');
        end
    end;
    
