function masks = txt2img( strings, h, txtPrp )
% Convert text string to a binary image.
%
% For each input string, creates a binary matrix of dimensions [hxw] that
% when displayed as an image shows the string. See example for usage.
% First, uses text() to display the text using Matlab's display
% functionality. Next uses getframe() to capture the screen and crops the
% resulting image appropriately.
%
% USAGE
%  masks = txt2img( strings, h, [txtPrp] )
%
% INPUTS
%  strings  - {1xn} text string or cell array of text strings to convert
%  h        - font height in pixels
%  txtPrp   - [] additional properites for call to "text"
%
% OUTPUTS
%  masks    - {1xn} binary image masks of height h for each string
%
% EXAMPLE
%  masks=txt2img('hello world',100); im(masks{1})
%
% See also CHAR2IMG, GETFRAME, TEXT
%
% Piotr's Image&Video Toolbox      Version 2.35
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

% set up blank figure to which to write text
if(nargin<3 || isempty(txtPrp)), txtPrp={}; end
txtPrp = [txtPrp 'units','pixels', 'position',[2 2], 'FontUnits', ...
  'pixels', 'fontsize',h-2, 'VerticalAlignment','Bottom', 'string'];
ss=get(0,'ScreenSize'); w=ss(3)-250;
hf=figure; clf; imshow(ones([h-1 w]));
% write each string and use screen capture to save image
if(~iscell(strings)), strings={strings}; end
n=length(strings); masks=cell(1,n);
for s=1:n
  ht=text(txtPrp{:},strings{s}); pos=get(ht,'Extent');
  if(pos(3)>w), error('string does not fit on screen'); end
  M=getframe(gca); M=M.cdata; M=M(:,1:pos(3),1); M=uint8(M>100);
  k=find(sum(M==0)>0); if(k), M=M(:,max(1,k(1)-1):min(end,k(end)+1)); end
  masks{s}=M; delete(ht);
end; close(hf);
end
