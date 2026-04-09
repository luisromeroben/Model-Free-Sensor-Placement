function new_ind = combinar_inds(inds,P,G,Ns)

ind1 = P(:,inds(1));
ind2 = P(:,inds(2));

ind1I = find(ind1==1);
ind2I = find(ind2==1);

new_ind = zeros(size(P,1),1);
tosumones = sum(ind1);
sumedones = 0;

for n=1:size(P,1)
    if ind1(n) == 1 && ind2(n)==1
        new_ind(n) =  1;
        ind1I(ind1I == n) = []; ind2I(ind2I == n) = [];
        sumedones = sumedones + 1;
    end
end

sumedones_p = sumedones;
ind1I_p = ind1I;
ind2I_p = ind2I;
new_ind_p = new_ind;

while sum(new_ind) ~= Ns %+ 1
while sumedones < tosumones
    r1 = randi(2);
    if r1==1
        r11 = randi(length(ind1I));
        node = ind1I(r11); ind1I(r11)=[];
        path = cell(length(ind2I),1);
        d = zeros(length(ind2I),1);
        for i=1:length(ind2I)           
            [path{i},d(i)] = shortestpath(G,node,ind2I(i)); 
        end
%         new_ind(node)=1;
    else
        r12 = randi(length(ind2I));
        node = ind2I(r12); ind2I(r12)=[]; 
        path = cell(length(ind1I),1);
        d = zeros(length(ind1I),1);
        for i=1:length(ind1I)           
            [path{i},d(i)] = shortestpath(G,node,ind1I(i)); 
        end
%         new_ind(node)=1;
    end
    [~,Idmin] = min(d);
    pathf = path{Idmin};
    new_node = pathf(round(length(pathf)/2));
    if ~isempty(intersect(find(new_ind==1),new_node))
        new_node = node;
    end
    new_ind(new_node) = 1;
    sumedones = sumedones + 1;
end

if sum(new_ind) ~= Ns %+ 1
   tosumones
   sumedones
   sumedones_p
   sumedones = sumedones_p;
   new_ind = new_ind_p;
   ind1I = ind1I_p;
   ind2I = ind2I_p;
%    error('Combine - new_ind has more or less 1s!!'); 
end
end

end