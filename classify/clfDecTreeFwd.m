function Y = clfDecTreeFwd( clf, X )
% Apply the decision tree to data X.
%
% USAGE
%  Y = clfDecTreeFwd( clf, X )
%
% INPUTS
%  clf     - trained model
%  X       - nxp data array
%
% OUTPUTS
%  Y       - nx1 vector of labels predicted according to the clf
%
% EXAMPLE
%
% See also CLFDECTREE
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

if(~strcmp(clf.type,'dectree')); error( ['incor. type: ' clf.type] ); end;
if( size(X,2)~= clf.p ); error( 'Incorrect data dimension' ); end;
T = clf.T;

[Y,d,cnames] = treeval( T, X );
Y = str2double( cnames ); % convert Y back to an int format
