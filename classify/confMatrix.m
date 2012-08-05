function CM = confMatrix( IDXtrue, IDXpred, ntypes )
% Generates a confusion matrix according to true and predicted data labels.
%
% CM(i,j) denotes the number of elements of class i that were given label
% j.  In other words, each row i contains the predictions for elements whos
% actual class was i.  If IDXpred is perfect, then CM is a diagonal matrix
% with CM(i,i) equal to the number of instances of class i.
%
% To normalize CM to [0,1], divide each row by sum of that row:
%  CMnorm = CM ./ repmat( sum(CM,2), [1 size(CM,2)] );
%
% USAGE
%  CM = confMatrix( IDXtrue, IDXpred, ntypes )
%
% INPUTS
%  IDXtrue     - [nx1] array of true labels [int values in 1-ntypes]
%  IDXpred     - [nx1] array of predicted labels [int values in 1-ntypes]
%  ntypes      - maximum number of types (should be > max(IDX))
%
% OUTPUTS
%  CM          - ntypes x ntypes confusion array with integer values
%
% EXAMPLE
%  IDXtrue = [ones(1,25) ones(1,25)*2];
%  IDXpred = [ones(1,10) randint2(1,30,[1 2]) ones(1,10)*2];
%  CM = confMatrix( IDXtrue, IDXpred, 2 )
%  confMatrixShow( CM, {'class-A','class-B'}, {'FontSize',20} )
%
% See also CONFMATRIXSHOW
%
% Piotr's Image&Video Toolbox      Version 2.12
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

IDXtrue=IDXtrue(:); IDXpred=IDXpred(:);

%%% convert common binary labels [-1/+1] or [0/1] to [1/2]
if( ntypes==2 )
  IDX = [IDXtrue;IDXpred];
  if( min(IDX)>=-1 && max(IDX)<=1 && all(IDX~=0))
    IDXtrue=IDXtrue+2;  IDXpred=IDXpred+2;
    IDXtrue(IDXtrue==3) = 2;  IDXpred(IDXpred==3) = 2;
  elseif( min(IDX)>=0 && max(IDX)<=1 )
    IDXtrue=IDXtrue+1;  IDXpred=IDXpred+1;
  end
end

%%% error check
[IDXtrue,er] = checkNumArgs( IDXtrue, [], 0, 2 ); error(er);
[IDXpred,er] = checkNumArgs( IDXpred, [], 0, 2 ); error(er);
if( length(IDXtrue)~=length(IDXpred) )
  error('Lengths of IDXs must match up.'); end
if( max([IDXtrue;IDXpred])>ntypes )
  error(['ntypes = ' int2str(ntypes) ' not large enough']); end

%%% generate CM
CM = zeros(ntypes);
for i=1:ntypes
  vals = IDXpred( IDXtrue==i );
  for j=1:ntypes; CM(i,j) = sum(vals==j); end
end
