function H = computeH(x1,x2,eps,im1,im2)

% x1 and x2 are 2,3, by n,m
% H = vgg_H_from_x_lin(xs1,xs2)
%
% Compute H using linear method (see Hartley & Zisserman Alg 3.2 page 92 in
%                              1st edition, Alg 4.2 page 109 in 2nd edition).
% Point preconditioning is inside the function.
%
% The format of the xs [p1 p2 p3 ... pn], where each p is a 2 or 3
% element column vector.

% Use RANSAC

Nmax=0;
for i=1:100000
  rand1=randsample(size(x1,2),4);
  rand2=randsample(size(x2,2),4);
  H=computeHBasic(x1(:,rand1),x2(:,rand2));
  x1Temp=H*[x1;ones(1,size(x1,2))];
  x1Temp(1,:)=x1Temp(1,:)./x1Temp(3,:);
  x1Temp(2,:)=x1Temp(2,:)./x1Temp(3,:);
  
  D=dist_euclidean(x1Temp(1:2,:)',x2');
  Ntemp=sum(any(D<eps^2,1));
  if Ntemp>Nmax
    Nmax=Ntemp
    H
    figure(1); imshow( imtransform2( im1, H, [], 'loose', 0 ),[]);
    %figure(2); imshow(im2,[]);
  end
end
Nmax

%%%%%%%%%%
  function H=computeHBasic(xs1,xs2)

  [r,c] = size(xs1);

  if (size(xs1) ~= size(xs2))
    error ('Input point sets are different sizes!')
  end

  if (size(xs1,1) == 2)
    xs1 = [xs1 ; ones(1,size(xs1,2))];
    xs2 = [xs2 ; ones(1,size(xs2,2))];
  end

  % condition points
  C1 = vgg_conditioner_from_pts(xs1);
  C2 = vgg_conditioner_from_pts(xs2);
  xs1 = vgg_condition_2d(xs1,C1);
  xs2 = vgg_condition_2d(xs2,C2);

  D = [];
  ooo  = zeros(1,3);
  D=zeros(c,9);
  for k=1:c
    p1 = xs1(:,k);
    p2 = xs2(:,k);
    D(2*k-1,:)=[ p1'*p2(3) ooo -p1'*p2(1) ];
    D(2*k,:)=[ ooo p1'*p2(3) -p1'*p2(2) ];
  end

  % Extract nullspace
  [u,s,v] = svd(D, 0); s = diag(s);

  nullspace_dimension = sum(s < eps * s(1) * 1e3);
  if nullspace_dimension > 1
    %fprintf('Nullspace is a bit roomy...');
  end

  h = v(:,9);

  H = reshape(h,3,3)';

  %decondition
  H = inv(C2) * H * C1;

  H = H/H(3,3);
  end
end
