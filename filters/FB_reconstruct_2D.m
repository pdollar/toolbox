% Use to see how much image information is preserved in filter outputs.
%
% Reconstructs the orginal image from filter outputs (approximately). The
% filter output for a patch is given by IFR=F*P where F is the set of
% filters in matrix form, P is the patch and IFR is the filter responses at
% the center of the patch.  We want to recover P from IFR and F, this is
% underconstrained but a solution can be found using least squared.  Note
% that each recovered P will be 0 mean if no mean information is captured
% by the filter outputs.  Can apply to a single patch (interatctively
% specified), or the entire image (by keeping the central pixel from each
% patch).
%
% USAGE
%  I2 = FB_reconstruct_2D( I, FB, patch )
%
% INPUTS
%  I      - original image
%  FB     - FB to apply and do reconstruction with
%  patch  - reconstruct just patch or entire image
%
% OUTPUTS
%  I2     - reconstructed image / patch
%
% EXAMPLE
%  load trees; X=imresize(X,.5); load FB_DoG.mat;
%  I2 = FB_reconstruct_2D( X, FB, 0 );

% Piotr's Image&Video Toolbox      Version 1.5
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function I2 = FB_reconstruct_2D( I, FB, patch )

FBmrows = size(FB,1); FBncols = size(FB,2);
FBrowRad = (FBmrows-1)/2;  FBcolRad = (FBncols-1)/2;
[mrows,ncols] = size(I);

% add mean vector to filterbank (helps for visualization to have mean)
if(0); FB = cat(3, FB, ones([FBmrows FBncols])/FBmrows/FBncols ); end;

% get FB responses
IFR = FB_apply_2D( I, FB, 'same' );

% create matrix F such that F*vectorized patch=filter response
F = reshape( FB, FBmrows*FBncols, [] ); F=F'; F=fliplr(F);
Finv = pinv(F);

if( patch ) %%% recover a specific patch

  % interactively get a specific r,c
  figure(1); clf;  im(I);
  [c,r] = ginput(1); r=round(r); c=round(c);
  hold('on'); plot( c, r, '+r' ); hold('off');

  % recover a given window patch
  IFRrc = squeeze( IFR(r,c,:) );
  P = reshape( Finv*IFRrc, FBmrows, FBncols );
  I2 = P;

  % get the true image window around given point
  rs = max(1,r-FBrowRad):min(r+FBrowRad,mrows);
  cs = max(1,c-FBcolRad):min(c+FBcolRad,ncols);
  Irc = I( rs, cs );

  % show the true window vs the recovered window
  figure(2); im( Irc );
  hold('on'); plot( FBrowRad+1, FBcolRad+1, '+r' ); hold('off');
  figure(3); im( P );
  hold('on'); plot( FBrowRad+1, FBcolRad+1, '+r' ); hold('off');

else %%% recover entire image
  if( 1 ) % reconstruction filter (for merging recovered patches)
    W = filter_binomial_1D( 1 );
    W = W * W';
  else
    W = [0 0 0; 0 1 0; 0 0 0];
  end

  I2 = zeros( size(IFR,1)+2, size(IFR,2)+2 );
  ind_r = (FBmrows+1)/2;  ind_c = (FBncols+1)/2;
  for r=1:size(IFR,1);
    for c=1:size(IFR,2)
      % recover the patch (vectorized) at this point
      IFRrc = squeeze( IFR(r,c,:) );
      P = reshape( Finv*IFRrc, FBmrows, FBncols );

      % update overall image by adding central 3x3 patch (weighted)
      Idelta = W .* P( ind_r-1:ind_r+1, ind_c-1:ind_c+1 );
      I2(r:r+2,c:c+2) = I2( r:r+2,c:c+2 ) + Idelta;
    end;
  end;
  I2 = arraycrop2dims( I2, size(I2)-2 );

  % display
  figure(1); clf;
  subplot(2,2,1); montage2( IFR, 1 );
  subplot(2,2,2); montage2( FB, 1 );
  subplot(2,2,3); im( I );
  subplot(2,2,4); im( I2 );
end
