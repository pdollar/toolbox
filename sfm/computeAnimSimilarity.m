% Compute similarities between frames of a video sequence
%
% It uses Alg 14.1 p.351 from HZ2
%
% USAGE
%  [S, SMax] = computeAnimSimilarity( A )
%
% INPUTS
%  A     - anim object (see generateToyAnimation for details)
%
% OUTPUTS
%  S     - FxF similarity matrix (F=number of frames) based on average
%          reconstruction error
%  SMax  - FxF similarity matrix (F=number of frames) based on max
%          reconstruction error
%
% EXAMPLE
%
% See also GENERATETOYANIMATION, VIEWANIMSIMILARITY

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function [S, SMax] = computeAnimSimilarity( A )

if( iscell(A) ); error('cell arrays not supported.'); end;
if( ~ismember(ndims(A),[2 3]) ); error('unsupported dimension of A'); end

siz=size(A); nFrames=siz(3); nPoint=siz(2);
if size(A,1)==3; A=A(1:2,:,:)./A([3 3],:,:); end

% Compute the similarities
if A.isProj
  S=zeros(nFrames,nFrames); SMax=S;
  for i=1:nFrames
    XBar=mean(A(:,:,i),2); A(:,:,i)=A(:,:,i)-XBar(:,ones(1,nPoint));
  end
  ticId = ticStatus('Similarities Computed');
  for i=1:nFrames-1
    for j=i+1:nFrames
      % Alg 14.1 p.351 from HZ2
      a=[A(:,:,i); A(:,:,j)]';
      [disc disc V] = svd(a,0);

      N=V(:,4);
      if nargout==1; S(i,j)=(norm(a*N,'fro')/norm(N))^2;
      else
        temp=a*N; temp=sum(temp.^2,2); SMax(i,j)=max(temp)/norm(N)^2;
        S(i,j)=sum(temp)/norm(N)^2;
      end
    end
    S(i+1:end,i)=S(i,i+1:end); SMax(i+1:end,i)=SMax(i,i+1:end);
    temp=nFrames*(nFrames-1)/2;
    tocStatus( ticId, 1-(nFrames-i)*(nFrames-i-1)/2/temp );
  end
end