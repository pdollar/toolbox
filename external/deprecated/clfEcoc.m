function clf = clfEcoc(p,clfInit,clfparams,nclasses,use01targets)
% Wrapper for ecoc that makes ecoc compatible with nfoldxval.
%
% Requires the SVM toolbox by Anton Schwaighofer.
%
% USAGE
%  clf = clfEcoc(p,clfInit,clfparams,nclasses,use01targets)
%
% INPUTS
%  p               - data dimension
%  clfInit         - binary classifier init (see nfoldxval)
%  clfparams       - binary classifier parameters (see nfoldxval)
%  nclasses        - num of classes (currently 3<=nclasses<=7 suppored)
%  use01targets    - see ecoc
%
% OUTPUTS
%  clf             - see ecoc
%
% EXAMPLE
%
% See also ECOC, NFOLDXVAL, CLFECOCCODE
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

if( nclasses<3 || nclasses>7 )
  error( 'currently only works if 3<=nclasses<=7'); end;
if( nargin<5 || isempty(use01targets)); use01targets=0; end;

% create code (limited for now)
[C,nbits] = clfEcocCode( nclasses );
clf = ecoc(nclasses, nbits, C, use01targets  ); % didn't use to pass use01?
clf.verbosity = 0; % don't diplay output

% initialize and temporarily store binary learner
clf.templearner = feval( clfInit, p, clfparams{:} );

% ecoctrain2 is custom version of ecoctrain
clf.funTrain = @clfEcocTrain;
clf.funFwd = @ecocfwd;

function clf = clfEcocTrain( clf, varargin )

clf = ecoctrain( clf, clf.templearner, varargin{:} );
