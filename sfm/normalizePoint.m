function [xhat, T] = normalizePoint(x,method)

switch method
  case 3
    xhat=x(1:2,:)./x([3 3],:); xhat(3,:)=1;
  case 4
    xhat=x(1:3,:)./x([4 4 4],:); xhat(4,:)=1;
  case Inf
    if size(x,1)==2; x(3,:)=1; end

    % Only operate on the points that are not at infinity
    finite=abs(x(3,:))>eps;
    x=x(1:2,finite)./repmat(x(3,finite),[2 1]);

    % Get the centroid
    c=mean(x(1:2,finite),2);

    % Get the scale factor
    scale=sqrt(2)/mean(sqrt((x(1,finite)-c(1)).^2+(x(2,finite)-c(2)).^2),2);

    % Apply the scale+centrization
    T=[ scale 0 -scale*c(1); 0 scale -scale*c(2); 0 0 1 ];
    xhat = T*[ x; finite ];
end
