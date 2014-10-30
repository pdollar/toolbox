function varargout = simpleCache( op, cache, varargin )
% A simple cache that can be used to store results of computations.
%
% Can save and retrieve arbitrary values using a vector (includnig char
% vectors) as a key. Especially useful if a function must perform heavy
% computation but is often called with the same inputs (for which it will
% give the same outputs).  Note that the current implementation does a
% linear search for the key (a more refined implementation would use a hash
% table), so it is not meant for large scale usage.
%
% To use inside a function, make the cache persistent:
%  persistent cache; if( isempty(cache) ) cache=simpleCache('init'); end;
% The following line, when placed inside a function, means the cache will
% stay in memory until the matlab environment changes.  For an example
% usage see maskGaussians.
%
% USAGE - 'init': initialize a cache object
%  cache = simpleCache('init');
%
% USAGE - 'put': put something in cache.  key must be a numeric vector
%  cache = simpleCache( 'put', cache, key, val );
%
% USAGE - 'get': retrieve from cache.  found==1 if obj was found
%  [found,val] = simpleCache( 'get', cache, key );
%
% USAGE - 'remove': free key
%  [cache,found] = simpleCache( 'remove', cache, key );
%
% INPUTS
%  op         - 'init', 'put', 'get', 'remove'
%  cache      - the cache object being operated on
%  varargin   - see USAGE above
%
% OUTPUTS
%  varargout  - see USAGE above
%
% EXAMPLE
%  cache = simpleCache('init');
%  hellokey=rand(1,3); worldkey=rand(1,11);
%  cache = simpleCache( 'put', cache, hellokey, 'hello' );
%  cache = simpleCache( 'put', cache, worldkey, 'world' );
%  [f,v]=simpleCache( 'get', cache, hellokey ); disp(v);
%  [f,v]=simpleCache( 'get', cache, worldkey ); disp(v);
%
% See also PERSISTENT, MASKGAUSSIANS
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.61
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

switch op
  case 'init' % init a cache
    cacheSiz = 8;
    cache.freeinds = 1:cacheSiz;
    cache.keyns = -ones(1,cacheSiz);
    cache.keys = cell(1,cacheSiz);
    cache.vals = cell(1,cacheSiz);
    varargout = {cache};
    
  case 'put' % a put operation
    key=varargin{1}; val=varargin{2};
    cache = cacheput( cache, key, val );
    varargout = {cache};
    
  case 'get' % a get operation
    key=varargin{1};
    [ind,val] = cacheget( cache, key );
    found = ind>0;
    varargout = {found,val};
    
  case 'remove'  % a remove operation
    key=varargin{1};
    [cache,found] = cacheremove( cache, key );
    varargout = {cache,found};
    
  otherwise
    error('Unknown cache operation: %s',op);
end
end

function cache = cachegrow( cache )
% double cache size
cacheSiz = length( cache.keyns );
if( cacheSiz>64 ) % warn if getting big
  warning(['doubling cache size to: ' int2str2(cacheSiz*2)]);%#ok<WNTAG>
end
cache.freeinds = [cache.freeinds (cacheSiz+1):(2*cacheSiz)];
cache.keyns = [cache.keyns -ones(1,cacheSiz)];
cache.keys  = [cache.keys cell(1,cacheSiz)];
cache.vals  = [cache.vals cell(1,cacheSiz)];
end

function cache = cacheput( cache, key, val )
% put something into the cache

% get location to place
ind = cacheget( cache, key ); % see if already in cache
if( ind==-1 )
  if( isempty( cache.freeinds ) )
    cache = cachegrow( cache ); %grow cache
  end
  ind = cache.freeinds(1); % get new cache loc
  cache.freeinds = cache.freeinds(2:end);
end

% now simply place in ind
cache.keyns(ind) = length(key);
cache.keys{ind} = key;
cache.vals{ind} = val;
end

function [ind,val] = cacheget( cache, key )
% get cache element, or fail
cacheSiz = length( cache.keyns );
keyn = length( key );
for i=1:cacheSiz
  if(keyn==cache.keyns(i) && all(key==cache.keys{i}))
    val = cache.vals{i}; ind = i; return; end
end
ind=-1; val=-1;
end

function [cache,found] = cacheremove( cache, key )
% get cache element, or fail
ind = cacheget( cache, key );
found = ind>0;
if( found )
  cache.freeinds = [ind cache.freeinds];
  cache.keyns(ind) = -1;
  cache.keys{ind} = [];
  cache.vals{ind} = [];
end
end
