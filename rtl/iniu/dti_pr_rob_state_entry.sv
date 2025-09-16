module `_PREFIX_(dti_pr_rob_state_entry) 
    import `_PREFIX_(dti_iniu_pack)::*;
    (
    input   logic                                       clk                                         ,
    input   logic                                       rst_n                                       ,

    input   logic                                       entry_reset                                 ,
    input   logic                                       entry_con_req                               ,
    input   logic                                       entry_trans_ack                             ,
    input   logic                                       entry_trans_req                             ,
    input   logic                                       entry_ack_con                               ,
    input   logic                                       entry_disconnect_req                        ,
    input   logic                                       entry_disconnect_ack                        ,
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

    logic                                     req_con      ;
    logic                                     bypass       ;
    logic                                     partial_reset;
    logic                                     normal_dis   ;
    logic                                     req_dis      ;
    logic [$clog2(TRANSACTION_MAX_NUM)-1:0]   trans_num    ; 
    logic                                     entry_release;
    logic                                     trans_finish ;
    logic                                     trans_req    ;
    logic                                     disconnect_req;
    logic                                     disconnect_req_mask;
    logic                                     partial_reset_done;

    //=================================================
    // TRAN NUM
    //=================================================
    always_ff @(posedge clk or negedge rst_n) begin: trans_num_update
        if(!rst_n)                                        trans_num <= 'd0;
        else if(entry_trans_req && entry_trans_ack)       trans_num <= trans_num;
        else if(entry_trans_req)                          trans_num <= trans_num + 1'd1;
        else if(entry_trans_ack)                          trans_num <= trans_num - 1'd1;
    end
    //=================================================
    // TRAN FINISH FLAG
    //=================================================
    always_ff @(posedge clk or negedge rst_n) begin: trans_finish_flag
        if(!rst_n)                                        trans_finish <= 1'd1;
        else if(entry_trans_req && !req_last)             trans_finish <= 1'd0;
        else if(entry_trans_req && req_last)              trans_finish <= 1'd1;
    end
    //=================================================
    // ENTRY STATE FSM
    //=================================================
    assign entry_release      = (req_con || req_dis) && entry_disconnect_ack;
    assign partial_reset_done = disconnect_req && req_ready;

    always_ff @(posedge clk or negedge rst_n) begin: state_idle_update
        if(!rst_n)                                         idle <= 1'b1;
        else if(entry_con_req)                             idle <= 1'b0;
        else if(entry_release)                             idle <= 1'b1; 
    end

    always_ff @(posedge clk or negedge rst_n) begin: state_req_con_update
        if(!rst_n)                                         req_con <= 1'b0;
        else if(idle && entry_con_req)                     req_con <= 1'b1;
        else if(entry_ack_con)                             req_con <= 1'b0;
        else if(entry_disconnect_ack)                      req_con <= 1'b0; 
    end

    always_ff @(posedge clk or negedge rst_n) begin: state_bypass_update
        if(!rst_n)                                         bypass <= 1'b0;
        else if(entry_ack_con && req_con)                  bypass <= 1'b1;
        else if(entry_reset)                               bypass <= 1'b0;
        else if(entry_disconnect_req)                      bypass <= 1'b0;    
    end

    always_ff @(posedge clk or negedge rst_n) begin: state_normal_dis_update
        if(!rst_n)                                         normal_dis <= 1'b0;
        else if(bypass && entry_disconnect_req)            normal_dis <= 1'b1;
        else if(normal_dis)                                normal_dis <= 1'b0; 
    end

    always_ff @(posedge clk or negedge rst_n) begin: state_partial_reset_update
        if(!rst_n)                                         partial_reset <= 1'b0;
        else if(bypass && entry_reset)                     partial_reset <= 1'b1;
        else if(partial_reset_done)                        partial_reset <= 1'b0; 
    end

    always_ff @(posedge clk or negedge rst_n) begin: state_req_dis_update
        if(!rst_n)                                         req_dis <= 1'b0;
        else if(partial_reset_done)                        req_dis <= 1'b1;
        else if(normal_dis)                                req_dis <= 1'b1;
        else if(req_dis&&entry_disconnect_ack)             req_dis <= 1'b0; 
    end
    //=================================================
    // OUTPUT
    //=================================================
    always_ff @(posedge clk or negedge rst_n) begin: entry_tid_out_update
        if(!rst_n)                            entry_tid_out <= 6'd0;
        else if(entry_con_req)                entry_tid_out <= entry_tid_in;
    end

    always_ff @(posedge clk or negedge rst_n) begin: disconnect_req_mask_gen
        if(!rst_n) 
            disconnect_req_mask <= 1'b0;
        else if(disconnect_req && !req_ready)
            disconnect_req_mask <= 1'b0;
        else if(disconnect_req && req_ready)
            disconnect_req_mask <= 1'b1;
    end

    assign disconnect_req   = partial_reset && trans_finish && !disconnect_req_mask && (trans_num=='d0);
    assign trans_req        = partial_reset && !trans_finish;

    assign entry_req_last   = partial_reset ? 1'b1 : 1'b0; 
    assign entry_req_valid  = entry_reset ? (disconnect_req||trans_req) : 1'd0;
    assign entry_req_keep   = disconnect_req ? 10'hf : 10'h3ff;
    assign entry_req_data   = 80'h0;

endmodule
