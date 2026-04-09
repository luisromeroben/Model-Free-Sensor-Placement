
function prob = prob_gen(leak,limit_dist,PipeDistance)


neighbours = find(PipeDistance(leak,:)<limit_dist);
dist_neig = PipeDistance(leak,neighbours);

mod_dn = limit_dist - dist_neig;
mod_dn = mod_dn - min(mod_dn);
mod_dn = mod_dn/max(mod_dn);
prob = zeros(length(PipeDistance),1);
prob(neighbours) = mod_dn';

end