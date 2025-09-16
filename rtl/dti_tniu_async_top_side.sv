module `_PREFIX_(dti_tniu_async_top_side)
    import lwnoc_lp_define_package::*;
    import lwnoc_lp_struct_package::*;
    import `_PREFIX_(dti_tniu_pack)::*;
#(
    parameter integer unsigned ASYNC_FIFO_DEPTH = 10    
)(
    input   logic                                            clk                                        ,
    input   logic                                            rst_n                                      ,
    // REQ_data channel
    input   logic                                            req_valid                                  ,
    input   logic  [CUSTOM_DATA_WIDTH+CUSTOM_KEEP_WIDTH-1:0] req_payload                                ,
    input   logic                                            req_last                                   ,
    input   logic  [TBU_NUM_WIDTH-1                      :0] req_srcid                                  ,
    input   logic  [TBU_NUM_WIDTH-1                      :0] req_tgtid                                  ,
    input   logic                                            req_qos                                    , //tie 1
    output  logic                                            req_threshold                              ,
    output  logic                                            req_ready                                  , //async rdy
    // async fifo req
    output logic    [ASYNC_FIFO_DEPTH-1                  :0] req_wptr_async                             ,
    input  logic    [ASYNC_FIFO_DEPTH-1                  :0] req_rptr_async                             ,
    input  logic    [ASYNC_FIFO_DEPTH-1                  :0] req_rptr_sync                              ,
    output logic    [90+6+6+1+1                          :0] req_pld_sync                               ,
    // RSP_data channel
    output  logic                                            rsp_valid                                  ,
    output  logic  [CUSTOM_DATA_WIDTH+CUSTOM_KEEP_WIDTH-1:0] rsp_payload                                ,
    output  logic                                            rsp_last                                   ,
    output  logic  [TBU_NUM_WIDTH-1                      :0] rsp_srcid                                  ,
    output  logic  [TBU_NUM_WIDTH-1                      :0] rsp_tgtid                                  ,
    output  logic                                            rsp_qos                                    , //tie 1
    input   logic                                            rsp_threshold                              ,
    input   logic                                            rsp_ready                                  , //custom rdy
    // async fifo rsp
    input  logic    [ASYNC_FIFO_DEPTH-1                  :0] rsp_wptr_async                             ,
    output logic    [ASYNC_FIFO_DEPTH-1                  :0] rsp_rptr_async                             ,
    output logic    [ASYNC_FIFO_DEPTH-1                  :0] rsp_rptr_sync                              ,
    input  logic    [90+6+6+1+1                          :0] rsp_pld_sync                               ,
    // lp
    input  lwnoc_lp_req_signal_t                             lp_hub_rx_req                              ,
    output lwnoc_lp_req_signal_t                             lp_hub_tx_req 
);
    logic [90+6+6+1+1-1:0]  req_pld_vector     ;
    logic                   async_req_stall    ;
    logic                   async_req_clear    ;
    logic                   async_req_full_zero;
    logic [90+6+6+1+1-1:0]  rsp_pld_vector     ;
    logic                   rsp_async_stall    ;
    logic                   rsp_async_clear    ;
    logic                   rsp_async_full_zero;
    logic                   rsp_async_idle     ;
    lwnoc_lp_req_signal_t   v_stage_1_hub_rx_req[2:0];
    lwnoc_lp_req_signal_t   v_stage_1_hub_tx_req[2:0];
    lwnoc_lp_req_signal_t   async_master_hub_tx_req;
    lwnoc_lp_req_signal_t   async_master_hub_rx_req;
    lwnoc_lp_req_signal_t   async_slave_hub_tx_req ;
    lwnoc_lp_req_signal_t   async_slave_hub_rx_req ;
    //===========================================================================
    // LP
    //===========================================================================
    assign v_stage_1_hub_rx_req[0] = async_slave_hub_rx_req;
    assign v_stage_1_hub_rx_req[1] = async_master_hub_rx_req;
    assign v_stage_1_hub_rx_req[2] = lp_hub_rx_req;

    assign lp_hub_tx_req           = v_stage_1_hub_tx_req[0];
    assign async_slave_hub_tx_req  = v_stage_1_hub_tx_req[1];
    assign async_master_hub_tx_req = v_stage_1_hub_tx_req[2];

    lwnoc_lp_hub_wrapper #(
        .NUM_TERMINAL       (3                          )
    ) u_stage_1_hub (
        .v_rx_req           (v_stage_1_hub_rx_req       ),
        .v_tx_req           (v_stage_1_hub_tx_req       )
    );

    lwnoc_lp_tniu_async_bridge u_slv_lp_tniu(
        .clk                (clk                        ),
        .rst_n              (rst_n                      ),
        .rx_req             (async_slave_hub_tx_req     ),
        .tx_req             (async_slave_hub_rx_req     ),
        .stall_ptr          (req_async_stall            ),
        .clear_ptr          (req_async_clear            ),
        .trans_idle         (1'b1                       ),
        .full_zero          (async_req_full_zero        )
    );

    lwnoc_lp_tniu_async_bridge u_mst_lp_tniu(
        .clk                (clk                        ),
        .rst_n              (rst_n                      ),
        .rx_req             (async_master_hub_tx_req    ),
        .tx_req             (async_master_hub_rx_req    ),
        .stall_ptr          (rsp_async_stall            ),
        .clear_ptr          (rsp_async_clear            ),
        .trans_idle         (1'b1                       ),
        .full_zero          (rsp_async_full_zero        )
    );
    //===========================================================================
    // package
    //===========================================================================
    assign rsp_last             = rsp_pld_vector[0];
    assign rsp_qos              = rsp_pld_vector[1];
    assign rsp_tgtid            = rsp_pld_vector[7:2];
    assign rsp_srcid            = rsp_pld_vector[13:8];
    assign rsp_payload          = rsp_pld_vector[103:14];
    //===========================================================================
    // async fifo req slv
    //===========================================================================
    assign req_pld_vector = {req_payload,req_srcid,req_tgtid,req_qos,req_last};
    afifo_slv #(
        .DATA_WIDTH         (90+6+6+1+1          ),
        .FIFO_DEPTH         (ASYNC_FIFO_DEPTH    )
    ) u_dti_pr_async_fifo_slv (
        .clk                (clk                    ),
        .rst_n              (rst_n                  ),
        .stall              (async_req_stall        ),
        .clear              (async_req_clear        ),
        .full_zero          (async_req_full_zero    ),
        .s_vld              (req_valid              ),
        .s_pld              (req_pld_vector         ),
        .s_rdy              (req_ready              ),
        .wptr_async         (req_wptr_async         ),
        .rptr_async         (req_rptr_async         ),
        .rptr_sync          (req_rptr_sync          ),
        .pld_sync           (req_pld_sync           )
    );
    //===========================================================================
    // async fifo rsp mst
    //===========================================================================
    afifo_mst #(
        .DATA_WIDTH         (90+6+6+1+1             ),
        .FIFO_DEPTH         (ASYNC_FIFO_DEPTH       )
    ) u_dti_pr_async_fifo_mst (
        .clk                (clk                    ),
        .rst_n              (rst_n                  ),
        .stall              (rsp_async_stall        ),
        .clear              (rsp_async_clear        ),
        .full_zero          (rsp_async_full_zero    ),
        .idle               (rsp_async_idle         ),
        .m_vld              (rsp_valid              ),
        .m_pld              (rsp_pld_vector         ),
        .m_rdy              (rsp_ready              ),
        .wptr_async         (rsp_wptr_async         ),
        .rptr_async         (rsp_rptr_async         ),
        .rptr_sync          (rsp_rptr_sync          ),
        .pld_sync           (rsp_pld_sync           )
    );

endmodule 