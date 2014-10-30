function F = filmStrip( I, overlap, delta, border )
% Used to display R stacks of T images as a "filmstrip".
%
% See examples below to see what is meant by "filmstrip".
%
% USAGE
%  F = filmStrip( I, overlap, delta, border )
%
% INPUTS
%  I          - MxNxTxR or MxNx1xTxR or MxNx3xTxR array
%               (of bw or color images). R can equal 1.
%  overlap    - amount of overlap between successive frames
%  delta      - amount to shift each successive frame upward
%  border     - width of black border around each frame
%
% OUTPUTS
%  F       - filmstrip
%
% EXAMPLE - one filmstrip
%  load images;
%  F1 = filmStrip( video(:,:,1:15), 10, 2, 5 );   figure(1); im(F1); % one
%  F2 = filmStrip( videos(:,:,:,1:10), 5, 2, 3 ); figure(2); im(F2); % many
%
% See also MONTAGE2
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.0
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

% convert I to be of type double, and have dimensions MxNxCxTxR
I = double(I); I = I/max(I(:)); sizI = size(I);
if(~any(sizI(3)==[1 3])); I=reshape(I,[sizI(1:2),1,sizI(3:end)]); end
I = padarray( I, [border border 0 0 0], 0, 'both' );
[mRows, nCols, nColor, nFrame, nStrip] = size(I);

% size of final filmstip object
sizF1 = [mRows+delta*(nFrame-1), nFrame*nCols-overlap*(nFrame-1), nColor];
sizF=sizF1;  sizF(1)=sizF1(1)*nStrip - ((nFrame-1-2)*delta)*(nStrip-1);
mRowsF1 = sizF1(1);

for i=1:nStrip

  % Create i-th film strip
  Fi = -ones( sizF1 );  row = 1;  col = sizF1(2);
  for f=nFrame:-1:1
    Fi( row:(row+mRows-1), (col-nCols+1):col, : ) = I(:,:,:,f,i);
    row = row + delta;  col = col - nCols + overlap;
  end

  % stop if creating single filmstrip
  if( nStrip==1 ); F=Fi; break; end

  % merge with the previous film strips
  if( i==1 ); F = -ones( sizF );  row2=1;  end
  Fc = F( row2:(row2+mRowsF1-1), : );
  locs=(Fc<0);  Fc(locs) = Fi(locs);
  F( row2:(row2+mRowsF1-1), :  ) = Fc;
  row2 = row2 + mRowsF1 - ((nFrame-1-2)*delta);
end
F(F<0)=1;
