function bbs = bbNms( bbs, varargin )
% Non-maximal suppression (nms) of bbs (mean-shift or maximum).
%
% type=='ms': Mean shift non-maximal suppression (nms) of bbs w variable
% width kernel. radii controls the amount of suppression. radii is a 4
% element vector containing the radius for each dimension (x,y,w,h).
% Typically the first two elements should be the same, as should the last
% two. Distance between w/h are computed in log2 space (ie w and w*2 are 1
% unit apart), and the radii should be set accordingly. radii should change
% depending on spatial and scale stride of bbs.
%
% type=='max': Non-maximal suppression (nms) of bbs using area of overlap
% criteria. For each pair of bounding boxes, if their overlap, defined by:
%  overlap(bb1,bb2) = area(intersect(bb1,bb2))/area(union(bb1,bb2))
% is greater than overlap, then the bb with the lower score is suppressed.
% In the Pascal critieria two bbs are considered a match if overlap>=.5;
%
% Although efficient, this function is O(n^2). To speed things up for large
% n, can divide data randomly into two sets, run nms on each, combine and
% run nms on the result. If maxn is specified, will split the set if
% n>maxn. Note that this is a heuristic and can change the results of nms.
%
% USAGE
%  bbs = bbNms( bbs, [varargin] )
%
% INPUTS
%  bbs        - original bbs (must be of form [x y w h wt])
%  varargin   - additional params (struct or name/value pairs)
%   .type       - ['max'] 'max', 'ms', or 'none'
%   .thr        - [0|-inf] ('max'|'ms') threshold below which to discard
%   .maxn       - [500] if n>maxn split and run recursively (see above)
%   .radii      - [.15 .15 1 1] supression radii ('ms' only, see above)
%   .overlap    - [.5] area of overlap for bbs ('max' only, see above)
%
% OUTPUTS
%  bbs      - suppressed bbs
%
% EXAMPLE
%  bbs=[0 0 1 1 1; .1 .1 1 1 1.1; 2 2 1 1 1];
%  bbs1 = bbNms(bbs, 'type','max' )
%  bbs2 = bbNms(bbs, 'thr',.5, 'type','ms')
%
% See also bbApply, nonMaxSuprList

% get parameters
dfs={'type','max','thr',[],'maxn',500,'radii',[.15 .15 1 1],'overlap',.5};
[type,thr,maxn,radii,overlap]=getPrmDflt(varargin,dfs,1);
if(isempty(thr)), if(strcmp(type,'ms')), thr=0; else thr=-inf; end; end
assert(maxn>=2); assert(numel(overlap)==1);

