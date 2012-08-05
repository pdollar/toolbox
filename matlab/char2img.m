function masks = char2img( strings, h, pad )
% Convert ascii text to a binary image using pre-computed templates.
%
% Input strings can only contain standard characters (ascii character
% 32-126). First time char2img() is ever called with a given height h,
% txt2img() is used to create a template for each ascii character. All
% subsequent calls to to char2img() with the given height are very fast as
% the pre-computed templates are used and no display/screen capture is
% needed.
%
% USAGE
%  masks = char2img( strings, h, [pad] )
%
% INPUTS
%  strings  - {1xn} text string or cell array of text strings to convert
%  h        - font height in pixels
%  pad      - [0] amount of extra padding between chars
%
% OUTPUTS
%  masks    - {1xn} binary image masks of height h for each string
%
% EXAMPLE
%  mask=char2img('hello world',50); im(mask{1})
%  mask=char2img(num2str(pi),35); im(mask{1})
%
% See also TXT2IMG
%
% Piotr's Image&Video Toolbox      Version 2.65
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

% load or create character templates (or simply store persistently)
persistent chars h0
if(isempty(h0) || h0~=h)
  pth=fileparts(mfilename('fullpath'));
  fName=sprintf('%s/private/char2img_h%03i.mat',pth,h); h0=h;
  if(exist(fName,'file')), load(fName); else
    chars=char(32:126); chars=num2cell(chars);
    chars=txt2img(chars,h,{'Interpreter','none'});
    save(fName,'chars');
  end
end
% add padding to chars
if(nargin<3 || isempty(pad)), pad=0; end
charsPad=chars; if(pad), pad=ones(h,pad,'uint8');
  for i=1:length(chars), charsPad{i}=[pad chars{i} pad]; end; end
% create actual string using templates
if(~iscell(strings)), strings={strings}; end
n=length(strings); masks=cell(1,n);
for s=1:n, str=strings{s};
  str(str<32 | str>126)=32; str=uint8(str-31);
  M=[charsPad{str}]; masks{s}=M;
end
