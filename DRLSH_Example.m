clc;
clear all;
close all;

%%
%Reading Data
Data = dlmread('Sample.txt');

%%
% Simple Example
ST = 6;
L = 10;
M = 25;
W = 1;

Selected_Index = DRLSH(Data,M,L,W,ST);
Selected_Data = Data(Selected_Index,:);

figure,
scatter(Data(:,1), Data(:,2), [], Data(:,3), 'filled')
title('Original Datatset')

figure,
scatter(Selected_Data(:,1), Selected_Data(:,2), [], Selected_Data(:,3), 'filled')
title('Selected Dataset')


%%
disp('Calculating Tables 1 and 2 in the paper')
M_Vector = [30 25 20 15 10 05];
ST_Vector =[08 06 04 02];
W = 1;
Size_Vector = [];
for iterations = 1:100
    iterations
    for i1 = 1:numel(M_Vector)
        for ii1 = 1:numel(ST_Vector)
            ST = ST_Vector(ii1);
            L = 10;
            M = M_Vector(i1);
            W = 1;
            
            tic
            Selected_Index_For_timeDuration = DRLSH(Data,M,L,W,ST);
            timeduration (ii1,i1, iterations) = toc;
            Size_Vector_Time_Duration(ii1,i1, iterations) = numel(Selected_Index_For_timeDuration);
        end
    end
end
mean(timeduration,3)
mean(Size_Vector_Time_Duration,3)
round(mean(timeduration,3),3)
