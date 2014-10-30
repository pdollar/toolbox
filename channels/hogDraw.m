function V = hogDraw( H, w, fhog )
% Create visualization of hog descriptor.
%
% USAGE
%  V = hogDraw( H, [w], [fhog] )
%
% INPUTS
%  H          - [m n oBin*4] computed hog features
%  w          - [15] width for each glyph
%  fhog       - [0] if true draw features returned by fhog
%
% OUTPUTS
%  V          - [m*w n*w] visualization of hog features
%
% EXAMPLE
%
% See also hog, fhog
%
% Piotr's Computer Vision Matlab Toolbox      Version 3.23
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

% fold normalizations
if(nargin<3 || isempty(fhog)), fhog=0; end
m=size(H,3); if(fhog), m=(m-5)/3; H=H(:,:,1:m*3); m=3; else m=4; end
s=size(H); s(3)=s(3)/m; w0=H; H=zeros(s);
for o=0:m-1, H=H+w0(:,:,(1:s(3))+o*s(3)); end;

% construct a "glyph" for each orientaion
if(nargin<2 || isempty(w)), w=15; end
bar=zeros(w,w); bar(:,round(.45*w):round(.55*w))=1;
bars=zeros([size(bar) s(3)]);
for o=1:s(3), bars(:,:,o)=imrotate(bar,-(o-1)*180/s(3),'crop'); end

% make pictures of positive weights by adding up weighted glyphs
H(H<0)=0; V=zeros(w*s(1:2));
for r=1:s(1), rs=(1:w)+(r-1)*w;
  for c=1:s(2), cs=(1:w)+(c-1)*w;
    for o=1:s(3), V(rs,cs)=V(rs,cs)+bars(:,:,o)*H(r,c,o); end
  end
end
