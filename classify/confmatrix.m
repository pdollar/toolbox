% Generates a confusion matrix according to true and predicted data labels.
%
% CM(i,j) denotes the number of elements of class i that were given label j.  In other
% words, each row i contains the predictions for elements whos actual class was i.  If
% IDXpred is perfect, then CM is a diagnol matrix with CM(i,i) equal to the number of
% instances of class i.  
%
% To normalize CM to fall between [0,1], divide each row by the sum of that row:
%   CMnorm = CM ./ repmat( sum(CM,2), [1 size(CM,2)] );
%
% INPUTS
%   IDXtrue     - nx1 array of true labels [int values between 1 and ntypes]
%   IDXpred     - nx1 array of predicted labels [int values between 1 and ntypes]
%   ntypes      - maximum number of types (should be > max(IDX))
%
% OUTPUTS
%   CM          - ntypes x ntypes confusion array with integer values
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also CONFMATRIX_SHOW

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function CM = confmatrix( IDXtrue, IDXpred, ntypes )

    %%% convert common binary labels [-1/+1] or [0/1] to [1/2]
    if( ntypes==2 )
        IDX = [IDXtrue;IDXpred];
        if( min(IDX)>=-1 && max(IDX)<=1 && all(IDX~=0))
            IDXtrue=IDXtrue+2;  IDXpred=IDXpred+2;
            IDXtrue(IDXtrue==3) = 2;  IDXpred(IDXpred==3) = 2;
        elseif( min(IDX)>=0 && max(IDX)<=1 )
            IDXtrue=IDXtrue+1;  IDXpred=IDXpred+1;
        end;
    end;

    %%% error check
    [IDXtrue,er] = checknumericargs( IDXtrue, [], 0, 2 ); error(er);
    [IDXpred,er] = checknumericargs( IDXpred, [], 0, 2 ); error(er);
    if( length(IDXtrue)~=length(IDXpred) )
        error('Lengths of IDXs must match up.'); end;
    if( max([IDXtrue;IDXpred])>ntypes )  
        error(['ntypes = ' int2str(ntypes) ' not large enough']); end;
    
    %%% generate CM
    CM = zeros(ntypes);
    for i=1:ntypes
        vals = IDXpred( IDXtrue==i );
        for j=1:ntypes CM(i,j) = sum(vals==j); end;
    end
