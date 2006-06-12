function s = char(tree)
% XMLTREE/CHAR Converter function from XMLTree to a description string
% FORMAT s = char(tree)
%
% tree - XMLTree object
% s    - a description string of an XMLTree
%_______________________________________________________________________
%
% Return a string describing the XMLTree:
%               'XMLTree object (x nodes) [filename]'
%_______________________________________________________________________
% @(#)char.m                   Guillaume Flandin               02/04/04

s = strcat('XMLTree object (',num2str(length(tree)),' nodes) [',getfilename(tree),']');
