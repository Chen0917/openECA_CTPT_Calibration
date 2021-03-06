function [KI1,KV2,KI2]=single_line_CT_PT_calibration...
    (line_number,accurate_bus_number,KV1,line_bus_info_set,Z,y)
%% Estimate single line parameters according to the line number
line_name=['line_' ,num2str(line_number), '_measured_positive_sequence.mat'];
VI_origin_struct=load(line_name);
VI_origin = VI_origin_struct.VI_measurement_set;

line_name=['line_' ,num2str(line_number), '_true_positive_sequence.mat'];
VI_origin_struct=load(line_name);
VI_origin_true = VI_origin_struct.VI_true_set;

% impedance matrix
BaseZ = (345000^2)/100000000;
Z = Z*BaseZ;
y = 1i*imag(y)/BaseZ;
ZM = [1+Z*y 1;1 1+Z*y]/(y*(2+Z*y));

if accurate_bus_number == line_bus_info_set(1,1)
    VI = VI_origin;
else
    VI = VI_origin(:,3:4);
    VI = [VI, VI_origin(:,1:2)];
end

%% Data initialization

VV1 = VI(:,1);
II1 = VI(:,2);
VV2 = VI(:,3);
II2 = VI(:,4);

V1=VV1;
V2=VV2;
I1=II1;
I2=II2;

% Zpu=(V1.*V1-V2.*V2)./(I1.*V2-I2.*V1)/2500;
% figure
% plot(Zpu,'*');
% legend('Pre Unit Impedance');
% grid on
%%Remove all the NaNs and -9999s
%Identification of NaNs
nan_record=0;
data_num=1800;

data_num=data_num-sum(isnan(sum(VI,2)));
nan_record=find(isnan(sum(VI,2)));
non_nan_record=find(~isnan(sum(VI,2)));

%Identification of -9999s
negative_infinity_record=0;

for i=1:size(VI,2)
    if negative_infinity_record==0
        negative_infinity_record=find((VI(:,i)+9999)==0);
    else
        negative_infinity_record=[negative_infinity_record ; find((VI(:,i)+9999)==0)];
    end
        
end

%% Estimation method
VVin=[VV1 VV2];%all 1800
Iin=[II1(:,1) II2(:,1)];%real currents

Vm1=VVin(:,1);
Vm2=VVin(:,2);
Im1=Iin(:,1);
Im2=Iin(:,2);

NN=30;
for jk=1:NN;
    JK_initial=jk:30:1800;
    
    if ~isempty(nan_record)
        for j=1:size(nan_record,1)
            JK_initial=JK_initial(find(JK_initial-nan_record(j,1)));
        end        
    end
    if ~isempty(negative_infinity_record)
        for k=1:size(negative_infinity_record,1)
            JK_initial=JK_initial(find(JK_initial-negative_infinity_record(k,1)));
        end
    end
    
    JK=JK_initial;
    Vin=[Vm1(JK) Vm2(JK)];
    Iin=[Im1(JK) Im2(JK)];
    
    Zhat=lscov(Iin,Vin);%1000/sqrt(3) scale factor
    
%     Iin_transpose = conj(Iin');
%     Zhat = (Iin_transpose*Iin)^(-1)*Iin_transpose*Vin;
    
%     [U, S, V] = svd(Iin);
%     r=rank(Iin);
%     U1 = U(:,1:r);
%     S1 = S(1:r,1:r);
%     V1 = V(:,1:r);
%     Zhat = V1*(S1^(-1))*U1'*Vin;
    
    KIhat1(jk) = KV1*Zhat(1,1)/ZM(1,1);
    KVhat2(jk) = KIhat1(jk)*ZM(2,1)/Zhat(1,2);
    KIhat2(jk) = KV1*Zhat(2,1)/ZM(1,2);

end

KI1 = sum(KIhat1)/NN;
KV2 = sum(KVhat2)/NN;
KI2 = sum(KIhat2)/NN;

end


