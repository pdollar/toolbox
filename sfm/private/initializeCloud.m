% Display a point cloud animation
%
% USAGE
%  initializeCloud( prm )
%
% INPUTS
%  I       - Nx3xT or Nx2xT array (N=num points, T=num frames)
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

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function [hPoint, hCam]=initializeCloud( prm )

dfs = {'t',[],'R',[],'nCam',-1,'c',[0 0 1],'N',[],'i',1,'A','REQ',...
  'bound',[]};
prm = getPrmDflt( prm, dfs );
t=prm.t; R=prm.R; nCam=prm.nCam; c=prm.c; N=prm.N; i=prm.i;
A=prm.A; bound=prm.bound;

nDim=size(A,1);

% Initialize the point cloud
if ~isempty(N)
  % Define some connectivities
  conn = cell(1,nPoint); coord=cell(1,3);
  for j = 1 : nPoint; conn{j}(:,2) = N{j}'; conn{j}(:,1) = i; end
  conn = cell2mat(conn');
  for j=1:nDim; coord{j}=[A(j,conn(:,1),i),A(j,conn(:,2),i)]'; end

  if nDim==3; hPoint=line(coord{1},coord{2},coord{3});
  else hPoint=line(coord{1},coord{2}); end
else
  if nDim==3; hPoint=plot3(A(1,:,i),A(2,:,i),A(3,:,i));
  else hPoint=plot(A(1,:,i),A(2,:,i)); end
  set(hPoint,'LineStyle','none');
end
set(hPoint,'Color',c,'Marker','.'); hold on;
hPoint(2)=plot3(A(1,1,i),A(2,1,i),A(3,1,i),'ks','MarkerSize',10);

% Initialize the cameras
if nCam>=0
  hCam=zeros(1+2*nCam,8);
  hCam(1,:)=plotPyramid(t(:,i),R(:,:,i),'r',1); l=2;
  for j=[i-nCam:i-1,i+1:i+nCam]
    m=j; m=max([1 m]); m=min([m size(A,3)]);
    hCam(l,:)=plotPyramid(t(:,m),R(:,:,m),'b',0.5);
    l=l+1;
  end
else
  hCam=[];
end
axis(bound);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h=plotPyramid(t,R,c,scale)

X=[-1 -1 0; 1 -1 0; 1 1 0; -1 1 0; 0 0 2]'*scale;
X(3,:)=X(3,:)+5; X=R'*(X-repmat(t,[1 5]));

XX=cell(1,3);
for k=1:3
  XX{k}=[X(k,1:2); X(k,2:3); X(k,3:4); X(k,[4 1]); X(k,[1 5]); ...
    X(k,[2 5]); X(k,[3 5]); X(k,[4 5])]';
end
h=line(XX{1},XX{2},XX{3},'Color',c)';
