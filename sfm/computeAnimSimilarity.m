% Compute similarities between frames of a video sequence
%
% It uses 14.3 and 14.4 from HZ2
%
% USAGE
%  playAnimation( A, [fps], [loop], [N] )
%
% INPUTS
%  I       - 3xNxT or 2xNxT array (N=num points, T=num frames)
%  fps     - [100] maximum number of frames to display per second
%            use fps==0 to introduce no pause and have the movie play as
%            fast as possible
%  loop    - [0] number of time to loop video (may be inf),
%            if neg plays video forward then backward then forward etc.
%  N       - [] cell array containing the connectivity neighbors
%
% OUTPUTS
%
% EXAMPLE
%
% See also

% Piotr's Image&Video Toolbox      Version 1.03
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function S = computeAnimSimilarity( A )

if( iscell(A) ); error('cell arrays not supported.'); end;
if( ~ismember(ndims(A),[2 3]) ); error('unsupported dimension of A'); end

siz=size(A); nframes=siz(3); nDim=siz(1); nPoint=siz(2);

% Compute the similarities
S=zeros(nframes,nframes);
for i=1:nframes
  for j=i+1:nframes
    % Alg 14.1 p.351 from HZ2
    X=[A(:,:,i); A(:,:,j)]';
    Xbar=mean(X,1);
    a=X-repmat(Xbar,[nPoint 1]);
    [disc disc V] = svd(a,0);

    N=V(:,4)';
    S(i,j)=norm(N*a')/norm(N);
    S(j,i)=S(i,j);
  end
  imshow(S,[]);
  drawnow;
end
