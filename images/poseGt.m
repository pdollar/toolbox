function varargout = poseGt( action, varargin )
% Object pose annotations struct.
%
% An object composed of n parts is is a [nx1] struct partrs, with the
% following (scalar) fields:
%  prn    - part parent (or 0 if root part)
%  x      - joint location (relative to parent)
%  y      - joint location (relative to parent)
%  ang    - part angle (relative to parent)
%  scl    - part scale (relative to parent)
%  asp    - part a.r.  (relative to parent)
%  angLk  - if lock=1 part ang is locked
%  sclLk  - if lock=1 part scl is locked
%  aspLk  - if lock=1 part asp is locked
% A few additional notes. The first part is always the root. Object
% position is given relative to [-1,1]x[-1,1] (and is independent of image
% size). ang is in radians. scl and asp are in log2 space (i.e. scl=-1
% indicates a scale of 2^-1=.5).
%
% poseGt contains a number of utility functions, accessed using:
%  outputs = poseGt( 'action', inputs );
% The list of functions and help for each is given below. Also, help on
% individual subfunctions can be accessed by: "help poseGt>action".
%
%%% Data structure for storing object part annotations.
% Create placeholder for object with n parts.
%   parts = create( n, varargin )
% Save object part annotation to text file.
%   parts = poseGt( 'objSave', parts, fName )
% Load object part annotation from text file.
%   parts = poseGt( 'objLoad', fName )
% Get part property 'name' (in a standard array).
%   vals = poseGt( 'getVals', parts, name )
% Set part property 'name' (with a standard array).
%   parts = poseGt( 'setVals', parts, name, vals )
% Return nx5 absolute position of each part.
%   bb = getAbsPos( parts, W, H )
% Set location of part id using given absolute position.
%   parts = setAbsPos( parts, id, bb, W, H )
% Return cumulative pose for each part.
%   [ang,scl,asp,ps] = getCumPose( parts )
%
% USAGE
%  varargout = poseGt( action, varargin );
%
% INPUTS
%  action     - string specifying action
%  varargin   - depends on action, see above
%
% OUTPUTS
%  varargout  - depends on action, see above
%
% EXAMPLE
%
% See also poseGt>create, poseGt>objSave, poseGt>objLoad, poseGt>getVals,
% poseGt>setVals
%
% Piotr's Image&Video Toolbox      Version NEW
% Copyright 2009 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

%#ok<*DEFNU>
varargout = cell(1,max(1,nargout));
[varargout{:}] = feval(action,varargin{:});
end

function parts = create( n )
% Create placeholder for object with n parts.
parts=repmat(struct('prn',1,'x',0,'y',0,'ang',0,'scl',0,'asp',0,...
  'angLk',0,'sclLk',0,'aspLk',0),[1 n]); parts(1).prn=0;
end

function parts = objSave( parts, fName )
% Save object part annotation to text file.
fid=fopen(fName,'w'); if(fid==-1), error('unable to open %s',fName); end
fprintf(fid,'%% poseGt version=1 n=%i\n',length(parts));
fs={'prn','x','y','ang','scl','asp','angLk','sclLk','aspLk'};
for i=1:9, fprintf(fid,'%f ',getVals(parts,fs{i})); fprintf(fid,'\n'); end
fclose(fid);
end

function parts = objLoad( fName )
% Load object annotation from text file.
fid=fopen(fName,'r'); if(fid==-1), error('unable to open %s',fName); end
out=fscanf(fid,'%% poseGt version=%d n=%d\n'); v=out(1); n=out(2);
if(v~=1), fclose(fid); error('Unknown version %i.',v); end;
parts=create(n);
fs={'prn','x','y','ang','scl','asp','angLk','sclLk','aspLk'};
for i=1:9, parts=setVals(parts,fs{i},fscanf(fid,'%f',n)); end
fclose(fid);
end

function vals = getVals( parts, name )
% Get part property 'name' (in a standard array).
vals=[parts.(name)]';
end

function parts = setVals( parts, name, vals )
% Set part property 'name' (with a standard array).
for i=1:length(parts), parts(i).(name)=vals(i); end
end

function bb = getAbsPos( parts, W, H )
% Return nx5 absolute position of each part.
n=length(parts); bb=zeros(n,5);
[angc,sclc,aspc,ps] = getCumPose(parts);
for i=1:n
  scl=2^sclc(i); asp=2^aspc(i); ang=angc(i);
  w=asp*scl; h=scl; ang=(pi/2-ang)/pi*180;
  bb(i,:)=[(1-ps(1,i)-w)*W/2 (1+ps(2,i)-h)*H/2 w*W h*H ang];
end
end

function parts = setAbsPos( parts, id, bb, W, H )
% Set location of part id using given absolute position.
p=parts(id); ang=(90-bb(5))/180*pi;
scl=bb(4)/H; asp=bb(3)/W/scl; scl=log2(scl); asp=log2(asp);
[angc,sclc,aspc,ps] = getCumPose(parts);
angd=angc(id)-ang; scld=sclc(id)-scl; aspd=aspc(id)-asp;
% drag by changing x,y for root
if(id==1 || (abs(angd)<1e-10 && abs(scld)<1e-10 && abs(aspd)<1e-10))
  x=1-(2*bb(1)+bb(3))/W - ps(1,id); parts(1).x=parts(1).x+x;
  y=(2*bb(2)+bb(4))/H-1 - ps(2,id); parts(1).y=parts(1).y+y;
end
% alter part as flags allow
if(~p.angLk), parts(id).ang=p.ang-angd; end
if(~p.sclLk), parts(id).scl=p.scl-scld; end
if(~p.aspLk), parts(id).asp=p.asp-aspd; end
end

function [ang,scl,asp,ps] = getCumPose( parts )
% Return cumulative pose for each part.
n=length(parts); MS=zeros(2,2,n); ps=zeros(2,n);
Z=zeros(1,n); ang=Z; scl=Z; asp=Z; init=Z;
p=parts(1); ang(1)=p.ang; scl(1)=p.scl; asp(1)=p.asp; init(1)=1;
for i=2:n % Compute ang, scl and asp
  p=parts(i); j=p.prn; assert(init(j)==1); init(i)=1;
  ang(i)=p.ang+ang(j); scl(i)=p.scl+scl(j); asp(i)=p.asp+asp(j);
end
for i=1:n % Compute center positions
  p=parts(i); c=cos(pi/2+ang(i)); s=sin(pi/2+ang(i));
  MS(:,:,i)=[2^asp(i)*c -s; 2^asp(i)*s c]*2^scl(i); pc=[p.x p.y]';
  if(i>1), pc=MS(:,:,i)*[0 1]'+MS(:,:,p.prn)*pc+ps(:,p.prn); end;
  ps(:,i)=pc;
end
end
