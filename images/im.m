function varargout = im( I, range, extraInf )
% Function for displaying grayscale images.
%
% Handy function for showing a grayscale or color image with a colorbar.
%
% USAGE
%  h = im( I, [range], [extraInf] )
%
% INPUTS
%  I        - image in a valid format for imagesc
%  range    - [] minval/maxval for imagesc
%  extraInf - [1] if 1 then colorbar is shown as well as tick marks
%
% OUTPUTS
%  h        - handle for image graphics object
%
% EXAMPLE
%  load clown; im( X )
%
% See also imshow, imview, impixelinfo, imtool, imagesc
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.41
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]
if( nargin<1 || isempty(I)); I=0; end;
if( nargin<2 || isempty(range)), range=[]; end
if( nargin<3 || isempty(extraInf)); extraInf=1; end;
% display image using imagesc
if(isempty(range)), h=imagesc(I); else h=imagesc(I,range); end
% set basic and optional properties
colormap(gray); title(inputname(1)); axis('image');
if( extraInf ), colorbar; else set(gca,'XTick',[],'YTick',[]); end
% output h only if output argument explicitly requested
if(nargout>0), varargout={h}; end
end

% whitebg('black'); set(gcf,'color', [0 0 0]); %black background
% set(gcf,'menubar','none'); % no menu
