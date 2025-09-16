module dti_pr_rob_state_entry 
    import dti_pack::*;
    (
    input   logic                                       clk                                         ,
    input   logic                                       rst_n                                       ,

    input   logic                                       entry_reset                                 ,
    input   logic                                       entry_alloc                                 ,
    input   logic                                       entry_release                               ,
    input   logic                                       entry_update                                ,
    input   logic                                       entry_ack_connected                         ,
    input   logic                                       req_last                                    ,
    input   logic  [TBU_NUM_WIDTH-1    :0]              entry_tid_in                                ,
    input   logic                                       req_ready                                   ,

    output  logic                                       idle                                        ,
    output  logic  [TBU_NUM_WIDTH-1    :0]              entry_tid_out                               ,
    output  logic                                       entry_req_valid                             ,
    output  logic  [CUSTOM_DATA_WIDTH-1:0]              entry_req_data                              ,
    output  logic  [CUSTOM_KEEP_WIDTH-1:0]              entry_req_keep                              ,
    output  logic                                       entry_req_last                                             
    );

    logic                                    wait_connected;
    logic                                    is_connected;
    logic                                    is_transaction;
    logic                                    is_disconnected;
    logic                                    transaction_finish;
    logic                                    transaction_process;
    logic                                    disconnect_req;
    logic                                    disconnect_req_mask;
    logic  [3:0]                             disconnect_req_msg_type;
    logic                                    disconnect_req_state;
    logic                                    disconnect_req_protocol;
    logic                                    disconnect_req_imp_def;
    logic  [3:0]                             version;
    logic  [11:0]                            disconnect_req_tok_trans_req;
    logic  [1:0]                             disconnect_req_stages;
    logic                                    spd;
    logic                                    sup_reg;
    logic  [3:0]                             disconnect_req_tok_inv_gnt; 
    logic  [$clog2(TRANSACTION_MAX_NUM)-1:0] transaction_cnt;

    //=================================================
    // ENTRY STATE FSM
    //=================================================
    assign transaction_finish  = entry_update & req_last;
    assign transaction_process = entry_update & !req_last;

    always_ff @(posedge clk or negedge rst_n) begin: state_idle_update
        if(!rst_n)                                         idle <= 1'b1;
        else if(entry_alloc)                               idle <= 1'b0;
        else if(entry_release)                             idle <= 1'b1; 
    end

    always_ff @(posedge clk or negedge rst_n) begin: state_wait_connected_update
        if(!rst_n)                                         wait_connected <= 1'b0;
        else if(entry_alloc)                               wait_connected <= 1'b1;
        else if(entry_ack_connected)                       wait_connected <= 1'b0;
        else if(entry_release)                             wait_connected <= 1'b0; 
    end

    always_ff @(posedge clk or negedge rst_n) begin: state_connected_update
        if(!rst_n)                                         is_connected <= 1'b0;
        else if(entry_ack_connected)                       is_connected <= 1'b1;
        else if(transaction_finish & !entry_reset)         is_connected <= 1'b1;
        else if(entry_reset)                               is_connected <= 1'b0; 
        else if(transaction_process)                       is_connected <= 1'b0;    
    end

    always_ff @(posedge clk or negedge rst_n) begin: state_transaction_update
        if(!rst_n)                                         is_transaction <= 1'b0;
        else if(transaction_process)                       is_transaction <= 1'b1;
        else if(transaction_finish)                        is_transaction <= 1'b0; 
    end

    always_ff @(posedge clk or negedge rst_n) begin: state_disconnected_update
        if(!rst_n)                                         is_disconnected <= 1'b0;
        else if(transaction_finish & entry_reset)          is_disconnected <= 1'b1;
        else if(entry_reset & is_connected)                is_disconnected <= 1'b1; 
        else if(entry_release)                             is_disconnected <= 1'b0;
    end

    //=================================================
    // OUTPUT
    //=================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n)                            entry_tid_out <= 6'd0;
        else if(entry_alloc)                  entry_tid_out <= entry_tid_in;
    end

    always_ff @(posedge clk or negedge rst_n) begin: disconnect_req_mask_gen
        if(!rst_n) 
            disconnect_req_mask <= 1'b0;
        else if(is_disconnected && !req_ready)
            disconnect_req_mask <= 1'b0;
        else if(is_disconnected && req_ready)
            disconnect_req_mask <= 1'b1;
    end

    // general setting
    assign sup_reg = 1'b0; // state 0 ignore
    assign spd     = 1'b0; // state 0 ignore
    assign version = 4'd0; // DTI-TBUv1:0

    // disconnect_gen
    assign disconnect_req_msg_type      = 4'h0; // DTI_TBU_CONDIS_REQ
    assign disconnect_req_state         = 1'd0; // disconnected
    assign disconnect_req_protocol      = 1'd0; // DTI-TBU must be 0
    assign disconnect_req_imp_def       = 1'd0; 
    assign disconnect_req_stages        = 2'd0; // state 0 ignore
    assign disconnect_req_tok_trans_req = 12'd0;
    assign disconnect_req_tok_inv_gnt   = 4'd0; // state 0 ignore

    assign disconnect_req = is_disconnected && !disconnect_req_mask;

    always_ff @(posedge clk or negedge rst_n) begin
       if(!rst_n)                       transaction_cnt <= '0;
       else if(entry_alloc)             transaction_cnt <= '0;
       else if(transaction_finish)      transaction_cnt <= '0;
       else if(entry_update)            transaction_cnt <= transaction_cnt + 1'b1;
    end

    assign entry_req_last    = is_transaction ? (transaction_cnt==TRANSACTION_MAX_NUM-1) : 1'b1; 
    assign entry_req_valid   = entry_reset ? (disconnect_req||is_transaction) : 1'd0;
    assign entry_req_keep    = is_disconnected ? 10'hf : 10'h3ff;
    assign entry_req_data    = 80'h0;

endmodule