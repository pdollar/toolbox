function C = convnFast( A, B, shape )
% Fast convolution, replacement for both conv2 and convn.
%
% See conv2 or convn for more information on convolution in general.
%
% This works as a replacement for both conv2 and convn.  Basically,
% performs convolution in either the frequency or spatial domain, depending
% on which it thinks will be faster (see below). In general, if A is much
% bigger then B then spatial convolution will be faster, but if B is of
% similar size to A and both are fairly big (such as in the case of
% correlation), convolution as multiplication in the frequency domain will
% tend to be faster.
%
% The shape flag can take on 1 additional value which is 'smooth'.  This
% flag is intended for use with smoothing kernels.  The returned matrix C
% is the same size as A with boundary effects handled in a special manner.
% That is instead of A being zero padded before being convolved with B;
% near the boundaries a cropped version of the matrix B is used, and the
% results is scaled by the fraction of the weight found in  the cropped
% version of B.  In this case each dimension of B must be odd, and all
% elements of B must be positive.  There are other restrictions on when
% this flag can be used, and in general it is only useful for smoothing
% kernels.  For 2D filtering it does not have much overhead, for 3D it has
% more and for higher dimensions much much more.
%
% For optimal performance some timing constants must be set to choose
% between doing convolution in the spatial and frequency domains, for more
% info see timeConv below.
%
% USAGE
%  C = convnFast( A, B, [shape] )
%
% INPUTS
%  A       - d dimensional input matrix
%  B       - d dimensional matrix to convolve with A
%  shape   - ['full'] 'valid', 'full', 'same', or 'smooth'
%
% OUTPUTS
%  C       - result of convolution
%
% EXAMPLE
%
% See also CONV2, CONVN
%
% Piotr's Image&Video Toolbox      Version 2.61
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<3 || isempty(shape)); shape='full'; end
if( ~any(strcmp(shape,{'same', 'valid', 'full', 'smooth'})) )
  error( 'convnFast: unknown shape flag' ); end

shapeorig = shape;
smoothFlag = (strcmp(shape,'smooth'));
if( smoothFlag ); shape = 'same'; end;

% get dimensions of A and B
ndA = ndims(A);  ndB = ndims(B); nd = max(ndA,ndB);
sizA = size(A); sizB = size(B);
if (ndA>ndB); sizB = [sizB ones(1,ndA-ndB)]; end
if (ndA<ndB); sizA = [sizA ones(1,ndB-ndA)]; end

% ERROR CHECK if smoothflag
if( smoothFlag )
  if( ~all( mod(sizB,2)==1 ) )
    error('If flag==''smooth'' then must have odd sized mask');
  end;
  if( ~all( B>0 ) )
    error('If flag==''smooth'' then mask must have >0 values.');
  end;
  if( any( (sizB-1)/2>sizA ) )
    error('B is more then twice as big as A, cannot use flag==''smooth''');
  end;
end

% OPTIMIZATION for 3D conv when B is actually 2D - calls (spatial) conv2
% repeatedly on 2D slices of A.  Note that may need to rearange A and B
% first and use recursion. The benefits carry over to convnBound
% (which is faster for 2D arrays).
if( ndA==3 && ndB==3 && (sizB(1)==1 || sizB(2)==1) )
  if (sizB(1)==1)
    A = permute( A, [2 3 1]);  B = permute( B, [2 3 1]);
    C = convnFast( A, B, shapeorig );
    C = permute( C, [3 1 2] );
  elseif (sizB(2)==1)
    A = permute( A, [3 1 2]);  B = permute( B, [3 1 2]);
    C = convnFast( A, B, shapeorig );
    C = permute( C, [2 3 1] );
  end
  return;
