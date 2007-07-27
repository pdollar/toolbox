% Compute similarities between frames of a video sequence
%
% It uses 14.3 and 14.4 from HZ2
%
% USAGE
%  playAnimation( A, [fps], [loop], [N] )
%
% INPUTS
%  A     - 2xNxT or 3xNxT array (N=num points, T=num frames)
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

siz=size(A); nframes=siz(3); nPoint=siz(2);
if size(A,1)==3; A=A(1:2,:,:)./A([3 3],:,:); end

% Compute the similarities
S=zeros(nframes,nframes);
for i=1:nframes
  for j=i+1:nframes
    % Alg 14.1 p.351 from HZ2
    X=[A(:,:,i); A(:,:,j)]';
    XBar=mean(X,1); a=X-repmat(XBar,[nPoint 1]);
    [disc disc V] = svd(a,0);

    N=V(:,4); S(i,j)=(norm(a*N)/norm(N))^2;
  end
  S(i+1:end,i)=S(i,i+1:end);
  imshow(S,[]); drawnow;
end
