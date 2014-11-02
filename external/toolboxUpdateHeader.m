function toolboxUpdateHeader
% Update the headers of all the files.
%
% USAGE
%  toolboxUpdateHeader
%
% INPUTS
%
% OUTPUTS
%
% EXAMPLE
%
% See also
%
% Piotr's Computer Vision Matlab Toolbox      Version 3.40
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

header={
  'Piotr''s Computer Vision Matlab Toolbox      Version 3.40'; ...
  'Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]'; ...
  'Licensed under the Simplified BSD License [see external/bsd.txt]'};

root=fileparts(fileparts(mfilename('fullpath')));
ds=dir(root); ds=ds([ds.isdir]); ds={ds.name};
ds=ds(3:end); ds=setdiff(ds,{'.git','doc'});
subds = { '/', '/private/' };
exts = {'m','c','cpp','h','hpp'};
omit = {'Contents.m','fibheap.h','fibheap.cpp'};

for i=1:length(ds)
  for j=1:length(subds)
    for k=1:length(exts)
      d=[root '/' ds{i} subds{j}];
      if(k==1), comment='%'; else comment='*'; end
      fs=dir([d '*.' exts{k}]); fs={fs.name}; fs=setdiff(fs,omit);
      n=length(fs); for f=1:n, fs{f}=[d fs{f}]; end
      for f=1:n, toolboxUpdateHeader1(fs{f},header,comment); end
    end
  end
end

end

function toolboxUpdateHeader1( fName, header, comment )

% set appropriate comment symbol in header
m=length(header); for i=1:m, header{i}=[comment ' ' header{i}]; end

% read in file and find header
disp(fName); lines=readFile(fName);
loc = find(not(cellfun('isempty',strfind(lines,header{1}(1:40)))));
if(isempty(loc)), error('NO HEADER: %s\n',fName); end; loc=loc(1);

% check that header is properly formed, return if up to date
for i=1:m; assert(isequal(lines{loc+i-1}(1:10),header{i}(1:10))); end
if(~any(strfind(lines{loc},'NEW'))); return; end

% update copyright year and overwrite rest of header
lines{loc+1}(13:16)=header{2}(13:16);
for i=[1 3:m]; lines{loc+i-1}=header{i}; end
writeFile( fName, lines );

end

function lines = readFile( fName )
fid = fopen( fName, 'rt' ); assert(fid~=-1);
lines=cell(10000,1); n=0;
while( 1 )
  n=n+1; lines{n}=fgetl(fid);
  if( ~ischar(lines{n}) ), break; end
end
fclose(fid); n=n-1; lines=lines(1:n);
end

function writeFile( fName, lines )
fid = fopen( fName, 'w' );
for i=1:length(lines); fprintf( fid, '%s\n', lines{i} ); end
fclose(fid);
end
