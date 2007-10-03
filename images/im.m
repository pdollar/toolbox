% Function for displaying grayscale images.
%
% Handy function for showing a grayscale image with a colorbar and
% interactive pixel info tool.
%
% USAGE
%  im( I, [range], [extraInf] )
%
% INPUTS
%  I        - image in a valid format
%  range    - [] minval/maxval for imagesc
%  extraInf - [1] if 1 then a colorbar is shown as well as impixelinfo
%
% OUTPUTS
%  X        - X after normalization.
%
% EXAMPLE
%  load clown; im( X )
%
% See also IMSHOW, IMVIEW, IMPIXELINFO

% Piotr's Image&Video Toolbox      Version 2.0
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function im( I, range, extraInf )

if( nargin<1 || isempty(I)); I=0; end;
if( nargin<2 || isempty(range))
  imagesc(I);
else
  imagesc(I,range)
end
if( nargin<3 || isempty(extraInf)); extraInf=1; end;

colormap(gray);
title(inputname(1));
axis('image');

% info about image pixels
if( extraInf )
  impixelinfo;
  colorbar;
else
  set(gca,'XTick',[]);
  set(gca,'YTick',[]);
end

% whitebg('black'); set(gcf,'color', [0 0 0]); %black background
% set(gcf,'menubar','none'); % no menu
