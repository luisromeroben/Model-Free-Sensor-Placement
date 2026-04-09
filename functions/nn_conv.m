
function [new_ind,new_val] = nn_conv(ind,PipeDistance,orig_val,preDefSensors)

convergence = 0;
it=1;
N = length(ind);
x = find(ind==1);
Ns = length(x);

while convergence ~= 1
    fprintf('\nIteration: %d\n',it);
    DtoS = PipeDistance(:,x);
    mDtoS=min(DtoS,[],2);
    val(it) = 2*mean(mDtoS) + max(mDtoS);
    
    index=zeros(N,1);
    
    for n=1:N
        index(n) = cargmin(DtoS(n,:));
    end
    
    xnew=zeros(Ns,1);
    for j=1:Ns
       cluster=find(index==j); 
       PDj = PipeDistance(cluster,cluster);
       mean_node = cluster(cargmin(max(PDj,[],2)));%2*mean(PDj,2)+
       if sum(ismember(preDefSensors,x(j)))==0
           xnew(j) = mean_node;
       else
           xnew(j)= x(j);
       end
    end
    
    DtoSnew = PipeDistance(:,xnew);
    mDtoSnew=min(DtoSnew,[],2);
    val_new = 2*mean(mDtoSnew) + max(mDtoSnew);

    if isempty(setdiff(x,xnew))
        disp('### CONVERGENCE REACHED ###');
        convergence=convergence+1;
    end
    if val_new>val(it)
        disp('### CONVERGENCE REACHED (*) ###');
        convergence = 1;
    else
        x = xnew;
    end

    
    it=it+1;
end

val

if val(end)<orig_val
    new_ind = zeros(length(ind),1); new_ind(x)=1;
    new_val = val(end);
    disp('++++ NEW BEST IND ++++');
else
    new_ind = ind;
    new_val = orig_val;
    disp('---- KEEP BEST IND ----');
end

end