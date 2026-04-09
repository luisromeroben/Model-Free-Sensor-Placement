function inds = selind(val,Ni)

    val_norm = val/(max(val));

    [Y,I] = sort(val_norm,'ascend');
    Yaux = (1-Y);
    Y = Yaux + Y(1) - 0.0; % setting a negative offset allows to regulate
    ns = 0;                % the probability of selecting the best indiv.
                           % (with 0.0, it will be always chosen).
    for i=1:Ni
        r = rand;
        if Y(i)>r && ns < 2
            inds(ns+1) = I(i);
            ns = ns + 1;
        end
        if i==Ni && ns < 2
            inds(ns+1) = I(randi(Ni-1)+1);
        end
    end

end