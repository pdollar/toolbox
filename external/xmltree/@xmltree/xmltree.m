function tree = xmltree(varargin)
% XMLTREE/XMLTREE Constructor of the XMLTree class
% FORMAT tree = xmltree(varargin)
% 
% filename - XML filename
% tree     - XMLTree Object
%
%     tree = xmltree;            % creates a minimal XML tree: <tag/>
%     tree = xmltree(filename);  % creates a tree from an XML file
%_______________________________________________________________________
%
% This is the constructor of the XMLTree class. 
% It creates a tree of an XML 1.0 file (after parsing) that is stored 
% using a Document Object Model (DOM) representation.
% See http://www.w3.org/TR/REC-xml for details about XML 1.0.
% See http://www.w3.org/DOM/ for details about DOM platform.
%_______________________________________________________________________
% @(#)xmltree.m                 Guillaume Flandin              02/03/27

switch(nargin)
	case 0
		tree.tree{1} = struct('type','element',...
		                      'name','tag',...
						      'attributes',[],...
						      'contents',[],...
							  'parent',[],...
						      'uid',1);
		tree.filename = '';
		tree = class(tree,'xmltree');
	case 1
		if isa(varargin{1},'xmltree')
			tree = varargin{1};
		elseif ischar(varargin{1})
			tree.tree = xml_parser(varargin{1});
			tree.filename = varargin{1};
			tree = class(tree,'xmltree');
		else 
			error('[XMLTree] Bad input argument');
		end
	otherwise
		error('[XMLTree] Bad number of arguments');
end
