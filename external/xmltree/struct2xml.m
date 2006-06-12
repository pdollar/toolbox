function tree = struct2xml(s,rootname)
%STRUCT2XML Convert structure to an XML tree object and specify its root name
%   TREE = STRUCT2XML(S,ROOTNAME) converts the structure S into an XML
%   representation TREE (an XMLTree object) with ROOTNAME as the root tag, if
%   provided. Only conventional objects (char, double, sparse, *int*) are
%   accepted in S's fields.
%
%   Example
%      report = struct('name','John','marks',...
%                      struct('maths',17,'physics',12));
%      tree = struct2xml(report);
%      save(tree,'report.xml');
%
%   See also XMLTREE.

%   Copyright 2003 Guillaume Flandin. 
%   $Revision: 1.1 $  $Date: 2003/03/11 21:26: $

error(nargchk(1,2,nargin));
if ~isstruct(s)
	error('[STRUCT2XML] Input argument must be a struct.');
end
if nargin == 1,
	if ~isempty(inputname(1)),
		rootname=inputname(1);
	else
		rootname='root';
	end
end
% Create an empty XML tree
tree = xmltree;

% Root element is the input argument name
tree = set(tree,root(tree),'name',rootname);

% Recursively walk inside the structure
tree = sub_struct2xml(tree,s,root(tree));

%=======================================================================
function tree = sub_struct2xml(tree,s,uid)

	if isstruct(s)
		for k=1:length(s)
			names = fieldnames(s(k));
			for i=1:length(names)
				if iscell(getfield(s(k),names{i}))
					for j=1:length(getfield(s(k),names{i}))
						[tree, uid2] = add(tree,uid,'element',names{i});
						tree = sub_struct2xml(tree,getfield(s(k),names{i},{j}),uid2);
					end
				else
					[tree, uid2] = add(tree,uid,'element',names{i});
					tree = sub_struct2xml(tree,getfield(s(k),names{i}),uid2);
				end
			end
		end
	else
		switch class(s)
			case 'char'
				tree = add(tree,uid,'chardata',s); %need to handle char arrays...
			case 'cell'
				% if a cell is present here, it comes from: getfield(s(k),names{i},{j})
				tree = sub_struct2xml(tree,s{1},uid);
			case {'double','sparse'}
				tree = add(tree,uid,'chardata',sub_num2str(s));
			case {'int8','uint8','int16','uint16','int32','uint32'}
				% need a specific function because num2str only works with double
			otherwise
				error(sprintf('[STRUCT2XML] Cannot convert from %s to char.',class(s)));
		end
	end
	
%=======================================================================
function s = sub_num2str(n)  % to be improved for ND arrays (code from Ph. Ciuciu)
	[N,P] = size(n);

	if N>1 | P>1
		s=['['];
		w = ones(1,P);w(P)=0;
		v = ones(N,1);v(N)=0;
		for k=1:N
			for i=1:P
				s = [s num2str(n(k,i)) repmat(',',1,w(i))];
			end
			s = [s repmat(';',1,v(k))];
		end
		s = [s ']'];
	else
		s = num2str(n);
	end
