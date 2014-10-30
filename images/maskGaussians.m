function [masks,keepLocs] = maskGaussians( siz, M, width, offset, show )
% Divides a volume into softly overlapping gaussian windows.
%
% Return M^nd masks each of size siz.  Each mask represents a symmetric
% gaussian window, the locations are evenly spaced throughout the array of
% size siz.  For example, if M=2, then along each dimension d the location
% of each mask is either 1/4 or 3/4 of siz(d) and likewise if M=3 that mask
% is at 1/6,3/6, or 5/6 of siz(d). For higher M the locations are:
% 1/2M,3/2M,...,M-1/2M. See examples below to visualize the masks.
%
% The std of each gaussian is set to be equal to the spacing between two
% adjacent masks multiplied by width.  Reducing the widths of the gaussians
% causes there to be less overlap between masks, but if the width is
% reduced too far certain pixels in between masks receive very little
% weight.  A desired property of the masks is that their coverage (the
% total weight placed on the pixel by all the masks) is approximately
% constant.  Typically, we settle for having the coverage be monotonically
% decreasing as we move away from the center.  (In reality the coverage
% oscilates as we move past peaks, it's just that the oscillations tend to
% be small).  The default value of the width is .6, which minimizes overlap
% while still providing good overall coverage. Values lower tend to produce
% noticeable oscillations in coverage.  offset in (-.5,1) controls the
% spacing of the locations.  Essentially, a positive offset moves the
% locations away from the center of the array and a negative offset moves
% the windows away from the center.  Using a positive offset gives better
% coverage to areas near the borders.
%
% USAGE
%  [masks,keepLocs] = maskGaussians( siz, M, [width], [offset], [show] )
% 
% INPUTS
%  siz         - dimensions of each mask
%  M           - # mask locations along each dim [either scalar or vector]
%  width       - [.6] widths of the gaussians
%  offset      - [.1] spacing of mask centers; in (-.5,1)
%  [show]      - [0] figure to use for display (no display if==0) (nd<=3)
%
% OUTPUTS
%  masks       - [see above] array of size [siz x M^nd]
%  keepLocs    - logical array of all locs where masks is nonzero
%
% EXAMPLE
%  masks = maskGaussians( 100, 10, .6, -.1, 1 );  %1D
%  masks = maskGaussians( [35 35], 3, .6, .1, 1 );  %2D
%  masks = maskGaussians( [35 35 35], [2 2 4], .6, .1, 1 ); %3D
%
% See also HISTCIMLOC, MASKCIRCLE
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.0
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

nd = length(siz);
if( nargin<3 || isempty(width)); width = .6; end;    
if( nargin<4 || isempty(offset)); offset = .1; end;
if( nargin<5 || isempty(show) || nd>3 ); show = 0; end;

%%% uses a cache since this is slow but often called with same inputs.
persistent cache; if( isempty(cache) ); cache=simpleCache('init'); end;
key = [nd siz M width offset];
[found,val] = simpleCache( 'get', cache, key ); 
if( found ) %%% get masks and keepLocs from cache
  [masks,keepLocs] = deal(val{:});
else %%% create masks and keepLocs
  [M,er] = checkNumArgs( M, [1 nd], 0, 2 ); error(er);
  inds = {':'}; inds = inds(:,ones(1,nd));  
  if( offset<=-.5 || offset>=1 ); error('offset must be in (-.5,1)'); end;

  %%% the covariance of each window
  spacing = (siz*(1+2*offset))./M;
  sigmas = spacing * width;
  C = diag(sigmas.^2);
  
  %%% create each mask
  masks = zeros( [siz,prod(M)] );
  for c=1:prod(M) 
    sub = ind2sub2( M, c );
    mus = (sub-.5).* spacing + .5-offset*siz;
    masks(inds{:},c) = filterGauss( siz, mus, C );
  end
  keepLocs = masks>1e-7;

  %%% place into cache
  cache = simpleCache( 'put', cache, key, {masks,keepLocs} );
end;

%%% optionally display
if( show )
  if( nd==1 )
    figure(show); clf; plot( masks );
    figure(show+1); clf; plot(sum( masks,nd+1 ));
    a=axis; a(3)=0; axis(a);
    title('coverage');
 elseif( nd==2)
    figure(show); clf; montage2( masks );        
    figure(show+1); clf; im(sum( masks,nd+1));
    title('coverage');
  elseif( nd==3)
    figure(show); clf; montage2( masks );        
    figure(show+1); clf; montage2(sum( masks,nd+1) );
    title('coverage');
  end
end;
    
