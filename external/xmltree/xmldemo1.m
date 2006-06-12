%XMLDEMO1 Demonstrate how to create an XML tree and save it
%
%   Description
%   This script demonstrates the use of the xmltree class to
%   create an XML tree from scratch and save it in a file.

%   Copyright (C) 2003  Guillaume Flandin

%   Please note that this script is only a demonstration of how
%   to use xmltree, set, add, view and save methods.
%   Indeed in this example, the use of the struct2xml function
%   would have been much more efficient:
%     entry = struct(...); % cf line 51
%     addressBook = struct('entry',entry);
%     tree = struct2xml(addressBook);

clc;
disp('This demonstration illustrates the use of the xmltree class.')
disp(' ')
disp('Let''s build an address book in XML.')
disp(' ')
disp('Press any key to create an empty tree.')
disp(' ')
pause;

disp('>> tree = xmltree;');
tree = xmltree;

% Modify the root element
disp(' ')
disp('Modify the root element.')
disp(' ')
disp('Press any key to continue.')
disp(' ')
pause;

disp('>> tree = set(tree,root(tree),''name'',''addressBook'');');
tree = set(tree,root(tree),'name','addressBook');

% Create a new entry in the address book
disp(' ')
disp('Create a new entry.')
disp(' ')
disp('Press any key to continue.')
disp(' ')
pause;

disp('>> tree = add(tree,root(tree),''comment'',''This is the first entry of our Address Book'');');
disp('>> [tree, entry_uid] = add(tree,root(tree),''element'',''entry'');');
disp('>> tree = attributes(tree,''add'',entry_uid,''lastModified'',datestr(datenum(date),''dd-mmm-yyyy''));');
tree = add(tree,root(tree),'comment','This is the first entry of our Address Book');
[tree, entry_uid] = add(tree,root(tree),'element','entry');
tree = attributes(tree,'add',entry_uid,'lastModified',datestr(datenum(date),'dd-mmm-yyyy'));

% Here are the data for the new entry
entry = struct('firstName','Guillaume',...
               'lastName','Flandin',...
			   'address',struct('institute','INRIA Sophia Antipolis',...
			                    'street','2004 Route des Lucioles',...
								'zipCode','06902',...
								'city','Sophia Antipolis',...
								'country','France'),...
			   'phone','(+33) 4 92 38 71 52',...
			   'email','Guillaume.Flandin@sophia.inria.fr');

% Fill in the fields with data
disp(' ')
disp('Create and fill in the fields with data.')
disp(' ')
disp('Press any key to continue.')
pause;
entry

% Create the 'firstName' tag
[tree, uid] = add(tree,entry_uid,'element','firstName');
tree = add(tree,uid,'chardata',entry.firstName);

% Create the 'lastName' tag
[tree, uid] = add(tree,entry_uid,'element','lastName');
tree = add(tree,uid,'chardata',entry.lastName);

% Create the 'address' tag
[tree, address_uid] = add(tree,entry_uid,'element','address');

	[tree, uid] = add(tree,address_uid,'element','institute');
	tree = add(tree,uid,'chardata',entry.address.institute);

	[tree, uid] = add(tree,address_uid,'element','street');
	tree = add(tree,uid,'chardata',entry.address.street);

	[tree, uid] = add(tree,address_uid,'element','zipCode');
	tree = add(tree,uid,'chardata',entry.address.zipCode);

	[tree, uid] = add(tree,address_uid,'element','city');
	tree = add(tree,uid,'chardata',entry.address.city);

	[tree, uid] = add(tree,address_uid,'element','country');
	tree = add(tree,uid,'chardata',entry.address.country);

% Create the 'phone' tag
[tree, uid] = add(tree,entry_uid,'element','phone');
tree = add(tree,uid,'chardata',entry.phone);

% Create the 'email' tag
[tree, uid] = add(tree,entry_uid,'element','email');
tree = add(tree,uid,'chardata',entry.email);

% Graphical display and save
disp('Graphical display.')
disp(' ')
disp('Press any key to display the xmltree.')
disp(' ')
pause;

disp('>> view(tree);')
view(tree);

disp(' ')
disp('Press any key to save the xmltree in example.xml.')
disp(' ')
pause;

disp('>> save(tree,''example.xml'');')
save(tree,'example.xml');
disp(['Saved in:' fullfile(pwd,'example.xml')]);

disp(' ');
disp('Press any key to end.')
pause; clc; close all;