elseif( ndA==3 && ndB==2 )
  C1 = conv2( A(:,:,1), B, shape );
  C = zeros( [size(C1), sizA(3)] ); C(:,:,1) = C1;
  for i=2:sizA(3); C(:,:,i) = conv2( A(:,:,i), B, shape ); end
  if (smoothFlag)
    for i=1:sizA(3)
      C(:,:,i) = convnBound(A(:,:,i),B,C(:,:,i),sizA(1:2),sizB(1:2));
    end
  end
  return;
end

% get predicted time of convolution in frequency and spatial domain
% constants taken from timeConv
sizfft = 2.^ceil(real(log2(sizA+sizB-1))); psizfft=prod(sizfft);
frequenPt = 3 * 1e-7 * psizfft * log(psizfft);
if (nd==2)
  spatialPt = 5e-9 * sizA(1) * sizA(2) * sizB(1) * sizB(2);
else
  spatialPt = 5e-8 * prod(sizA) * prod(sizB);
end

% perform convolution
if ( spatialPt < frequenPt )
  if (nd==2)
    C = conv2( A, B, shape );
  else
    C = convn( A, B, shape );
  end
else
  C = convnFreq( A, B, sizA, sizB, shape );
end;


% now correct boundary effects (if shape=='smooth')
if( ~smoothFlag ); return; end;
C = convnBound( A, B, C, sizA, sizB );

function C = convnBound( A, B, C, sizA, sizB )
% calculate boundary values for C in spatial domain

nd = length(sizA);
radii = (sizB-1)/2;

% flip B appropriately (conv flips B)
for d=1:nd; B = flipdim(B,d); end

% accelerated case for 1D mask B
if( nd==2 && sizB(1)==1 )
  sumB=sum(B(:)); r=radii(2); O=ones(1,sizA(1));
  for i=1:r
    Ai=A(:,1:r+i); Bi=B(r+2-i:end);
    C(:,i)=sum(Ai.*Bi(O,:),2)/sum(Bi)*sumB;
    Ai=A(:,end+1-r-i:end); Bi=B(1:(end-r+i-1));
    C(:,end-i+1)=sum(Ai.*Bi(O,:),2)/sum(Bi)*sumB;
  end; return;
elseif( nd==2 && sizB(2)==1 )
  sumB=sum(B(:)); r=radii(1); O=ones(1,sizA(2));
  for i=1:r
    Ai=A(1:r+i,:); Bi=B(r+2-i:end);
    C(i,:)=sum(Ai.*Bi(:,O),1)/sum(Bi)*sumB;
    Ai=A(end+1-r-i:end,:); Bi=B(1:(end-r+i-1));
    C(end-i+1,:)=sum(Ai.*Bi(:,O),1)/sum(Bi)*sumB;
  end; return;
end

% get location that need to be updated
inds = {':'}; inds = inds(:,ones(1,nd));
Dind = zeros( sizA );
for d=1:nd
  inds1 = inds; inds1{ d } = 1:radii(d);
  inds2 = inds; inds2{ d } = sizA(d)-radii(d)+1:sizA(d);
  Dind(inds1{:}) = 1;  Dind(inds2{:}) = 1;
end
Dind = find( Dind );
Dndx = ind2sub2( sizA, Dind );
nlocs = length(Dind);

% get cuboid dimensions for all the boundary regions
sizeArep = repmat( sizA, [nlocs,1] );
radiiRep = repmat( radii, [nlocs,1] );
Astarts = max(1,Dndx-radiiRep);
Aends = min( sizeArep, Dndx+radiiRep);
Bstarts = Astarts + (1-Dndx+radiiRep);
Bends = Bstarts + (Aends-Astarts);

% now update these locations
vs = zeros( 1, nlocs );
if( nd==2 )
  for i=1:nlocs % accelerated for 2D arrays
    Apart = A( Astarts(i,1):Aends(i,1), Astarts(i,2):Aends(i,2) );
    Bpart = B( Bstarts(i,1):Bends(i,1), Bstarts(i,2):Bends(i,2) );
    v = (Apart.*Bpart); vs(i) = sum(v(:)) ./ sum(Bpart(:));
  end
