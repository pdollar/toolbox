function [rec,prec,ap] = VOCevalaction(VOCopts,id,cls,draw)

% load test set
[gtimg,gtobj,gt]=textread(sprintf(VOCopts.action.clsimgsetpath,cls,VOCopts.testset),'%s %d %d');

% hash image/object ids
gtid=cell(numel(gtimg),1);
for i=1:numel(gtimg);
    gtid{i}=sprintf('%s/%d',gtimg{i},gtobj(i));
end
hash=VOChash_init(gtid);

% load results
[img,obj,confidence]=textread(sprintf(VOCopts.action.respath,id,cls),'%s %d %f');

% map results to ground truth objects
out=ones(size(gt))*-inf;
tic;
for i=1:length(img)
    % display progress
    if toc>1
        fprintf('%s: pr: %d/%d\n',cls,i,length(img));
        drawnow;
        tic;
    end
    
    % find ground truth object
    k=sprintf('%s/%d',img{i},obj(i));
    j=VOChash_lookup(hash,k);
    if isempty(j)
        error('unrecognized object "%s"',k);
    elseif length(j)>1
        error('multiple image "%s"',k);
    else
        out(j)=confidence(i);
    end
end

% compute precision/recall

[so,si]=sort(-out);
tp=gt(si)>0;
fp=gt(si)<0;

fp=cumsum(fp);
tp=cumsum(tp);
rec=tp/sum(gt>0);
prec=tp./(fp+tp);

ap=VOCap(rec,prec);

if draw
    % plot precision/recall
    plot(rec,prec,'-');
    grid;
    xlabel 'recall'
    ylabel 'precision'
    title(sprintf('class: %s, subset: %s, AP = %.3f',cls,VOCopts.testset,ap));
end