% discard bbs below threshold and run nms1
if(isempty(bbs)), bbs=zeros(0,5); end; if(strcmp(type,'none')), return; end
kp=bbs(:,5)>thr; bbs=bbs(kp,:); if(size(bbs,1)<=1), return; end;
bbs = nms1(bbs,type,thr,maxn,radii,overlap);

  function bbs = nms1( bbs, type, thr, maxn, radii, overlap )
    % if big split in two, recurse, merge, then run on merged
    if( size(bbs,1)>maxn )
      n=size(bbs,1); bbs=bbs(randperm(n),:); n2=floor(n/2);
      bbs0=nms1(bbs(1:n2,:),type,thr,maxn,radii,overlap);
      bbs1=nms1(bbs(n2+1:n,:),type,thr,maxn,radii,overlap);
      bbs=[bbs0; bbs1]; n0=n; n=size(bbs,1);
      if(n<n0), bbs=nms1(bbs,type,thr,maxn,radii,overlap); return; end
    end
    % run actual nms on given bbs
    switch type
      case 'max', bbs = nmsMax(bbs,overlap);
      case 'ms', bbs = nmsMs(bbs,thr,radii);
      case 'cover', bbs = nmsCover(bbs,overlap);
      otherwise, error('unknown type: %s',type);
    end
  end

  function bbs = nmsMax( bbs, overlap )
    % for each i suppress all j st j>i and area-overlap>overlap
    [score,ord]=sort(bbs(:,5),'descend'); bbs=bbs(ord,:);
    n=size(bbs,1); kp=true(1,n); areas=bbs(:,3).*bbs(:,4);
    xs=bbs(:,1); xe=bbs(:,1)+bbs(:,3); ys=bbs(:,2); ye=bbs(:,2)+bbs(:,4);
    for i=1:n
      for j=i+find( kp(i+1:n) )
        iw=min(xe(i),xe(j))-max(xs(i),xs(j)); if(iw<=0), continue; end
        ih=min(ye(i),ye(j))-max(ys(i),ys(j)); if(ih<=0), continue; end
        o=iw*ih; o=o/(areas(i)+areas(j)-o); if(o>overlap), kp(j)=0; end
      end
    end
    bbs=bbs(kp,:);
  end

  function bbs = nmsMs( bbs, thr, radii )
    % position = [x+w/2,y+h/2,log2(w),log2(h)], ws=weights-thr
    ws=bbs(:,5)-thr; w=bbs(:,3); h=bbs(:,4); n=length(w);
    ps=[bbs(:,1)+w/2 bbs(:,2)+h/2 log2(w) log2(h)];
    % find modes starting from each elt, then merge nodes that are same
    ps1=zeros(n,4); ws1=zeros(n,1); stopThr=1e-2;
    for i=1:n, [ps1(i,:) ws1(i,:)]=nmsMs1(i); end
    [ps,ws] = nonMaxSuprList(ps1,ws1,stopThr*100,[],[],2);
    % convert back to bbs format and sort by weight
    w=pow2(ps(:,3)); h=pow2(ps(:,4));
    bbs=[ps(:,1)-w/2 ps(:,2)-h/2 w h ws+thr];
    [ws,ord]=sort(ws,'descend'); bbs=bbs(ord,:);
    
    function [p,w]=nmsMs1(ind)
      % variable bandwith kernel (analytically defined)
      p=ps(ind,:); [n,m]=size(ps); onesN=ones(n,1);
      h = [pow2(ps(:,3)) pow2(ps(:,4)) onesN onesN];
      h = h .* radii(onesN,:); hInv=1./h;
      while(1)
        % compute (weighted) squared Euclidean distance to each neighbor
        d=(ps-p(onesN,:)).*hInv; d=d.*d; d=sum(d,2);
        % compute new mode
        wMask=ws.*exp(-d); wMask=wMask/sum(wMask); p1=wMask'*ps;
        % stopping criteria
        diff=sum(abs(p1-p))/m; p=p1; if(diff<stopThr), break; end
      end
      w = sum(ws.*wMask);
    end
  end

  function bbs = nmsCover( bbs, overlap )
    % construct n^2 neighbor matrix
    n=size(bbs,1); N=sparse(1:n,1:n,.5); a=bbs(:,3).*bbs(:,4);
    xs=bbs(:,1); xe=bbs(:,1)+bbs(:,3); ys=bbs(:,2); ye=bbs(:,2)+bbs(:,4);
    for i=1:n
      for j=i+1:n
        iw=min(xe(i),xe(j))-max(xs(i),xs(j)); if(iw<=0), continue; end
        ih=min(ye(i),ye(j))-max(ys(i),ys(j)); if(ih<=0), continue; end
        o=iw*ih; o=o/(a(i)+a(j)-o); if(o>overlap), N(i,j)=1; end
      end
    end
    % perform set cover operation (greedily choose next best)
    N=N+N'; is=zeros(1,n); ss=zeros(1,n); n1=n; c=0;
    while( n1>0 ), s0=0;
      for i=1:n, s=sum(N(:,i).*bbs(:,5)); if(s>s0), i0=i; s0=s; end; end
      N0=N(:,i0)==1; n1=n1-sum(N0); N(N0,:)=0; N(:,N0)=0;
      c=c+1; is(c)=i0; ss(c)=sum(bbs(N0,5));
    end
    is=is(1:c); ss=ss(1:c); bbs=bbs(is,:); bbs(:,5)=ss;
  end
end
