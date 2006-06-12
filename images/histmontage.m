% Used to display multiple 1D histograms.
%
% INPUTS
%   HS  - nhist x nbins array where HS(i,j) is the jth bin in the ith histogram
%   mm  - [optional] #images/row (if [] then calculated based on nn)
%   nn  - [optional] #images/col(if [] then calculated based on mm)
%
% EXAMPLE
%   h = histc_1D( randn(2000,1), 20 );
%   histmontage([h; h]);
%
% DATESTAMP
%   29-Sep-2005  2:00pm
% 
% See also HISTC, HISTC_1D, FILTER_GAUSS_1D

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function histmontage( HS, mm, nn )
    [nhist, nbins] = size(HS);
    if( nhist>100 || nhist*nbins>10000 ) 
        error('Too much histogram data to display!');  end;

    %%% get layout of images (mm=#images/row, nn=#images/col)
    if (nargin<3 || isempty(mm) || isempty(nn))
        if (nargin==1 || (nargin==2 && isempty(mm)) || (nargin==3 && isempty(mm) && isempty(nn)) )
            nn = round(sqrt(nhist));
            mm = ceil( nhist / nn );
        elseif (isempty(mm))
            mm = ceil( nhist / nn );
        else
            nn = ceil( nhist / mm );
        end;    
    end;
        
    %%% plot each histogram
    clf; 
    for q=1:nhist
        if( nhist>1 ) subplot( mm, nn, q ); end;
        bar( HS(q,:), 1 ); shading('flat'); 
        ylim( [0,1] );   set( gca, 'YTick', [] );
        xlim( [.5, nbins+.5] );  set( gca, 'XTick', [] );
    end;
