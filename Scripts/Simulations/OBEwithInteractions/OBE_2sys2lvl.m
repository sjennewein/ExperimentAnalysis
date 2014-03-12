function [Ha,Sup,Sdown,Hom,Gamm]=OBE_2sys2lvl(delta)
Nat=2;
gam=2*pi*6.066e6/2; % half-decay rate

%dipole of the transition
dip=[1 0 0];

%Size of the random position distribution
sigX=2;
sigY=2;
sigZ=20;
%Draw the positions
Ncloud=1;
pos1=[sigX*randn(1,Ncloud);sigY*randn(1,Ncloud);sigZ*randn(1,Ncloud)];
pos2=[sigX*randn(1,Ncloud);sigY*randn(1,Ncloud);sigZ*randn(1,Ncloud)];

dist=norm(pos1-pos2);
% plot(pos1','o')

id=[[1 0];[0 1]]; %identity operator

%Free atomic Hamiltonian
h0=[[0 0];[0 delta]];
Ha=kron(id,h0)+kron(h0,id);


%Jumping operators
sup=[[0 0];[0 1]];%raising operator
sdown=[[0 1];[0 0]];%lowering operator

Sup=zeros(Nat,2^Nat,2^Nat);
Sdown=zeros(Nat,2^Nat,2^Nat);

Sup(1,:,:)=kron(sup,id);
Sup(2,:,:)=kron(id,sup);
Sdown(1,:,:)=kron(sdown,id);
Sdown(2,:,:)=kron(id,sdown);

%Coherent part of interaction

Omega=zeros(Nat,Nat);





end