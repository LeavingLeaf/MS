function [ram_addr, ddr_write_done, wr_addr, wr_len, wr_valid] = ...
    hdlcoder_external_memory_write_ctrl(burst_len, start, wr_ready, wr_complete)
%

%   Copyright 2017 The MathWorks, Inc.

% create persistent variables (registers)
persistent wstate burst_stop burst_count
if(isempty(wstate))
    wstate      = fi(0, 0, 4, 0);
    burst_stop  = uint32(0);
    burst_count = uint32(0);
end

% state machine encoding
IDLE              = fi(0, 0, 4, 0);
WRITE_BURST_START = fi(1, 0, 4, 0);
DATA_COUNT        = fi(2, 0, 4, 0);
ACK_WAIT          = fi(3, 0, 4, 0);

% state machine logic
switch (wstate)
    case IDLE
        % output to AXI4 Master
        wr_addr  = uint32(0);
        wr_len   = uint32(0);
        wr_valid = false;
        
        % output to DUT logic
        ram_addr = uint32(0);
        ddr_write_done = true;
        
        % state variables
        burst_stop  = uint32(burst_len);
        burst_count = uint32(0);
        
        if start
            wstate(:) = WRITE_BURST_START;
        else
            wstate(:) = IDLE;
        end
        
        
    case WRITE_BURST_START
        % output to AXI4 Master
        wr_addr  = uint32(0);
        wr_len   = uint32(burst_stop);
        wr_valid = false;
        
        % output to DUT logic
        ram_addr = uint32(burst_count);
        ddr_write_done = false;
        
        if wr_ready
            wstate(:) = DATA_COUNT;
        else
            wstate(:) = WRITE_BURST_START;
        end
        
        
    case DATA_COUNT
        % output to AXI4 Master
        wr_addr  = uint32(0);
        wr_len   = uint32(burst_stop);
        wr_valid = true;
        
        % state variables
        burst_count = uint32(burst_count + 1);
        
        % output to DUT logic
        ram_addr = uint32(burst_count);
        ddr_write_done = false;
        
        if ( burst_count == burst_stop )
            wstate(:) = ACK_WAIT;
        else
            if ( wr_ready )
                wstate(:) = DATA_COUNT;
            else
                wstate(:) = WRITE_BURST_START;
            end
        end
        
        
    case ACK_WAIT
        % output to AXI4 Master
        wr_addr  = uint32(0);
        wr_len   = uint32(0);
        wr_valid = false;
        
        % output to DUT logic
        ram_addr = uint32(0);
        ddr_write_done = false;
        
        if wr_complete
            wstate(:) = IDLE;
        else
            wstate(:) = ACK_WAIT;
        end
        
    otherwise
        % output to AXI4 Master
        wr_addr = uint32(0);
        wr_len = uint32(0);
        wr_valid = false;
        
        % output to DUT logic
        ram_addr = uint32(0);
        ddr_write_done = false;
        
        wstate(:) = IDLE;
        
end

end

% LocalWords:  AXI
