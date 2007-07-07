% Utility to process parameter name/value pairs.
%
% DEPRECATED -- ONLY USED BY KMEANS2?  SHOULD BE REMOVED.
% USE GETPARAMDEFAULTS INSTEAD.
%
% Based on code fromt Matlab Statistics Toolobox's "private/statgetargs.m"
%
% [EMSG,A,B,...]=GETARGS(PNAMES,DFLTS,'NAME1',VAL1,'NAME2',VAL2,...)
% accepts a cell array PNAMES of valid parameter names, a cell array DFLTS
% of default values for the parameters named in PNAMES, and additional
% parameter name/value pairs.  Returns parameter values A,B,... in the same
% order as the names in PNAMES.  Outputs corresponding to entries in PNAMES
% that are not specified in the name/value pairs are set to the
% corresponding value from DFLTS.  If nargout is equal to length(PNAMES)+1,
% then unrecognized name/value pairs are an error.  If nargout is equal to
% length(PNAMES)+2, then all unrecognized name/value pairs are returned in
% a single cell array following any other outputs.
%
% EMSG is empty if the arguments are valid, or the text of an error message
% if an error occurs.  GETARGS does not actually throw any errors, but
% rather returns an error message so that the caller may throw the error.
% Outputs will be partially processed after an error occurs.
%
% USAGE
%  [emsg,varargout]=getargs(pnames,dflts,varargin)
%
% INPUTS
%  pnames     - cell of valid parameter names
%  dflts      - cell of default parameter values
%  varargin   - list of proposed name / value pairs
%
% OUTPUTS
%  emsg       - error msg - '' if no error
%  varargout  - list of assigned name / value pairs
%
% EXAMPLE
%  pnames = {'color' 'linestyle', 'linewidth'};  dflts  = { 'r','_','1'};
%  v = {'linew' 2 'nonesuch' [1 2 3] 'linestyle' ':'};
%  [emsg,color,linestyle,linewidth,unrec] = getargs(pnames,dflts,v{:}) % ok
%  [emsg,color,linestyle,linewidth] = getargs(pnames,dflts,v{:})    % err
%
% See also GETPARAMDEFAULTS

% Piotr's Image&Video Toolbox      Version 1.5
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function [emsg,varargout]=getargs(pnames,dflts,varargin)

wid = sprintf('Images:%s:obsoleteFunction',mfilename);
warning(wid,[ '%s is obsolete in Piotr''s toolbox.\n It will be ' ...
  'removed in the next version of the toolbox.'],upper(mfilename));

% We always create (nparams+1) outputs:
%    one for emsg
%    nparams varargs for values corresponding to names in pnames
% If they ask for one more (nargout == nparams+2), it's for unrecognized
% names/values
emsg = '';
nparams = length(pnames);
varargout = dflts;
unrecog = {};
nargs = length(varargin);

% Must have name/value pairs
if mod(nargs,2)~=0
  emsg = sprintf('Wrong number of arguments.');
else
  % Process name/value pairs
  for j=1:2:nargs
    pname = varargin{j};
    if ~ischar(pname)
      emsg = sprintf('Parameter name must be text.');
      break;
    end
    i = strmatch(lower(pname),lower(pnames));
    if isempty(i)
      % if they've asked to get back unrecognized names/values, add this
      % one to the list
      if nargout > nparams+1
        unrecog((end+1):(end+2)) = {varargin{j} varargin{j+1}};
        % otherwise, it's an error
      else
        emsg = sprintf('Invalid parameter name:  %s.',pname);
        break;
      end
    elseif length(i)>1
      emsg = sprintf('Ambiguous parameter name:  %s.',pname);
      break;
    else
      varargout{i} = varargin{j+1};
    end
  end
end
varargout{nparams+1} = unrecog;
