clearvars -except best_ind
addpath("EPANET-Matlab-Toolkit-dev",'functions')
clc;

if exist('d','var')
    d.unload
end

%% Load data from network %%

network = 'BWSN_Network_1';

if ~isfile(fullfile('data',[network '_data.mat']))

    start_toolkit; % The toolkit is then initiated

    path2net_relative = '\networks\';
    netFolderName = sprintf('%s',path2net_relative);
    path2net = [pwd netFolderName];
    netINPFile = [path2net network '.inp'];

    d=epanet(netINPFile);

    % Preprocess data %

    reservoirIDs = [d.NodeReservoirIndex d.NodeTankIndex];
    N = d.NodeCount;
    name = d.NodeNameID;
    A = d.getConnectivityMatrix;
    G = graph(A);

    Gorig = graph(A);
    tEdges = table2array(G.Edges);
    linkLengths = d.getLinkLength;
    linkLengths(d.LinkValveIndex) = 1e-3;
    link_node = d.getLinkNodesIndex;

    % PipeDistance matrix generation %

    for i=1:length(link_node)
        ind1 = [];
        ind2 = [];
        ind1 = find(tEdges(:,1) == link_node(i,1))';
        ind1 = [ind1 find(tEdges(:,1) == link_node(i,2))'];

        ind2 = find(tEdges(:,2) == link_node(i,1))';
        ind2 = [ind2 find(tEdges(:,2) == link_node(i,2))'];

        ind = intersect(ind1,ind2);

        G.Edges.Weight(ind) = linkLengths(i);

    end
    G.Nodes.Name = name';

    PipeDistance = zeros(size(A));
    for i=1:N
        for j=i:N
            [~,PipeDistance(i,j)] = shortestpath(G,i,j);
            PipeDistance(j,i) = PipeDistance(i,j);
        end
    end

    % Get the node coordenades

    x = double(d.getNodeCoordinates{1})';
    y = double(d.getNodeCoordinates{2})';
    node_coordenades = [x y];

    % Close toolkit

    d.closeNetwork();
    d.unload;

    save(fullfile('data',[network '_data.mat']),'A','G','reservoirIDs','PipeDistance','N','node_coordenades')

else

    load(fullfile('data',[network '_data.mat']));

end

%% Set configuration parameters %%

% Sensors %

Ns = 10; % number of sensors
nr = reservoirIDs; % reservoir indices

% GA %

Ni = 5; % number of individuals in the population
pmut = 0.2; % initial mutation probability

% Convergence and counters %

terminated = 0;
cont = 0;
counter = 1;
r_times = 0;
val_hist = [];

% Flags %

plotting = 0;
nn_conv_enabled = 1;

%% Generate initial population %%

preDefSensors = [nr];
NnotpreDefSensors = Ns - length(preDefSensors);

% P is the population %

P = zeros(N,Ni);
if isempty(preDefSensors)
    for i=1:Ni
        p = zeros(N, 1);
        p(randperm(numel(p), Ns)) = 1;
        P(:,i) = p;
    end
else
    for i=1:Ni
        p = zeros(N, 1);
        p(preDefSensors) = 1;
        sd = setdiff(1:N,preDefSensors);
        p(sd(randperm(numel(sd), NnotpreDefSensors))) = 1;
        P(:,i) = p;
    end
end

% #####################################################################
%    Uncomment (and edit) this line if you want to re-run the
%    algorithm maintaining the same best candidate than previous ones
% #####################################################################

if exist(fullfile('results',[network '_sensorization' num2str(Ns) '.mat']),'file')
    load(fullfile('results',[network '_sensorization' num2str(Ns) '.mat']));
    P(:,1) = best_ind;
end

%% Evaluate individuals of initial population %%

val = eval_ind(P,PipeDistance);

if nn_conv_enabled
disp('###### STARTING NNCONV OF INITIAL INDS ######');
for j = 1:Ni
    [P(:,j),val(j)] = nn_conv(P(:,j),PipeDistance,val(j),preDefSensors);
end
disp('###### FINISHED NNCONV OF INITIAL INDS ######');
end

%% Algorithm %%

val_m = [];
color = {'b','r','k','y','g','m','c',...
[175/255 51/255 1],[75/255 132/255 24/255],[1 164/255 5/255]};

while ~terminated
   
    for i=1:Ni/2
        
        % Select two individuals from the previous generation for crossover 
        % (selection probability proportional to the individual's 
        % evaluation function).   
          
        val_m = [val_m;val];
        
        if plotting == 1
            figure(1);
            for l=1:size(val_m,2)
                plot(1:length(val_m(:,l)),val_m(:,l),'*-','Color',color{l});
                hold on
            end
            hold off
            
            pause(0.005);
        end

        % Select the individuals %

        inds = selind(val,Ni);
        
        % Cruzar con cierta probabilidad los dos
        % individuos obteniendo dos descendientes

        new_ind = combinar_inds(inds,P,G,Ns);

        % Cross the two individuals with a certain probability, 
        % obtaining two offspring
        
        r3 = rand;
        if r3 < pmut
            new_ind = mutar_ind(new_ind,nr,Ns,preDefSensors);
        end
        
        % Compute the evaluation function of the two mutated offspring
        
        val_newind = eval_ind(new_ind,PipeDistance); 
        
        % Insert the two mutated offspring into the new generation
        
        P = [P new_ind];
        val = [val val_newind];
        
        [val,I] = sort(val,'ascend');
        P = P(:,I);
        P = P(:,1:end-1);
        val = val(:,1:end-1);
        
        if cont == 70
            if nn_conv_enabled == 1
                [P(:,1),val(1)] = nn_conv(P(:,1),PipeDistance,val(1),preDefSensors);
            end
        elseif cont > 100 
            disp('############## CONT > 100 ################');
            Pnew = zeros(N,Ni);
            if isempty(preDefSensors)
                for j=1:Ni
                    pnew = zeros(N, 1);
                    pnew(randperm(numel(pnew), Ns)) = 1;
                    Pnew(:,j) = pnew;
                end
            else
                for j=1:Ni
                    pnew = zeros(N, 1);
                    pnew(preDefSensors) = 1;
                    sd = setdiff(1:N,preDefSensors);
                    pnew(sd(randperm(numel(sd), NnotpreDefSensors))) = 1;
                    Pnew(:,j) = pnew;
                end
            end
            val_new = eval_ind(Pnew,PipeDistance);
            P = [P(:,1) Pnew(:,2:end)];
            val = [val(1) val_new(2:end)];
            if nn_conv_enabled == 1
                disp('###### STARTING NNCONV OF NEW INDS ######');
                for j = 1:Ni
                    [P(:,j),val(j)] = nn_conv(P(:,j),PipeDistance,val(j),preDefSensors);
                end
                disp('###### FINISHED NNCONV OF NEW INDS ######');
            end
            cont = 0;
            r_times = r_times + 1;
        end
            
    end
    
    if convergence(val,val_hist)
        pmut = pmut+0.1;
        cont=cont+1;
        if mod(cont,10)==0
            fprintf('\ncont convergence = %d\n',cont);
        end
    else
        pmut = 0.2;
        cont = 0;
    end


    if counter >= 50000 || r_times >= 10
        terminated = 1;
    end
    
    if size(val_hist,1) >= 10
        val_hist = [val;val_hist(1:end-1,:)];
    else
        val_hist = [val;val_hist];
    end
    
    counter = counter + 1;
    if mod(counter,50) == 0 && counter >= 50
        fprintf('\nEvaluation function - Best value -> %f\n',val(1));
    end
end    

%% Save the results %%

best_ind = P(:,1);
best_val = val(1);
sensors = find(best_ind==1)';

figure;hold on
fig = plot(graph(A),'XData',node_coordenades(:,1),'YData',node_coordenades(:,2),'Marker','o','MarkerSize',4);
xlabel('Latitude','interpreter','latex','fontsize',14);
ylabel('Longitude','interpreter','latex','fontsize',14);
grid

highlight(fig,sensors,'NodeColor','r','MarkerSize',5);
highlight(fig,nr,'NodeColor','y','MarkerSize',5);

save(fullfile('results',[network '_sensorization' num2str(Ns) '.mat']),'best_ind','best_val','sensors');

%%
bo = best_ind;
for s = 1:31
    
end