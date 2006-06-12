function display(tree)
% XMLTREE/DISPLAY Command window display of an XMLTree
% FORMAT display(tree)
% 
% tree - XMLTree object
%_______________________________________________________________________
%
% This method is called when the semicolon is not used to terminate a
% statement which returns an XMLTree.
%_______________________________________________________________________
% @(#)display.m                  Guillaume Flandin             02/04/04

disp(' ');
disp([inputname(1),' = ']);
disp(' ');
for i=1:prod(size(tree))
	disp([blanks(length(inputname(1))+3) char(tree(i))]);
end
disp(' ');
