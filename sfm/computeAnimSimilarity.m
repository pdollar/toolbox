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

siz=size(A); nFrame=siz(3);

% Compute the similarities
if A.isProj
  S=zeros(nFrame,nFrame); SMax=S;
  ticId = ticStatus('Similarities Computed');
  for i=1:nFrames-1
    for j=i+1:nFrames
      % Alg 14.1 p.351 from HZ2
     [SMax(i,j),disc,S(i,j)]=computeSMFromx(anim.A2(:,:,i),...
       anim.A2(:,:,j),isProj,method,true);
    end
    S(i+1:end,i)=S(i,i+1:end); SMax(i+1:end,i)=SMax(i,i+1:end);
    temp=nFrames*(nFrames-1)/2;
    tocStatus( ticId, 1-(nFrames-i)*(nFrames-i-1)/2/temp );
  end
end
