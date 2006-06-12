function child = children(tree,uid)
% XMLTREE/CHILDREN Return children's UIDs of node uid
% FORMAT child = children(tree,uid)
%
% tree   - a tree
% uid    - uid of the element
% child  - array of the UIDs of children of node uid
%_______________________________________________________________________
%
% Return UID's of children of node uid
%_______________________________________________________________________
% @(#)children.m              Guillaume Flandin                02/04/09

error(nargchk(2,2,nargin));

child = [];
uid = uid(:);
l = length(tree);
for i=1:length(uid)
	if uid(i) > 0 & uid(i) <= l
		if strcmp(tree.tree{uid(i)}.type,'element')
			child = [child tree.tree{uid(i)}.contents];
		end
	else
		error('[XMLTree] Invalid UID.');
	end
end
if isempty(child), child = []; end
