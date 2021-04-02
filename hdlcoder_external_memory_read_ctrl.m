function [valid_out, count_out, ddr_read_done, rd_addr, rd_len, rd_avalid] = ...
    hdlcoder_external_memory_read_ctrl(burst_len, start, rd_aready, rd_dvalid)
%

%   Copyright 2017 The MathWorks, Inc.

% create persistent variables (registers)
persistent rstate burst_stop burst_count
if isempty(rstate)
    rstate      = fi(0, 0, 4, 0);
    burst_stop  = uint32(0);
    burst_count = uint32(0);
end

% state Memory Encoding
IDLE               = fi(0, 0, 4, 0);
READ_BURST_START   = fi(1, 0, 4, 0);
READ_BURST_REQUEST = fi(2, 0, 4, 0);
DATA_COUNT         = fi(3, 0, 4, 0);

% state machine logic
switch (rstate)
    case IDLE
        % output to AXI4 Master
        rd_addr   = uint32(0);
        rd_len    = uint32(0);
        rd_avalid = false;
        
        % output to DUT logic
        valid_out = false;
        count_out = uint32(0);
        ddr_read_done = true;
        
        % State vars
        burst_stop  = uint32(burst_len);
        burst_count = uint32(0);
        
        if start
            rstate(:) = READ_BURST_START;
        else
            rstate(:) = IDLE;
        end
        
    case READ_BURST_START
        % output to AXI4 Master
        rd_addr   = uint32(0);
        rd_len    = uint32(burst_stop);
        rd_avalid = false;
        
        % output to DUT logic
        valid_out = false;
        count_out = uint32(0);
        ddr_read_done = false;
        
        if rd_aready
            rstate(:) = READ_BURST_REQUEST;
        else
            rstate(:) = READ_BURST_START;
        end
        
    case READ_BURST_REQUEST
        % output to AXI4 Master
        rd_addr   = uint32(0);
        rd_len    = uint32(burst_stop);
        rd_avalid = true;
        
        % output to DUT logic
        valid_out = false;
        count_out = uint32(0);
        ddr_read_done = false;
        
        rstate(:) = DATA_COUNT;
        
    case DATA_COUNT
        % output to AXI4 Master
        rd_addr   = uint32(0);
        rd_len    = uint32(burst_stop);
        rd_avalid = false;
        
        % output to DUT logic
        valid_out = rd_dvalid;
        count_out = uint32(burst_count);
        ddr_read_done = false;
        
        % State vars
        if ( rd_dvalid )
            burst_count = uint32(burst_count + 1);
        end
        
        if ( burst_count == burst_stop )
            rstate(:) = IDLE;
        else
            rstate(:) = DATA_COUNT;
        end
        
    otherwise
        % output to AXI4 Master
        rd_addr   = uint32(0);
        rd_len    = uint32(0);
        rd_avalid = false;
        
        % output to DUT logic
        valid_out = false;
        count_out = uint32(0);
        ddr_read_done = false;
        
        rstate(:) = IDLE;
end

end

% LocalWords:  AXI
