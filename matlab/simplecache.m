% A very simply cache that can be used to store results of computations.  
%
% Can save and retrieve arbitrary values using a vector (includnig char vectors) as a key.
% Especially useful if a function must perform heavy computation but is often called with
% the same inputs (for which it will give the same outputs).  Note that the current
% implementation does a linear search for the key (a more refined implementation would use
% a hash table), so it is not meant for large scale usage.
%
% To use inside a function, make the cache persistent: 
%   persistent cache; if( isempty(cache) ) cache=simplecache('init'); end;
% The following line, when placed inside a function, means the cache will stay in memory
% until the matlab environment changes.  For an example usage see mask_gaussians.
%
% USAGE:
%   %%% initialize a cache:
%   cache = simplecache('init');   
%
%   %%% put something in a cache.  Note that key must be a numeric vector.
%   %%% if cache already contained an object with the same key that obj is overwritten.
%   cache = simplecache( 'put', cache, key, val );
%
%   %%% attempt to get something from cache.  found==1 if obj was found, val is the obj.
%   [found,val] = simplecache( 'get', cache, key );
%
%   %%% free key
%   [cache,found] = simplecache( 'remove', cache, key );
%
%
% EXAMPLE
%   cache = simplecache('init');
%   hellokey=rand(1,3); worldkey=rand(1,11);
%   cache = simplecache( 'put', cache, hellokey, 'hello' );
%   cache = simplecache( 'put', cache, worldkey, 'world' );
%   [f,v]=simplecache( 'get', cache, hellokey ); disp(v);
%   [f,v]=simplecache( 'get', cache, worldkey ); disp(v);
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also PERSISTENT, MASK_GAUSSIANS

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function varargout = simplecache( op, cache, varargin )

    if( strcmp(op,'init') ) %%% init a cache
        error(nargchk(1, 2, nargin));
        error(nargoutchk(1, 1, nargout));
        
        cache_siz = 8; % initial size
        cache.freeinds = 1:cache_siz;
        cache.keyns = -ones(1,cache_siz);
        cache.keys = cell(1,cache_siz);
        cache.vals = cell(1,cache_siz);
        
        varargout = {cache};
        
        
    elseif( strcmp(op,'put') ) %%% a put operation
        error(nargchk(4, 4, nargin));
        error(nargoutchk(1, 1, nargout));
        [ key, val ] = deal( varargin{:} );
        if( ~isvector(key) ) error( 'key must be a vector' ); end;

        cache = cacheput( cache, key, val );
        
        varargout = {cache};

        
    elseif( strcmp(op,'get') ) %%% a get operation
        error(nargchk(3, 3, nargin));
        error(nargoutchk(0, 2, nargout));
        key = deal( varargin{:} );
        if( ~isvector(key) ) error( 'key must be a vector' ); end;

        [ind,val] = cacheget( cache, key );
        found = ind>0;
        
        varargout = {found,val};
    
        
    elseif( strcmp(op,'remove') ) %%% a remove operation    
        error(nargchk(3, 3, nargin));
        error(nargoutchk(0, 2, nargout));
        key = deal( varargin{:} );
        if( ~isvector(key) ) error( 'key must be a vector' ); end;

        [cache,found] = cacheremove( cache, key );

        varargout = {cache,found};

        
    else %%% unknown op
        error( ['Unknown cache operation: ' op] );
    end;



    


    
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% double cache size
function cache = cachegrow( cache )
    cache_siz = length( cache.keyns ); 
    if( cache_siz>64 ) % warn if getting big
        warning(['doubling cache size to: ' int2str2(cache_siz*2)]); end;
    cache.freeinds = [cache.freeinds (cache_siz+1):(2*cache_siz)];
    cache.keyns = [cache.keyns -ones(1,cache_siz)];
    cache.keys  = [cache.keys cell(1,cache_siz)];
    cache.vals  = [cache.vals cell(1,cache_siz)];

    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% put something into the cache
function cache = cacheput( cache, key, val )
    
    % get location to place
    ind = cacheget( cache, key ); % see if already in cache
    if( ind==-1 )
        if( length( cache.freeinds )==0 )
            cache = cachegrow( cache ); %grow cache
        end;
        ind = cache.freeinds(1); % get new cache loc
        cache.freeinds = cache.freeinds(2:end);
    end;
    
    % now simply place in ind
    cache.keyns(ind) = length(key);
    cache.keys{ind} = key;
    cache.vals{ind} = val;

    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% get cache element, or fail
function [ind,val] = cacheget( cache, key )
    
    cache_siz = length( cache.keyns ); 

    keyn = length( key );  
    for i=1:cache_siz
        if(keyn==cache.keyns(i) && all(key==cache.keys{i}))
            val = cache.vals{i};
            ind = i;
            return;
        end
    end;
    ind=-1; val=-1;
    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% get cache element, or fail
function [cache,found] = cacheremove( cache, key )
    [ind,val] = cacheget( cache, key );
    found = ind>0;
    if( found )
        cache.freeinds = [ind cache.freeinds];
        cache.keyns(ind) = -1;
        cache.keys{ind} = [];
        cache.vals{ind} = [];
    end
