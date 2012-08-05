function imLabel( labels, position, S, pvPairs )
% Improved method for labeling figure axes.
%
% USAGE
%  imLabel( labels, position, [S], [pvPairs] )
%
% INPUTS
%  labels          - cell array of strings, labels for display
%  position        - 'left', 'right', 'bottom', or 'top'
%  S               - [] rotation for top and bottom labels in [-90,90]
%  pvPairs         - [] parameter / value list for text
%
% OUTPUTS
%
% EXAMPLE
%  load( 'images.mat' ); clf; cla; montage2( images(:,:,1:9) );
%  imLabel( {'row1','row2','row3'}, 'left',[],{'FontSize',20} );
%  imLabel( {'col1','col2','col3'}, 'bottom', -25, {'FontSize',20} );
%
% See also MONTAGE2, TEXT2, TEXT
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<3 || isempty(S) ); S=0; end
if( nargin<4 || isempty(pvPairs) ); pvPairs={}; end
if( abs(S)>90 ); error( 'slant must be between -90 and 90'); end

%%% set up for ydir reversed, xdir normal :)
ys = ylim; nys=ys(2)-ys(1);
xs = xlim; nxs=xs(2)-xs(1);
if(strcmp(get(gca,'YDir'),'reverse')); ys=ys([2 1]); nys=-nys; end
if(strcmp(get(gca,'XDir'),'reverse')); xs=xs([2 1]); nxs=-nxs; end

%%% write labels
nlabels = length( labels );
switch position
  case 'bottom'
    set(gca,'XTick',[]); %tick interfere
    if(abs(S)<=15)
      H='center'; V='top';
    elseif( S>15 && S<50 )
      H='right'; V='top';
    elseif( S>=50 )
      H='right'; V='middle';
    elseif( S<-15 && S>-50 )
      H='left'; V='top';
    elseif( S<=-50 )
      H='left'; V='middle';
    end;
    txtAlign ={'VerticalAlignment',V,'HorizontalAlignment',H,'Rotation',S};
    yloc = ys(1);
    for i=1:nlabels
      xloc = xs(1) + (2*i-1)/(2*nlabels)*nxs;
      text2( xloc,yloc,labels{i},txtAlign{:},pvPairs{:});
    end;
    
  case 'top'
    title(''); %title interfere
    if(abs(S)<=15)
      H='center'; V='bottom';
    elseif( S>15 && S<50 )
      H='left'; V='bottom';
    elseif( S>=50 )
      H='left'; V='middle';
    elseif( S<-15 && S>-50 )
      H='right'; V='bottom';
    elseif( S<=-50 )
      H='right'; V='middle';
    end;
    txtAlign ={'VerticalAlignment',V,'HorizontalAlignment',H,'Rotation',S};
    txtAlign = [txtAlign, {'Rotation',S}]; %rotate
    yloc = ys(2) + nys/40;
    for i=1:nlabels
      xloc = xs(1) + (2*i-1)/(2*nlabels)*nxs;
      text2( xloc,yloc,labels{i},txtAlign{:},pvPairs{:});
    end;
    
  case 'left'
    set(gca,'YTick',[]); %ticks interfere
    txtAlign ={'VerticalAlignment','middle','HorizontalAlignment','right'};
    xloc = xs(1) - nxs/20;
    for i=1:nlabels
      yloc = ys(2) - (2*i-1)/(2*nlabels)*nys;
      text2( xloc,yloc,labels{i},txtAlign{:},pvPairs{:});
    end;
    
  case 'right'
    colorbar off; % colorbar interferes
    txtAlign = {'VerticalAlignment','middle','HorizontalAlignment','left'};
    xloc = xs(2) + nxs/20;
    for i=1:nlabels
      yloc = ys(2) - (2*i-1)/(2*nlabels)*nys;
      text2( xloc,yloc,labels{i},txtAlign{:},pvPairs{:});
    end;
    
  otherwise
    error(['illegal position: ' position]);
end
