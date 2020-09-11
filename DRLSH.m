% function Selected_Data_Index = DRLSH(Data,M,L,W,ST)
% This is a function of Locality Sensitive Hashing for Data Reduction
% It is based on the Algorithm developed by Aslani and Seipel in the
% following paper:
% "Mohammad Aslani, Stefan Seipel, A fast instance selection method for support vector machines in building extraction, Applied Soft Computing, 2020, 106716, ISSN 1568-4946" 
%  https://doi.org/10.1016/j.asoc.2020.106716.
%
% This function first calculates the bucket of all data and store them
% Then find similar points in the bucket for removing them.
% The codes are fairly optimal and tried to write them based on matrix
% calculations. 

% Data: is an n-by-m matrix that n is the number of samples and m is the number of attributes (dimensions) + output. 
% For instance, if there are 1000 instances with 7 features, the
% dimension of the matrix is 1000 by 8 (7 input features + 1 output feature).
% M: is the number of hash functions (Hyperplanes) for partitioning the space
% L: is the number of Layers of hash functions
% W: is the bucket size, if Data is normalized between 0 and 1, the best value for W is 1
% Since the data are normalized the suggested value for W is 1. 
% ST: is the Similarity Threshold. ST should not be greater than L.
% If ST is set to L, then only the points that share all the buckets (L)
% are removed. The smaller the value of ST is, the more points are removed. For more
% information about ST please refer to Figure 3 in the paper. 
% Selected_Data_Index: contains the index of the selected data.

%**************************************************************************
% Note: Data Matrix should include both input features (X) and output feature (Y)
%**************************************************************************

% Example:
% M = 25;
% L = 10;
% W = 1;
% ST = 9;
% Selected_Data_Index = DRLSH(Data,M,L,W,ST);
% Selected_Data = Data(Selected_Data_Index, :);


function Selected_Data_Index = DRLSH(Data,M,L,W,ST)

Classes = unique(Data(:,end));

%Normalizing the data between 0 and 1
maximum = max(Data(:,1:end-1));
minimum = min(Data(:,1:end-1));
maxmin = maximum-minimum;
maxmin(maxmin==0) = 1;
Data(:,1:end-1) = (Data(:,1:end-1) - minimum)./maxmin;


Dimension = size(Data(:,1:end-1),2); % Number of features
M = M; % Number of hash functions in each table
L = L; % Number of hash tables
W = W; % Bucket size
Frequency_Neighbors_Threshold = ST; % if the occurance frequency of a neighbor of the current point in all buckets is higher than this value, it is removed. This value should be equal or less than L.


s = rng; %Reset Random Number Generator
a = normrnd(0,1, [M*L , Dimension]); % Generate a in floor((ax+b)/W)
b = W.*rand(M*L,1); % Generate b in floor((ax+b)/W)


% Calculating the buckets of samples
%disp('Bucket Assigning');
Bucket_Index_Decimal_All = int32(zeros(L,size(Data(:,1:end-1),1)));
for i = 1:L
    j = (1+(i-1)*M):i*M;
    Bucket_Index = int16( floor( (a(j,:)*(Data(:,1:end-1))' + b(j,1))/W ) );
    BI = (Bucket_Index);
    %--For splitting BI matrix into PartsNo to make the search faster%
    Bucket_Index_uniqued = ([]);
    partsNo1 = 1;
    vectLength1 = size(BI,2);
    splitsize1 = 1/partsNo1*vectLength1;
    for ijj = 1:partsNo1
        idxs1 = [floor(round((ijj-1)*splitsize1)):floor(round((ijj)*splitsize1))-1]+1;
        Bucket_Index_uniqued = [Bucket_Index_uniqued, unique(  (  (BI(:,idxs1))  )' , 'rows'  )'];             
    end
    Bucket_Index_uniqued  = (unique(Bucket_Index_uniqued', 'rows'))';
    %--For splitting BI matrix into PartsNo to make the search faster%
    
    
    %--For splitting BI matrix into PartsNo to make the search faster%
    partsNo = 1;
    ss = 0;
    vectLength = size(BI,2);
    splitsize = 1/partsNo*vectLength;
    for ij = 1:partsNo
        idxs = [floor(round((ij-1)*splitsize)):floor(round((ij)*splitsize))-1]+1;
        BI_Part = (BI(:,idxs)); 
        [~, Bucket_Index_Decimal]= ismember((BI_Part'), (Bucket_Index_uniqued'), 'rows');
        Bucket_Index_Decimal = int32(Bucket_Index_Decimal');
        Bucket_Index_Decimal_All(i,ss+1:ss+size(Bucket_Index_Decimal,2)) = (Bucket_Index_Decimal);
        ss = ss + size(Bucket_Index_Decimal, 2);
    end
    %---For splitting BI matrix into PartsNo to make the search faster%
end
%disp('Removing Samples');
Removed_Samples_Index_ALL = (int32(zeros(1, size(Data(:,1:end-1),1))));         
RSC= 0;
for classID = 1:numel(Classes)
    All_Indexes = ( (find(Data(:,end)==Classes(classID)))');                    
    Bucket_Index_Decimal_All_Class = (Bucket_Index_Decimal_All(:,All_Indexes)); 
    iii = int32(1);
    TRS = size(Bucket_Index_Decimal_All,2)+1; Temporal_Removed_Samples = TRS;
    while iii<size(All_Indexes,2)
        Current_Sample_Bucket_Index_Decimal = Bucket_Index_Decimal_All_Class(:, iii);
        Bucket_Index_Decimal_All_Class(:, iii)  = -1;
        Number_of_Common_Buckets = sum((Bucket_Index_Decimal_All_Class - Current_Sample_Bucket_Index_Decimal)==0,1);
        Index_Neighbors = Number_of_Common_Buckets>0;
        Frequency_Neighbors = (Number_of_Common_Buckets(Index_Neighbors))';                            
        uniqued_Neighbors = (All_Indexes(Index_Neighbors))'   ;                                                        
        Bucket_Index_Decimal_All_Class(:, iii)  = Current_Sample_Bucket_Index_Decimal;
        Removed_Samples_Current =  (int32(uniqued_Neighbors(Frequency_Neighbors >= Frequency_Neighbors_Threshold)))';
        Removed_Samples_Index_ALL(RSC+1:RSC+size(Removed_Samples_Current,2)) =  Removed_Samples_Current;
        RSC = RSC + size(Removed_Samples_Current,2);
        %--------------for making the algorithm fast--------------%
        Temporal_Removed_Samples = [Temporal_Removed_Samples, Removed_Samples_Current];
        if ( min(Temporal_Removed_Samples) <= All_Indexes(iii+1) ) || ( iii > 2000 )
            [aa, ~]=ismember(All_Indexes,Temporal_Removed_Samples);
            All_Indexes(aa)=[];
            Bucket_Index_Decimal_All_Class(:,aa)= [];
            Temporal_Removed_Samples = TRS;
            All_Indexes(1:iii) = []; % Added
            Bucket_Index_Decimal_All_Class(:,1:iii)=[]; % Added
            iii = 0; % Added
        end
        %--------------for making the algorithm fast--------------%
        iii = iii+1;
    end
end
Removed_Samples_Index_ALL = unique(Removed_Samples_Index_ALL);
Removed_Samples_Index_ALL(Removed_Samples_Index_ALL==0) = [];
Selected_Data_Index = setdiff( (1:size(Data,1)), Removed_Samples_Index_ALL);