elseif( nd==3 ) % accelerated for 3D arrays
  for i=1:nlocs
    Apart = A( Astarts(i,1):Aends(i,1), Astarts(i,2):Aends(i,2), ...
      Astarts(i,3):Aends(i,3) );
    Bpart = B( Bstarts(i,1):Bends(i,1), Bstarts(i,2):Bends(i,2), ...
      Bstarts(i,3):Bends(i,3) );
    za = sum(sum(sum(Apart.*Bpart))); zb=sum(sum(sum(Bpart)));
    vs(1,i) = za./zb;
  end
else % general case [slow]
  extract=cell(1,nd);
  for i=1:nlocs
    for d=1:nd; extract{d} = Astarts(i,d):Aends(i,d); end
    Apart = A( extract{:} );
    for d=1:nd; extract{d} = Bstarts(i,d):Bends(i,d); end
    Bpart = B( extract{:} );
    v = (Apart.*Bpart); vs(i) = sum(v(:)) ./ sum(Bpart(:));
  end
end
C( Dind ) = vs * sum(B(:));

function C = convnFreq( A, B, sizA, sizB, shape )
% Convolution as multiplication in the frequency domain

siz = sizA + sizB - 1;

% calculate correlation in frequency domain
Fa = fftn(A,siz);
Fb = fftn(B,siz);
C = ifftn(Fa .* Fb);

% make sure output is real if inputs were both real
if(isreal(A) && isreal(B)); C = real(C); end

% crop to size
if(strcmp(shape,'valid'))
  C = arrayToDims( C, max(0,sizA-sizB+1 ) );
elseif(strcmp(shape,'same'))
  C = arrayToDims( C, sizA );
elseif(~strcmp(shape,'full'))
  error('unknown shape');
end

function K = timeConv() %#ok<DEFNU>
% Function used to calculate constants for prediction of convolution in the
% frequency and spatial domains.  Method taken from normxcorr2.m
% May need to reset K's if placing this on a new machine, however, their
% ratio should be about the same..

mintime = 4;

switch 3
  case 1  % conv2  [[empirically K = 5e-9]]
    % convolution time = K*prod(size(a))*prod(size(b))
    siza = 30;  sizb = 200;
    a = ones(siza);  b = ones(sizb);
    t1 = cputime;  t2 = t1; k = 0;
    while (t2-t1)<mintime;
      disc = conv2(a,b); k = k + 1; t2 = cputime; %#ok<NASGU>
    end
    K = (t2-t1)/k/siza^2/sizb^2;
    
  case 2  % convn  [[empirically K = 5e-8]]
    % convolution time = K*prod(size(a))*prod(size(b))
    siza = [10 10 10];  sizb = [30 30 10];
    a = ones(siza);  b = ones(sizb);
    t1 = cputime;  t2 = t1;  k = 0;
    while (t2-t1)<mintime;
      disc = convn(a,b); k = k + 1; t2 = cputime; %#ok<NASGU>
    end
    K = (t2-t1)/k/prod(siza)/prod(sizb);
    
  case 3 % fft (one dimensional) [[empirically K = 1e-7]]
    % fft time = K * n log(n)  [if n is power of 2]
    % Works fastest for powers of 2.  (so always zero pad until have
    % size of power of 2?).  2 dimensional fft has to apply single
    % dimensional fft to each column, and then signle dimensional fft
    % to each resulting row.  time = K * (mn)log(mn).  Likewise for
    % highter dimensions.  convnFreq requires 3 such ffts.
    n = 2^nextpow2(2^15);
    vec = complex(rand(n,1),rand(n,1));
    t1 = cputime;  t2 = t1;  k = 0;
    while (t2-t1) < mintime;
      disc = fft(vec); k = k + 1; t2 = cputime; %#ok<NASGU>
    end
    K = (t2-t1) / k / n / log(n);
end
