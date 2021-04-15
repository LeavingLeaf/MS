
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

% Quantization
quantization = 8;
bandwidth = 32;

parallin = bandwidth/quantization;
parallout = bandwidth/quantization;

ZERO = fi(0, 1, quantization, 0);
ONE  = fi(1, 1, quantization, 0);

inChannel = 4;
outChannel = 1;

Phase_In = ceil (inChannel / parallin);
Phase_Out = ceil (outChannel / parallout);

mod_in = mod(inChannel , parallin);
byPass = 1;

byPass_pool = 1;
byPass_ReLU = 1;
byPass_Function = 0;

Conv_Stride = 1;
Conv_Padding = 0;
Pool_Stride = 2;
Pool_Width = 2;

Ti = 1;
To = 1;
Tr = 1;
Tc = 1;

Feature_Area = Feature_Width * Feature_Height;
Feature_Length = Phase_In * Feature_Area;

Weight_Area = Weight_Width * Weight_Height;
Weight_Length = Phase_In * Weight_Area * Phase_Out;

Feature_Weight_Length = Feature_Length + Weight_Length;

outFeature_Width = Feature_Width - Weight_Width + 1;
outFeature_Height = Feature_Height - Weight_Height + 1;
outFeature_Area = outFeature_Width * outFeature_Height;
outFeature_Length = outFeature_Width * outFeature_Height * Phase_Out;

% Burst_Length = Vector_Matrix_Length;
Burst_Length = Feature_Weight_Length;
DDR_Depth = Weight_Length + Feature_Length + outFeature_Length;
Duty_Cycle = 0.5;
Single_Tolerance = 10e-5;

Delay_FeatureRow = 1;

RAM_OutInteration = inChannel;

Bias = 0;

%% DDR Intial Data Generation
% Parameters
    % MSB [31:16]
    param_a = fi([Weight_Width, Feature_Width, inChannel, outFeature_Width, Conv_Stride, Pool_Stride, Ti, Tr],1,16,0);
    % LSB [15:0]
    param_b = fi([Weight_Height, Feature_Height, outChannel, outFeature_Height, Conv_Padding, Pool_Width, To, Tc],1,16,0);
    % Param [31:0]
    param_fx32 = bitconcat(param_a, param_b);
    
% WeightData : fix (1,8,7)
    weight = randi([0 100], Weight_Width, Weight_Height, inChannel, outChannel) - 30;
    weight_fx8 = fi (weight, 1, 8, 0);
    weight_fx32 = fi(zeros(Weight_Width, Weight_Height, Phase_In, outChannel),0,32,0);

    % concatenate the 8 bit data to 32 bit 
    for i = 1:Phase_In
        if(i == Phase_In)
        %         for j = 1: parallin
        %                 weight_fx32(:,:,i,:) = bitconcat(weight_fx8)
        %         end
        end

        weight_fx32(:,:,i,:) = bitconcat(weight_fx8(:,:,1 + (i-1)* parallin,:), ...
                                         weight_fx8(:,:,2 + (i-1)* parallin,:), ...
                                         weight_fx8(:,:,3 + (i-1)* parallin,:), ...
                                         weight_fx8(:,:,4 + (i-1)* parallin,:));
    end

    % reshpe the weight matrix to 1-D format in DDR Storege
    weight_fx32_ddr = reshape(weight_fx32.permute([2 1 3 4]), 1, []);
    
% FeatureData
    feature = randi([1 100], Feature_Width, Feature_Height, inChannel) - 30;
    feautre_fx8 = fi(feature, 1, 8, 0);
    feature_fx32 = fi(zeros(Feature_Width, Feature_Height, Phase_In),0,32,0);

    % concatenate the 8 bit data to 32 bit 
    for i = 1:Phase_In
        if(i == Phase_In)
        %         for j = 1: parallin
        %                 weight_fx32(:,:,i,:) = bitconcat(weight_fx8)
        %         end
        end

        feature_fx32(:,:,i) = bitconcat(feautre_fx8(:,:,1 + (i-1)* parallin), ...
                                         feautre_fx8(:,:,2 + (i-1)* parallin), ...
                                         feautre_fx8(:,:,3 + (i-1)* parallin), ...
                                         feautre_fx8(:,:,4 + (i-1)* parallin));
    end

    % reshpe the weight matrix to 1-D format in DDR Storege
    feature_fx32_ddr = reshape(feature_fx32.permute([2 1 3]), 1, []);


%% read DDR Data type
maskDataType = get_param('external_memory_test/DDR','OutDataTypeStr');

%% DDR initialization data
ddrInit_fx32 = horzcat(weight_fx32_ddr, feature_fx32_ddr);
size_ddrInit = size(ddrInit_fx32, 2);

zeros_ddr = fi(zeros(1,DDR_Depth - size_ddrInit),0,32,0);




if strcmp(maskDataType(1:4),'uint') || strcmp(maskDataType(1:3),'int')
% ddrInitData =fi((randi([1 100],1,DDR_Depth) -30), numerictype(maskDataType));
% ddrInitData =fi((randi([1 100],1,DDR_Depth) -30), 0, 32);
    

    ddrInitData= horzcat(ddrInit_fx32, zeros_ddr);

%     ddrInitData =fi((rand(1,DDR_Depth) - 0.3), 1, 32);
elseif strcmp(maskDataType, 'single')
    ddrInitData = single((rand(1,DDR_Depth)));
else
    error('Data type %s is not supported for this example. Please try single or int32, or update hdlcoder_external_memory_init.m to provide correct DDR initialization data for this data type.', maskDataType);
end


% LocalWords:  DDR
