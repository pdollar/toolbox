% [4D] Used to display R stacks of T images as a filmstrip.
%
% USAGE
%  Ftot = filmStrip( Itot, overlap, delta, border )
%
% INPUTS
%  Itot       - MxNxTxR or MxNx1xTxR or MxNx3xTxR array
%               (of bw or color images). R can equal 1.
%  overlap    - amount of overlap between successive frames
%  delta      - amount to shift each successive frame upward
%  border     - width of black border around each frame
%
% OUTPUTS
%  Ftot       - filmstrip
%
% EXAMPLE
%  load images;
%  F = filmStrip( video(:,:,1:15), 10, 2, 5 );
%  figure(1); im(F);
%  F = filmStrips( videos(:,:,:,1:10), 5, 2, 3 );
%  figure(2); im(F);
%
% See also MONTAGE2

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function Ftot = filmStrip( Itot, overlap, delta, border )

Itot = double(Itot); Itot = Itot/max(Itot(:));

siz=size(Itot);
if ~any(siz(3)==[1 3]); Itot=reshape(Itot,[siz(1:2),1,siz(3:end)]); end

h = 1;
nColor=size(Itot,3); nframes = size(Itot,4); nStrip=size(Itot,5);

for i=1:nStrip
  I = padarray( Itot(:,:,:,:,i), [border border 0 0], 0, 'both' );
  mrows=size(I,1); ncols=size(I,2);

  % Create the film strip
  siz = [mrows+delta*(nframes-1), nframes*ncols-overlap*(nframes-1)];
  F = -ones( [siz nColor] ) * double(max(I(:)));
  row = 1; col = siz(2);
  for f=nframes:-1:1
    F( row:(row+mrows-1), (col-ncols+1):col, : ) = I(:,:,:,f);
    row = row + delta; col = col - ncols + overlap;
  end

  if nStrip==1; Ftot=F; break; end

  % merge with the previous film strips
  if( i==1 )
    sizF = size(F);  nrows = sizF(1);
    sizF(1) = nrows*nStrip - ((nframes-1)*delta-2*delta)*(nStrip-1);
    Ftot = -ones( sizF );
  end
  Fc = Ftot( h:(h+nrows-1), : ); locs = (Fc<0);
  Fc( locs ) = F( locs );
  Ftot( h:(h+nrows-1), :  ) = Fc;
  h = h + nrows - ((nframes-1)*delta-2*delta);
end
Ftot(Ftot<0)=1;
