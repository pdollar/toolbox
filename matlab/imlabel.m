% Improved method for labeling figure axes.
%
% INPUTS
%   labels          - cell array of strings, labels for display
%   position        - 'left', 'right', 'bottom', or 'top'
%   slant           - [optional] rotation for top and bottom labels in [-90,90]
%   pvpairs         - [optional] parameter / value list for text
%
% EXAMPLE
%   load( 'images.mat' );
%   clf; cla; montage2( images(:,:,1:9), 1 );
%   imlabel( {'row1','row2','row3'}, 'left',[],{'FontSize',20} );
%   imlabel( {'column 1','column 2','column 3'}, 'bottom', -25, {'FontSize',20} );
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also MONTAGE2, TEXT2, TEXT

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function imlabel( labels, position, slant, pvpairs )
    if( nargin<3 || isempty(slant) ) slant=0; end;
    if( nargin<4 || isempty(pvpairs) ) pvpairs={}; end;
    if( abs(slant)>90 ) error( 'slant must be between -90 and 90'); end;
    
    %%% set up for ydir reversed, xdir normal :)
    ys = ylim; nys=ys(2)-ys(1);  
    xs = xlim; nxs=xs(2)-xs(1);  
    if(strcmp(get(gca,'YDir'),'reverse')) ys=ys([2 1]); nys=-nys; end;
    if(strcmp(get(gca,'XDir'),'reverse')) xs=xs([2 1]); nxs=-nxs; end

    %%% write labels
    nlabels = length( labels );
    switch position
        case 'bottom' 
            set(gca,'XTick',[]); %tick interfere
            if(abs(slant)<=15) 
                H='center'; V='top'; 
            elseif( slant>15 && slant<50 )
                H='right'; V='top';
            elseif( slant>=50 )
                H='right'; V='middle'; 
            elseif( slant<-15 && slant>-50 )
                H='left'; V='top';
            elseif( slant<=-50 )
                H='left'; V='middle'; 
            end;
            textalign = {'VerticalAlignment',V,'HorizontalAlignment',H,'Rotation',slant};
            yloc = ys(1);
            for i=1:nlabels
                xloc = xs(1) + (2*i-1)/(2*nlabels)*nxs;
                text2( xloc,yloc,labels{i},textalign{:},pvpairs{:}); 
            end;
                        
        case 'top'
            title(''); %title interfere
            if(abs(slant)<=15) 
                H='center'; V='bottom'; 
            elseif( slant>15 && slant<50 )
                H='left'; V='bottom';
            elseif( slant>=50 )
                H='left'; V='middle'; 
            elseif( slant<-15 && slant>-50 )
                H='right'; V='bottom';
            elseif( slant<=-50 )
                H='right'; V='middle'; 
            end;       
            textalign = {'VerticalAlignment',V,'HorizontalAlignment',H,'Rotation',slant};
            textalign = {textalign{:}, 'Rotation',slant}; %rotate
            yloc = ys(2) + nys/40;
            for i=1:nlabels
                xloc = xs(1) + (2*i-1)/(2*nlabels)*nxs;
                text2( xloc,yloc,labels{i},textalign{:},pvpairs{:}); 
            end;
                        
        case 'left'
            set(gca,'YTick',[]); %tick interfere
            textalign = {'VerticalAlignment','middle','HorizontalAlignment','right'};
            xloc = xs(1) - nxs/20;
            for i=1:nlabels
                yloc = ys(2) - (2*i-1)/(2*nlabels)*nys;
                text2( xloc,yloc,labels{i},textalign{:},pvpairs{:}); 
            end;            
            
        case 'right'
            colorbar off; % colorbar interference
            textalign = {'VerticalAlignment','middle','HorizontalAlignment','left'};
            xloc = xs(2) + nxs/20;
            for i=1:nlabels
                yloc = ys(2) - (2*i-1)/(2*nlabels)*nys;
                text2( xloc,yloc,labels{i},textalign{:},pvpairs{:}); 
            end;            
            
        otherwise
            error(['illegal position: ' position]);
    end    
    
