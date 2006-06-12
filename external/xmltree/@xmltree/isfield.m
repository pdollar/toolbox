function F = isfield(tree,uid,parameter)
% XMLTREE/ISFIELD Is parameter a field of tree{uid} ?
% FORMAT F = isfield(tree,uid,parameter)
%
% tree      - a tree
% uid       - uid of the element
% parameter - a field of the root tree
% F         - 1 if present, 0 otherwise
%_______________________________________________________________________
%
% Is parameter a field of tree{uid} ?
%_______________________________________________________________________
% @(#)isfield.m               Guillaume Flandin                01/10/31

error(nargchk(3,3,nargin));

F = zeros(1,length(uid));
for i=1:length(uid)
	if isfield(tree.tree{uid(i)},parameter)
		F(i) = 1;
	end
end
