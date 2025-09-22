module `_PREFIX_(dti_pr) 
    import `_PREFIX_(dti_iniu_pack)::*;
#(
    parameter integer unsigned TBU_NUM             = 4,
    parameter integer unsigned TRANSACTION_MAX_NUM = 8
)(
    input   logic                                       clk                                         ,
    input   logic                                       rst_n                                       , 
    // REQ_data channel
    input   logic                                       req_tvalid                                  ,
    input   logic   [AXIS_DATA_WIDTH-1:0]               req_tdata                                   ,
    input   logic   [AXIS_KEEP_WIDTH-1:0]               req_tkeep                                   ,
    input   logic                                       req_tlast                                   ,
    input   logic   [TBU_NUM_WIDTH-1  :0]               req_ttid                                    ,
    output  logic                                       req_tready                                  , //custom rdy
    // RSP_data channel
    output  logic                                       rsp_tvalid                                  ,
    output  logic   [CUSTOM_DATA_WIDTH-1:0]             rsp_tdata                                   ,
    output  logic   [CUSTOM_KEEP_WIDTH-1:0]             rsp_tkeep                                   ,
    output  logic                                       rsp_tlast                                   ,
    output  logic   [TBU_NUM_WIDTH-1    :0]             rsp_ttid                                    ,
    input   logic                                       rsp_tready                                  , //dti rdy
    // DTI_to_conv
    output logic                                        req_valid                                   ,
    input  logic                                        req_ready                                   ,
    output logic    [AXIS_DATA_WIDTH-1:0]               req_data                                    ,
    output logic    [AXIS_KEEP_WIDTH-1:0]               req_keep                                    ,
    output logic    [TBU_NUM_WIDTH-1  :0]               req_tid                                     ,
    output logic                                        req_last                                    ,
    // conc_to_DTI                                                        
    input  logic                                        rsp_valid                                   ,
    output logic                                        rsp_ready                                   ,
    input  logic    [CUSTOM_DATA_WIDTH-1:0]             rsp_data                                    ,
    input  logic    [CUSTOM_KEEP_WIDTH-1:0]             rsp_keep                                    ,
    input  logic    [TBU_NUM_WIDTH-1    :0]             rsp_tid                                     ,
    input  logic                                        rsp_last                                    ,
    // lp interface
    input   logic                                       stall                                       ,
    input   logic                                       partial_reset                               ,
    output  logic                                       idle                                        
    );

    logic [TBU_NUM-1:0]                  entry_con_req       ;
    logic [TBU_NUM-1:0]                  entry_trans_req     ;
    logic [TBU_NUM-1:0]                  entry_trans_ack_last;
    logic [TBU_NUM-1:0]                  entry_ack_con       ;
    logic [TBU_NUM-1:0]                  entry_con_deny      ;
    logic [TBU_NUM-1:0]                  entry_disconnect_req;
    logic [TBU_NUM-1:0]                  entry_disconnect_ack;
    logic [TBU_NUM-1:0]                  entry_idle          ;
    logic                                tbu_req_en          ;
    logic                                tbu_rsp_en          ;
    logic [3:0]                          m_msg_type          ;
    logic [3:0]                          s_msg_type          ;  
    logic                                s_state             ;
    logic [TBU_NUM_WIDTH-1    :0]        entry_tid           [TBU_NUM-1:0];
    logic [TBU_NUM-1          :0]        entry_req_valid     ;
    logic [CUSTOM_DATA_WIDTH-1:0]        entry_req_data      [TBU_NUM-1:0]; 
    logic [CUSTOM_KEEP_WIDTH-1:0]        entry_req_keep      [TBU_NUM-1:0];
    logic [TBU_NUM-1          :0]        entry_reset         ;
    logic [$clog2(TBU_NUM)-1  :0]        entry_reset_id      ;
    logic                                entry_reset_vld     ;
    logic [TBU_NUM-1          :0]        entry_reset_arbiter ;
    logic [CUSTOM_DATA_WIDTH-1:0]        reset_data          ;
    logic                                reset_valid         ;
    logic [TBU_NUM-1          :0]        reset_id            ;
    logic [$clog2(TBU_NUM)-1:0]          allocate_id         ;
    logic                                allocate_vld        ;
    logic [TBU_NUM-1:0]                  allocate_oh         ;
    logic [CUSTOM_KEEP_WIDTH-1:0]        reset_keep          ;   
    logic                                reset_last          ;
    logic [TBU_NUM-1          :0]        entry_req_last      ;
    logic                                entry_ready         ;
    logic [TBU_NUM-1          :0]        trans_num_overflow  ;
    logic                                tcu_trans_ack       ;
     
    //=================================================
    // ROB update logic
    //================================================= 
    assign s_msg_type    = rsp_tdata[3:0];
    assign s_state       = rsp_tdata[4];
    assign m_msg_type    = req_tdata[3:0];
    assign m_state       = req_tdata[4];
    assign tbu_req_en    = req_valid && req_ready && entry_ready;
    assign tbu_rsp_en    = rsp_valid && rsp_ready;
    assign tcu_trans_ack = (s_msg_type==DTI_TBU_TRANS_FAULT) || (s_msg_type==DTI_TBU_TRANS_RESP) || (s_msg_type==DTI_TBU_TRANS_RESPEX);

    generate 
        for (genvar i=0; i<TBU_NUM; i++) begin: rob_update_gen
            assign entry_con_req[i]        = tbu_req_en && (m_msg_type==DTI_TBU_CONDIS_REQ) && m_state && allocate_oh[i];
            assign entry_ack_con[i]        = tbu_rsp_en && (s_msg_type==DTI_TBU_CONDIS_ACK) && s_state && (entry_tid[i] == rsp_tid);
            assign entry_disconnect_ack[i] = tbu_rsp_en && (s_msg_type==DTI_TBU_CONDIS_ACK) && !s_state && (entry_tid[i] == rsp_tid);
            assign entry_disconnect_req[i] = tbu_req_en && (m_msg_type==DTI_TBU_CONDIS_REQ) && !m_state && (entry_tid[i] == req_tid);
            assign entry_trans_req[i]      = tbu_req_en && (m_msg_type==DTI_TBU_TRANS_REQ) && (entry_tid[i] == req_tid);
            assign entry_trans_ack_last[i] = tbu_rsp_en && tcu_trans_ack && (entry_tid[i] == rsp_tid) && rsp_last;
        end
    endgenerate
    //=================================================
    // PREALLOCATE
    //================================================= 
    fcip_lead_one #(
        .ENTRY_NUM (TBU_NUM)
    ) u_fcip_lead_one_entry(
        .v_entry_vld    (entry_idle         ),
        .v_free_idx_oh  (allocate_oh        ),
        .v_free_idx_bin (allocate_id        ),
        .v_free_vld     (allocate_vld       )
    );
    //=================================================
    // ROB
    //================================================= 
    generate 
        for (genvar i=0; i<TBU_NUM; i++) begin: rob_entry
            `_PREFIX_(dti_pr_rob_state_entry) #(               
                .TBU_NUM             (TBU_NUM             ),
                .TRANSACTION_MAX_NUM (TRANSACTION_MAX_NUM )) 
            u_dti_pr_rob_state_entry (
                .clk                 (clk                    ),
                .rst_n               (rst_n                  ),
                .entry_reset         (entry_reset[i]         ),
                .entry_con_req       (entry_con_req[i]       ),
                .entry_trans_req     (entry_trans_req[i]     ),
                .entry_trans_ack_last(entry_trans_ack_last[i]),
                .entry_ack_con       (entry_ack_con[i]       ),
                .entry_disconnect_req(entry_disconnect_req[i]),
                .entry_disconnect_ack(entry_disconnect_ack[i]),
                .req_last            (req_last               ),
                .entry_tid_in        (req_tid                ),
                .req_ready           (req_ready              ),
                .idle                (entry_idle[i]          ),
                .trans_num_overflow  (trans_num_overflow[i]  ),
                .entry_tid_out       (entry_tid[i]           ),
                .entry_req_valid     (entry_req_valid[i]     ),
                .entry_req_data      (entry_req_data[i]      ),
                .entry_req_keep      (entry_req_keep[i]      ),
                .entry_req_last      (entry_req_last[i]      )
            );
        end
    endgenerate 

    assign idle = &entry_idle;
    //=================================================
    // RESET ARBITER
    //================================================= 
    assign entry_reset_arbiter = partial_reset ? ~entry_idle : {TBU_NUM{1'b0}};

    fcip_lead_one #(
        .ENTRY_NUM (TBU_NUM)
    ) u_fcip_lead_one_reset(
        .v_entry_vld    (entry_reset_arbiter  ),
        .v_free_idx_oh  (entry_reset          ),
        .v_free_idx_bin (entry_reset_id       ),
        .v_free_vld     (entry_reset_vld      )
    );
    //=================================================
    // DTI to CUSTOM
    //=================================================
    always_comb begin: trans_num_overflow_ready
        entry_ready = 1'b1;
        for (int i=0; i<TBU_NUM; i++) begin
            if (entry_tid[i] == req_tid) begin
                entry_ready = ~trans_num_overflow[i];
            end
        end
    end

    always_comb begin: reset_mux_logic
        reset_data    = {CUSTOM_DATA_WIDTH{1'b0}};
        reset_keep    = {CUSTOM_KEEP_WIDTH{1'b0}};
        reset_valid   = 1'b0;
        reset_id      = 6'd0;
        for (int i=0; i<TBU_NUM; i++) begin
            if (entry_reset[i]) begin
                reset_valid   = entry_req_valid[i];
                reset_data    = entry_req_data[i];
                reset_keep    = entry_req_keep[i];
                reset_last    = entry_req_last[i];
                reset_id      = entry_tid[i];
            end
        end
    end
    // dti to conv 
    assign req_valid   = partial_reset ? reset_valid : (req_tvalid && ~stall);
    assign req_data    = partial_reset ? reset_data : req_tdata;
    assign req_keep    = partial_reset ? reset_keep : req_tkeep;  
    assign req_tid     = partial_reset ? reset_id : req_ttid;
    assign req_last    = partial_reset ? reset_last : req_tlast;
    assign req_tready  = partial_reset ? 1'd0 : (req_ready && ~stall && entry_ready);
    //=================================================
    // CUSTOM to DTI
    //=================================================  
    assign rsp_tvalid    = partial_reset ? 1'b0 : rsp_valid;
    assign rsp_tdata     = partial_reset ? 80'd0 : rsp_data;
    assign rsp_tkeep     = partial_reset ? 10'h0 : rsp_keep;
    assign rsp_tlast     = partial_reset ? 1'b1 : rsp_last;
    assign rsp_ttid      = partial_reset ? 6'd0 : rsp_tid;
    assign rsp_ready     = partial_reset ? 1'b1 : rsp_tready;   
    //=================================================
    // DEBUG
    //=================================================  
    `ifdef TOY_SIM
        logic [63:0] cycle;
        always_ff @(posedge clk or negedge rst_n) begin
            if(~rst_n)  cycle <= 0;
            else        cycle <= cycle + 1;
        end
        initial begin
            forever begin
                @(posedge clk)
                    if(!allocate_vld && tbu_req_en && (m_msg_type==DTI_TBU_CONDIS_REQ) && m_state) begin
                        $display("ALLOC_ERR: [cycle=%0d]", cycle);
                    end
            end
        end 
    `endif 

endmodule
        
