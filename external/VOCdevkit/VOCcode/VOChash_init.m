function hash = VOChash_init(strs)

hsize=4999;
hash.key=cell(hsize,1);
hash.val=cell(hsize,1);

for i=1:numel(strs)
    s=strs{i};
    h=mod(str2double(s([3:4 6:11 13:end])),hsize)+1;
    j=numel(hash.key{h})+1;
    hash.key{h}{j}=strs{i};
    hash.val{h}(j)=i;
end

