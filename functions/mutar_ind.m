function ind = mutar_ind(ind,nr,Ns,pDS)

indI = find(ind==1);
t = 1:length(ind);
for i=1:length(indI)
   t(t==indI(i))=[]; 
end

r=randi(length(indI));
while ~isempty(intersect(indI(r),pDS))
    r=randi(length(indI));
end
ind(indI(r))=0;
ind(t(randi(length(t))))=1;

if sum(ind) ~= Ns %+ 1
   error('Ind has more 1s!!'); 
end

end