% Used to apply the same operation to all .mat files in given directory.
%
% For each mat in srcdir, loads the mat file, extracts the variables denoted by
% matcontents, applies the function fhandle and stores the result.  matcontents must be a
% cell array of strings, where each string denotes the variable stored in the mat files.
% For example, if each mat file contains two variables y and z, then matcontents should be
% {'y','z'}.  For long operations shows progress information.
%
% fhandle must point to a function that takes two inputs: vals and params.
% vals is a cell array that contains the values for the variables denoted by matcontents
% and contained in the mat file, and params are the additional static parameters passed to
% feval_arrays.  Continuing the example above vals would be {y,z} - (use deal to extract):
%    x=feval(fhandle,{y,z},params) 
% Each returned x must have the same dimensions, X is a concatentation of the returned x's
% along the (d+1) dimension.  
%
% INPUTS
%   fhandle     - function to apply to contents of each mat file [see above]
%   matcontents - cell array of strings that denote expected contents of each mat file
%   params      - cell array of additional parameters to fhandle (may be {})
%   srcdir      - directory containg mat files
%   prefix      - [optional] only consider mat files in srcdir of the form prefix_*.mat
%
% OUTPUTS
%   X        - output array [see above]
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also FEVAL_IMAGES, FEVAL_ARRAYS

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function X = feval_mats( fhandle, matcontents, params, srcdir, prefix )
    error(nargchk( 4, 5, nargin ));
    
    %%% Check if srcdir is valid and add '/' at end if needed
    if( ~isempty(srcdir) )
        if(~exist(srcdir,'dir')) error( ['feval_mats: dir ' srcdir ' not found' ] ); end;
        if( srcdir(end)~='\' && srcdir(end)~='/' ) srcdir(end+1) = '/'; end;
    end

    
    %%% get appropriate filenames
    if( nargin<=4 || isempty(prefix) ) 
        dircontent = dir( [srcdir '*.mat'] ); 
    else
        dircontent = dir( [srcdir prefix '_*.mat'] ); 
    end
    filenames = {dircontent.name}; n = length(dircontent);        
    if( n==0 ) error( ['No appropriate mat files found in ' srcdir] ); end;
    

    %%% load each mat file and apply fhandle
    ticstatusid = ticstatus('feval_mats',[],40);
    ncontents = length( matcontents );
    for i=1:n
        % load mat file and get contents
        S = load( [srcdir filenames{i}] ); 
        errmsg = ['Unexpected contents for mat file: ' filenames{i}];
        if( length(fieldnames(S))<ncontents) error( errmsg ); end;
        inputs = cell(1,ncontents);
        for j=1:ncontents
            if( ~isfield(S,matcontents{j}) ) error( errmsg ); end;
            inputs{j} = getfield(S,matcontents{j});
        end; clear S;
        
        % apply fhandle
        x = feval( fhandle, inputs, params );
        if (i==1) 
            ndx = ndims(x); 
            if(ndx==2 && size(x,2)==1) ndx=1; end;
            ones_ndx = ones(1,ndx);
            X = repmat( x, [ones_ndx,n] ); 
            indsX = {':'}; indsX = indsX(ones_ndx);
        else 
            X(indsX{:},i) = x;
        end;
        tocstatus( ticstatusid, i/n );
    end;
    
