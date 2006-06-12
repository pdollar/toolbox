% Used to display a confusion matrix.  
%
% See confmatrix for general format and info on confusion matricies.  This function
% normalizes the CM before displaying (hence all values range in [0,1] and rows sum to 1. 
%
% INPUTS
%   CM          - ntypes x ntypes confusion array -- see confusmatrix
%   types       - [optional] cell array of length ntypes of text labels for each type 
%   pvpairs     - [optional] parameter / value list for text.m
%   ndigits     - [optional] number of digits after decimal to display
%
% OUTPUTS
%   NONE
%
% EXAMPLE
%   cliptypes = { 'anger','disgust','fear','joy','sadness','surprise' };
%   confmatrix_show( rand(6)/3+eye(6), cliptypes, {'FontSize',20} )
%   title('confusion matrix','FontSize',24);
%
% DATESTAMP
%   07-Oct-2005  5:00pm
%
% See also CONFMATRIX, TEXT2

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function confmatrix_show( CM, types, pvpairs, ndigits )
    if( nargin<2 ) types=[]; end;
    if( nargin<3 || isempty(pvpairs)) pvpairs = {'FontSize',20}; end;
    if( nargin<4 || isempty(ndigits)) ndigits=2; end;
    if( ndigits<1 || ndigits>10 ) error('too few or too many digits'); end;
    if( any(CM)<0 ) error( 'CM must have non-negative entries' ); end;
        
    %%% normalize and convert to integer matrix
    CM = CM ./ repmat( sum(CM,2), [1 size(CM,2)] );
    CM = round(CM*10^ndigits);
    
    %%% display as image
    clf; h=imagesc(10^ndigits-CM,[0,10^ndigits]); 
    colormap gray; axis square;
    set(gca,'XTick',[]); set(gca,'YTick',[]); 
    
    %%% now write text of actual confusion value
    ntypes = size(CM,1);
    textalign = { 'VerticalAlignment','middle', 'HorizontalAlignment','center' };
    for i=1:ntypes
        for j=1:ntypes 
            if( CM(i,j)>10^ndigits/2 ) color = 'w'; else color = 'k'; end;
            if( CM(i,j)==10^ndigits ) 
                label = ['1.' repmat('0',[1 ndigits-1]) ];
            else
                label = ['.' int2str2( CM(i,j),ndigits) ]; 
            end
            text(j,i,label,'color',color,textalign{:},pvpairs{:});
        end;
    end
    
    %%% now add type labels
    if( ~isempty(types) )
        imlabel( types, 'left', 0, pvpairs );
        imlabel( types, 'bottom', -35, pvpairs );
    end;
    
    
    
    
    
