module dti_partial_reset 
    import dti_pack::*;
    (
    input   logic                                       clk                                         ,
    input   logic                                       rst_n                                       ,
    // DTI_PR_adapter
    input   logic                                       patial_reset                                ,
    output  logic                                       idle                                        ,
    // REQ_data channel
    input   logic                                       req_tvalid                                  ,
    input   logic   [79:0]                              req_tdata                                   ,
    input   logic   [9:0]                               req_tkeep                                   ,
    input   logic                                       req_tlast                                   ,
    input   logic   [5:0]                               req_tid                                     ,
    output  logic                                       req_tready                                  , // custom rdy
    // RSP_data channel
    output  logic                                       rsp_tvalid                                  ,
    output  logic   [79:0]                              rsp_tdata                                   ,
    output  logic   [9:0]                               rsp_tkeep                                   ,
    output  logic                                       rsp_tlast                                   ,
    output  logic   [5:0]                               rsp_tid                                     ,
    input   logic                                       rsp_tready                                  , // dti rdy
    // DTI_to_custom
    output logic                                        req_valid                                   ,
    input  logic                                        req_ready                                   ,
    output logic    [89:0]                              req_payload                                 ,
    output logic    [5:0]                               req_srcid                                   ,
    output logic    [5:0]                               req_tgtid                                   ,
    output logic                                        req_qos                                     , //tie1
    output logic                                        req_last                                    ,
    input  logic                                        req_threshold                               , // tie1
    // custom_to_DTI                                                        
    input  logic                                        rsp_valid                                   ,
    output logic                                        rsp_ready                                   ,
    input  logic    [89:0]                              rsp_payload                                 ,
    input  logic    [5:0]                               rsp_srcid                                   ,
    input  logic    [5:0]                               rsp_tgtid                                   ,
    input  logic                                        rsp_qos                                     , //tie 1
    input  logic                                        rsp_last                                    ,
    output logic                                        rsp_threshold                                 //tie 1
    );

    logic [TBU_NUM-1:0] tbu_req_en;
    logic [TBU_NUM-1:0] tbu_rsp_en;
    logic [1:0]         entry_state    [TBU_NUM-1:0];
    logic [1:0]         entry_state_nxt[TBU_NUM-1:0];
    logic [3:0]         m_msg_type;
    logic [3:0]         s_msg_type;  
    logic               m_state;
    logic               s_state;
    logic               reset_sel;
    logic               reset_reg;
    logic [TBU_NUM-1:0] tbu_reset;  
    logic [TBU_NUM-1:0] tbu_idle;
    logic [1:0]         current_state [TBU_NUM-1:0];
    logic [5:0]         current_tid;
    logic               reset_req_valid;
    logic               disconnect_req_valid;
    logic               disconnect_req_mask;
    logic  [89:0]       disconnect_req_payload;
    logic  [3:0]        disconnect_req_msg_type;
    logic               disconnect_req_state;
    logic               disconnect_req_protocol;
    logic               disconnect_req_imp_def;
    logic  [3:0]        version;
    logic  [11:0]       disconnect_req_tok_trans_req;
    logic  [1:0]        disconnect_req_stages;
    logic               spd;
    logic               sup_reg;
    logic  [3:0]        disconnect_req_tok_inv_gnt;   
    logic               transaction_req_valid;  
    logic  [89:0]       transaction_req_payload;

    //=================================================
    // ENTRY STATE FSM
    //=================================================
    assign m_msg_type = req_tdata[3:0];
    assign s_msg_type = rsp_payload[13:10];
    assign m_state    = req_tdata[4];
    assign s_state    = rsp_payload[14];

    generate
        for (genvar i=0; i<TBU_NUM; i++) begin: tbu_state_fsm
            // tbu_req_en gen
            assign tbu_req_en[i] = (req_valid && req_ready && (req_srcid == i));
            // tbu_rsp_en gen
            assign tbu_rsp_en[i] = (rsp_valid && rsp_ready && (rsp_srcid == i));
            // tbu_state
            always_ff @(posedge clk or negedge rst_n) begin: entry_state_gen
                if(!rst_n) 
                    entry_state[i] <= IDLE;
                else  
                    entry_state[i] <= entry_state_nxt[i];
            end
            // tbu_state_nxt
            always_comb begin: entry_state_nxt_gen
                entry_state_nxt[i] = entry_state[i];
                case(entry_state[i])
                    IDLE: 
                    begin
                        if(tbu_rsp_en[i] && (s_msg_type==DTI_TBU_CONDIS_ACK) && s_state) 
                            entry_state_nxt[i] = CONNECTED;
                        else 
                            entry_state_nxt[i] = IDLE;
                    end
                    CONNECTED: 
                    begin
                        if(tbu_req_en[i] && !req_last)
                            entry_state_nxt[i] = TRANSACTION;
                        else if(tbu_rsp_en[i] & (s_msg_type==DTI_TBU_CONDIS_ACK) && !s_state)
                            entry_state_nxt[i] = IDLE;
                        else if(tbu_reset[i])
                            entry_state_nxt[i] = DISCONNECTED;
                        else
                            entry_state_nxt[i] = CONNECTED;
                    end
                    TRANSACTION: 
                    begin
                        if(tbu_req_en[i] && req_last && !tbu_reset[i])
                            entry_state_nxt[i] = CONNECTED;
                        else if(tbu_req_en[i] && req_last && tbu_reset[i])
                            entry_state_nxt[i] = DISCONNECTED;
                        else 
                            entry_state_nxt[i] = TRANSACTION;
                    end
                    DISCONNECTED: 
                    begin 
                        if(tbu_rsp_en[i] && (s_msg_type==DTI_TBU_CONDIS_ACK) && !s_state) 
                            entry_state_nxt[i] = IDLE;
                        else 
                            entry_state_nxt[i] = DISCONNECTED;
                    end
                    default: entry_state_nxt[i] = IDLE; 
                endcase    
            end
            // tbu_idle
            assign tbu_idle[i] = (entry_state[i] == IDLE);
        end
    endgenerate

    assign idle = &tbu_idle;
    //=================================================
    // RESET PROCESS
    //=================================================
    always_ff @(posedge clk or negedge rst_n) begin: reset_reg_gen
        if(!rst_n) 
            reset_reg <= 1'b0;
        else if(patial_reset) 
            reset_reg <= 1'b1;
        else if(idle)
            reset_reg <= 1'b0;      
    end
    assign reset_sel = patial_reset | reset_reg;

    generate 
        for (genvar i=0; i<TBU_NUM; i++) begin: reset_process
            if(i==0) begin
                assign tbu_reset[i] = reset_sel && ~tbu_idle[i];
                assign current_state[i] = entry_state[i] & {tbu_reset[i], tbu_reset[i]};
            end   
            else begin   
                assign tbu_reset[i] = reset_sel && ~tbu_idle[i] & ~tbu_reset[i-1];
                assign current_state[i] = entry_state[i] & {tbu_reset[i], tbu_reset[i]} | current_state[i-1];
            end 
        end
    endgenerate   

    // current_tid
    always_comb begin
        current_tid = 6'd0;
        for (int i=0; i<TBU_NUM; i++) begin
            if (tbu_reset[i]) begin
                current_tid = 6'(i);
            end
        end
    end
    //=================================================
    // DTI to CUSTOM
    //=================================================         
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

    always_ff @(posedge clk or negedge rst_n) begin: disconnect_req_mask_gen
        if(!rst_n) 
            disconnect_req_mask <= 1'b0;
        else if(current_state[TBU_NUM-1]!==DISCONNECTED)
            disconnect_req_mask <= 1'b0;
        else if(disconnect_req_valid && req_ready)
            disconnect_req_mask <= 1'b1;
    end
    assign disconnect_req_valid   = (current_state[TBU_NUM-1]==DISCONNECTED) && !disconnect_req_mask; 
    assign disconnect_req_payload = {80'd0, 10'hf}; 

    // transaction_req
    assign transaction_req_valid   = (current_state[TBU_NUM-1]==TRANSACTION);
    assign transaction_req_payload = {80'd0, 10'h3ff};  

    // dti to custom 
    assign req_valid   = reset_sel ? disconnect_req_valid | transaction_req_valid : req_tvalid;
    assign req_payload = disconnect_req_valid ? disconnect_req_payload :
                         transaction_req_valid ? transaction_req_payload :
                         {req_tdata, req_tkeep};  
    assign req_srcid   = reset_sel ? current_tid : req_tid;
    assign req_tgtid   = 6'd0;
    assign req_qos     = 1'b1; // tie1
    assign req_last    = reset_sel ? 1'd1 : req_tlast;
    assign req_tready  = !reset_sel & req_ready;

    //=================================================
    // CUSTOM to DTI
    //=================================================  
    assign rsp_tvalid    = reset_sel ? 1'b0 : rsp_valid;
    assign rsp_tdata     = reset_sel ? 80'd0 : rsp_payload[89:10];
    assign rsp_tkeep     = reset_sel ? 10'h0 : rsp_payload[9:0];
    assign rsp_tlast     = reset_sel ? 1'b1 : rsp_last;
    assign rsp_tid       = reset_sel ? 6'd0 : rsp_tgtid;
    assign rsp_ready     = reset_sel | rsp_tready;    
    assign rsp_threshold = 1'b1; 

endmodule
        