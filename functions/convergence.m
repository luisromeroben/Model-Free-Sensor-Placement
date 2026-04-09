%% Convergencia %%

function res = convergence(val,val_hist)

    if all(abs(val(:)-val(1))<1e-3)
       res = 1;
    else
        if size(val_hist,1) >= 10
            res = 1;
            for i=1:size(val_hist,2)
                if all(abs(val_hist(:,i)-val(1,i))>1e-3)
                    res = 0;
                end
            end
        else
            res = 0;
        end
    end

end