function p = parent(tree,uid)
% XMLTREE/PARENT Parent Method
% FORMAT uid = parent(tree,uid)
% 
% tree   - XMLTree object
% uid    - UID of the lonely child
% p      - UID of the parent ([] if root is the child)
%_______________________________________________________________________
%
% Return the uid of the parent of a node.
%_______________________________________________________________________
% @(#)parent.m                  Guillaume Flandin              02/04/08

p = tree.tree{uid}.parent;
