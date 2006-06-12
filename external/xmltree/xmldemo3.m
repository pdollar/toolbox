%XMLDEMO3 Demonstrate how to convert an XMLtree in a simple structure
%
%   Description
%   This script demonstrates the use of the xmltree class to
%   convert an XMLtree (when possible) in a simple structure.
%   This can only be performed when the XML file is simple enough
%   (one element cannot have more than one chardata child). 

%   Copyright (C) 2003  Guillaume Flandin

clc;
disp('This demonstration illustrates the use of the xmltree class')
disp('to convert an xmltree in a simple Matlab structure.')
disp(' ')
disp('Press any key to open the XML file ''example.xml''.')
pause;

disp('>> t = xmltree(''example.xml'')')
try,
	t = xmltree('example.xml');
catch,
	disp('Please first launch xmldemo1')
end

disp(' ')
disp('Press any key to display the XML file.')
pause;

save(t);

disp(' ')
disp('Convert the xmltree in a Matlab structure.')
disp(' ')
disp('Press any key to continue.')
disp(' ')
pause; clc;

disp('>> s = convert(tree);')
s = convert(t);

disp(' ')
disp('Display the content of the structure.')
disp(' ')
disp('Press any key to continue.')
disp(' ')
pause;

disp('>> s.entry');
s.entry
disp('>> s.entry.address');
s.entry.address
disp('>> s.entry.address.institute');
s.entry.address.institute

disp(' ');
disp('Press any key to end.')
pause; clc; close all;
