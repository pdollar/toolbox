function [rec,prec,ap] = VOCevallayout_pr(VOCopts,id,draw)

% load test set
[imgids,objids]=textread(sprintf(VOCopts.layout.imgsetpath,VOCopts.testset),'%s %d');

% hash image ids
hash=VOChash_init(imgids);

% load ground truth objects

tic;
n=0;
np=zeros(VOCopts.nparts,1);
for i=1:length(imgids)
    % display progress
    if toc>1
        fprintf('layout pr: load %d/%d\n',i,length(imgids));
        drawnow;
        tic;
    end
    
    % read annotation
    r=PASreadrecord(sprintf(VOCopts.annopath,imgids{i}));
    
    % extract object
    n=n+1;
    o=r.objects(objids(i));
    gt(n)=o;
    
    for j=1:numel(o.part)
        c=strmatch(o.part(j).class,VOCopts.parts,'exact');
        np(c)=np(c)+1;
    end
end

% load results

fprintf('layout pr: loading results\n');
xml=VOCreadxml(sprintf(VOCopts.layout.respath,id));

% test detections by decreasing confidence

[t,si]=sort(-str2double({xml.results.layout.confidence}));
nd=numel(si);

det=false(n,1);

ptp=[];
pfp=[];
pc=[];

for di=1:nd
        
    % display progress
    if toc>1
        fprintf('layout pr: compute: %d/%d\n',di,nd);
        drawnow;
        tic;
    end
    
    % match result to ground truth object
    d=xml.results.layout(si(di));
    ii=VOChash_lookup(hash,d.image);
    oi=ii(objids(ii)==str2num(d.object));
    
    if isempty(oi)
        warning('unrecognized layout: image %s, object %s',d.image,d.object);
        continue
    end
    
    if det(oi)
        warning('duplicate layout: image %s, object %s',d.image,d.object);
        continue
    end
    det(oi)=true;
    o=gt(oi);            

    % assign parts to ground truth parts
    
    gtd=false(numel(o.part),1);
    da=zeros(numel(d.part),1);
    dc=zeros(numel(d.part),1);
    for i=1:numel(d.part)     
        dc(i)=strmatch(d.part(i).class,VOCopts.parts,'exact');
        bb=str2double({d.part(i).bndbox.xmin d.part(i).bndbox.ymin ...
                       d.part(i).bndbox.xmax d.part(i).bndbox.ymax});
        
        ovmax=-inf;
        for j=1:numel(o.part)
            if strcmp(d.part(i).class,o.part(j).class)
                bbgt=o.part(j).bbox;
                bi=[max(bb(1),bbgt(1))
                    max(bb(2),bbgt(2))
                    min(bb(3),bbgt(3))
                    min(bb(4),bbgt(4))];
                iw=bi(3)-bi(1)+1;
                ih=bi(4)-bi(2)+1;
                if iw>0 & ih>0                
                    % compute overlap as area of intersection / area of union
                    ua=(bb(3)-bb(1)+1)*(bb(4)-bb(2)+1)+...
                       (bbgt(3)-bbgt(1)+1)*(bbgt(4)-bbgt(2)+1)-...
                       iw*ih;
                    ov=iw*ih/ua;
                    if ov>ovmax
                        ovmax=ov;
                        jmax=j;
                    end
                end
            end
        end
        if ovmax>=VOCopts.minoverlap && ~gtd(jmax)
            da(i)=jmax;
            gtd(jmax)=true;
        end
    end
        
    ptp=[ptp ; da~=0];
    pfp=[pfp ; da==0];
    pc=[pc ; dc];    
end    

% evaluate each part type

for i=1:VOCopts.nparts

    % compute precision/recall

    fpi=cumsum(pfp(pc==i));
    tpi=cumsum(ptp(pc==i));
    v=tpi+fpi>0;
    rec{i}=tpi(v)/np(i);
    prec{i}=tpi(v)./(fpi(v)+tpi(v));

    ap{i}=VOCap(rec{i},prec{i});
    
    if draw
        % plot precision/recall
        subplot(VOCopts.nparts,1,i);
        plot(rec{i},prec{i},'-');
        grid;
        xlabel 'recall'
        ylabel 'precision'
        title(sprintf('subset: %s, part: %s, AP = %.3f',VOCopts.testset,VOCopts.parts{i},ap{i}));
    end
end
