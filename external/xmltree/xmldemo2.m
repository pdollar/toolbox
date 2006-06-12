%XMLDEMO2 Demonstrate how to read an XML file, modify it and save it
%
%   Description
%   This script demonstrates the use of the xmltree class to
%   open an XML file, access data stored in it, modify a value
%   and save the new XML file.
%
%   This demonstration script need the file 'example.xml' created
%   in the first demonstration script xmldemo1.

%   Copyright (C) 2003  Guillaume Flandin

clc;
disp('This demonstration illustrates the use of the xmltree class.')
disp(' ')
disp('Let''s open the address book previously created and modify an entry.')
disp(' ')
disp('Press any key to open the XML file ''example.xml''.')
disp(' ')
pause;

disp('>> t = xmltree(''example.xml'')')
try,
	t = xmltree('example.xml')
catch,
	disp('Please first launch xmldemo1')
end

disp(' ')
disp('Now you have several methods implemented to deal with the xmltree object:')
methods xmltree

disp('Press any key to continue.')
pause; clc;

% Extract the first name
disp('Extract the first name.')
disp(' ')
disp('Press any key to continue.')
disp(' ')
pause;

disp('>> first_name = children(t,find(t,''/addressBook/entry[1]/firstName''))')
disp('>> get(t,first_name,''value'')')
firstname_tag = find(t,'/addressBook/entry[1]/firstName');
first_name = children(t,firstname_tag);
get(t,first_name,'value')

% Modify the first name
disp('Modify the first name.')
disp(' ')
disp('Press any key to continue.')
disp(' ')
pause;

disp('t = set(t,first_name,''value'',''Joe'');')
t = set(t,first_name,'value','Joe');

% Modify the last name
disp(' ')
disp('Modify the last name.')
disp(' ')
disp('Press any key to modify the last name.')
disp(' ')
pause;

disp('>> t = set(t,children(t,find(t,''//lastName'')),''value'',''Bloggs'');')
t = set(t,children(t,find(t,'//lastName')),'value','Bloggs');

% Save the modified XML file
disp(' ')
disp('Press any key to save the xmltree in example2.xml.')
disp(' ')
pause;

disp('>> save(t,''example2.xml'');')
save(t,'example2.xml');
disp(['Saved in:' fullfile(pwd,'example2.xml')]);

disp(' ');
disp('Press any key to end.')
pause; clc; close all;
