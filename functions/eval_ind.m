function val = eval_ind(P,PipeDistance)

val = zeros(1,size(P,2));
for i=1:size(P,2)

DtoS = PipeDistance(:,P(:,i)==1);
mDtoS=min(DtoS,[],2);

val(i) = 2*mean(mDtoS) + max(mDtoS);
end
end