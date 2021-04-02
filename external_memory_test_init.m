
%

%   Copyright 2017 The MathWorks, Inc.

%% Control whether to run matrix vector multiplication module
% Matrix_Multiplication_On = true: Matrix vector multiplication mode
%     Read data from DDR, do matrix vector multiplication, write result back to DDR
% Matrix_Multiplication_On = false: Data Loop Back mode
%     Read data from DDR, write to a RAM inside of the DUT, write the same data back to DDR
Matrix_Multiplication_On = true;

%% parameter initialization
% Vector_Matrix_Length = Matrix_Size^2 + Matrix_Size;
byPass = 0;

inChannel = 1;
outChannel = 2;

Conv_Stride = 1;
Conv_Padding = 0;
Pool_Stride = 2;
Pool_Width = 2;

Ti = 1;
To = 1;
Tr = 1;
Tc = 1;

Feature_Area = Feature_Width * Feature_Height;
Feature_Length = inChannel * Feature_Area;

Weight_Area = Weight_Width * Weight_Height;
Weight_Length = inChannel * Weight_Area * outChannel;

Feature_Weight_Length = Feature_Length + Weight_Length;

outFeature_Width = Feature_Width - Weight_Width + 1;
outFeature_Height = Feature_Height - Weight_Height + 1;
outFeature_Area = outFeature_Width * outFeature_Height;
outFeature_Length = outFeature_Width * outFeature_Height * outChannel;

% Burst_Length = Vector_Matrix_Length;
Burst_Length = Feature_Weight_Length;
DDR_Depth = Weight_Length + Feature_Length + outFeature_Length;
Duty_Cycle = 0.5;
Single_Tolerance = 10e-5;

Delay_FeatureRow = 1;

RAM_OutInteration = inChannel;

Bias = 0;

%% read DDR Data type
maskDataType = get_param('external_memory_test/DDR','OutDataTypeStr');

%% DDR initialization data
if strcmp(maskDataType(1:4),'uint') || strcmp(maskDataType(1:3),'int')
%     ddrInitData =fi((randi([1 100],1,DDR_Depth) -30), numerictype(maskDataType));
ddrInitData =fi((randi([1 100],1,DDR_Depth) -30), 1, 32);
%     ddrInitData =fi((rand(1,DDR_Depth) - 0.3), 1, 32);
elseif strcmp(maskDataType, 'single')
    ddrInitData = single((rand(1,DDR_Depth)));
else
    error('Data type %s is not supported for this example. Please try single or int32, or update hdlcoder_external_memory_init.m to provide correct DDR initialization data for this data type.', maskDataType);
end


% LocalWords:  DDR
