% Normalize points for SFM
%
% USAGE
%  [xHat, T] = normalizePoint(x,method)
%
% INPUTS
%  x       - 2xN or 3xN or 4xN point coordinates
%  method  - 3 (divide by the 3rd coordinate) or 4 (divide by the 4th
%            coordinate) or Inf (mean=sqrt(2) and centered on 0)
%
% OUTPUTS
%  xHat    - the normalized points
%  T       - if method==Inf, it returns the transformation such that
%            xHat=T*x
% EXAMPLE
%
% See also

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function [xHat, T] = normalizePoint(x,method)

switch method
  case 3
    switch size(x,1)
      case 3
        xHat=x(1:2,:)./x([3 3],:); xHat(3,:)=1;
      case 2
        xHat=x(1:2,:); xHat(3,:)=1;
      otherwise
        error('Wrong input size');
    end
  case 4
    switch size(x,1)
      case 4
        xHat=x(1:3,:)./x([4 4 4],:); xHat(4,:)=1;
      case 3
        xHat=x(1:3,:); xHat(4,:)=1;
      otherwise
        error('Wrong input size');
    end
  case Inf
    if size(x,1)==2; x(3,:)=1; end

    % Only operate on the points that are not at infinity
    finite=abs(x(3,:))>eps;
    x=x(1:2,finite)./x([3 3],finite);

    % Get the centroid
    c=mean(x(1:2,finite),2);

    % Get the scale factor
    scale=sqrt(2)/mean(sqrt((x(1,finite)-c(1)).^2+...
      (x(2,finite)-c(2)).^2),2);

    % Apply the scale+centrization
    T=[ scale 0 -scale*c(1); 0 scale -scale*c(2); 0 0 1 ];
    xHat = T*[ x; finite ];
end
