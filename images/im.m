%IM [2D] Function for displaying grayscale images.
%
% Handy function for showing a grayscale image with a colorbar and interactive pixel value
% tool.
%
% INPUTS
%   I       - image in a valid format
%   range   - [optional] minval/maxval for imagesc
%
% EXAMPLE
%   load clown
%   im( X )
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also IMSHOW, IMVIEW

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function im( I, range );
    if( nargin==1 || isempty(range)) 
        imagesc(I);
    else
        imagesc(I,range)
    end

    pixval on; % info about image pixels
    title(inputname(1)); % title according to name of input arg
    colormap(gray); % black/white image
    colorbar; % appends a colorbar 
    axis('image'); % used for images
    % whitebg('black'); set(gcf,'color', [0 0 0]); %black background:
    % set(gcf,'menubar','none'); % no menu

