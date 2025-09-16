module dti_pr_iniu_async_sys_side
    import lwnoc_lp_define_package::*;
    import lwnoc_lp_struct_package::*;
    import dti_pack::*;
    #(
        parameter integer unsigned  ASYNC_FIFO_DEPTH    = 16,
        parameter integer unsigned  TIME_OUT_WIDTH      = 10
    )(
    input   logic                                       clk                          ,
    input   logic                                       rst_n                        ,
    // REQ_data channel
    input   logic                                       req_tvalid                   ,
    input   logic   [AXIS_DATA_WIDTH-1:0]               req_tdata                    ,
    input   logic   [AXIS_KEEP_WIDTH-1:0]               req_tkeep                    ,
    input   logic                                       req_tlast                    ,
    input   logic   [TBU_NUM_WIDTH-1  :0]               req_ttid                     ,
    output  logic                                       req_tready                   , //custom rdy
    // RSP_data channel
    output  logic                                       rsp_tvalid                   ,
    output  logic   [CUSTOM_DATA_WIDTH-1:0]             rsp_tdata                    ,
    output  logic   [CUSTOM_KEEP_WIDTH-1:0]             rsp_tkeep                    ,
    output  logic                                       rsp_tlast                    ,
    output  logic   [TBU_NUM_WIDTH-1    :0]             rsp_ttid                     ,
    input   logic                                       rsp_tready                   , //dti rdy
    // async fifo req
    output logic    [ASYNC_FIFO_DEPTH-1 :0]             req_wptr_async               ,
    input  logic    [ASYNC_FIFO_DEPTH-1 :0]             req_rptr_async               ,
    input  logic    [ASYNC_FIFO_DEPTH-1 :0]             req_rptr_sync                ,
    output logic    [90+6+6+1+1         :0]             req_pld_sync                 ,
    // async fifo rsp
    input  logic    [ASYNC_FIFO_DEPTH-1 :0]             rsp_wptr_async               ,
    output logic    [ASYNC_FIFO_DEPTH-1 :0]             rsp_rptr_async               ,
    output logic    [ASYNC_FIFO_DEPTH-1 :0]             rsp_rptr_sync                ,
    input  logic    [90+6+6+1+1         :0]             rsp_pld_sync                 ,
    // LP
    input  logic    [TIME_OUT_WIDTH-1   :0]             timeout_val                  ,
    input  logic                                        preq                         ,
    input  lwnoc_pchannel_state_t                       pstate                       ,
    output lwnoc_pchannel_active_t                      pactive                      ,
    output logic                                        paccept                      ,
    output logic                                        pdeny                        ,
    input  lwnoc_lp_req_signal_t                        lp_hub_rx_req                ,
    output lwnoc_lp_req_signal_t                        lp_hub_tx_req 
    );    
    // conv
    logic                                               conv_req_valid               ;
    logic                                               conv_req_ready               ;
    logic    [AXIS_DATA_WIDTH-1:0]                      conv_req_data                ;
    logic    [AXIS_KEEP_WIDTH-1:0]                      conv_req_keep                ;
    logic    [TBU_NUM_WIDTH-1  :0]                      conv_req_tid                 ;
    logic                                               conv_req_last                ;                                                     
    logic                                               conv_rsp_valid               ;
    logic                                               conv_rsp_ready               ;
    logic    [CUSTOM_DATA_WIDTH-1:0]                    conv_rsp_data                ;
    logic    [CUSTOM_KEEP_WIDTH-1:0]                    conv_rsp_keep                ;
    logic    [TBU_NUM_WIDTH-1    :0]                    conv_rsp_tid                 ;
    logic                                               conv_rsp_last                ;
    // DTI_to_async             
    logic                                               req_valid                    ;
    logic                                               req_ready                    ;
    logic    [CUSTOM_DATA_WIDTH+CUSTOM_KEEP_WIDTH-1:0]  req_payload                  ;
    logic    [TBU_NUM_WIDTH-1  :0]                      req_srcid                    ;
    logic    [TBU_NUM_WIDTH-1  :0]                      req_tgtid                    ;
    logic                                               req_qos                      ; //tie1
    logic                                               req_threshold                ;
    logic                                               req_last                     ;
    // async_to_DTI                                                                     
    logic                                               rsp_valid                    ;
    logic                                               rsp_ready                    ;
    logic    [CUSTOM_DATA_WIDTH+CUSTOM_KEEP_WIDTH-1:0]  rsp_payload                  ;
    logic    [TBU_NUM_WIDTH-1    :0]                    rsp_srcid                    ;
    logic    [TBU_NUM_WIDTH-1    :0]                    rsp_tgtid                    ;
    logic                                               rsp_qos                      ; //tie 1
    logic                                               rsp_threshold                ;
    logic                                               rsp_last                     ;
    // async fifo req          
    logic                                               async_req_stall              ;
    logic                                               async_req_clear              ;
    logic                                               async_req_full_zero          ;
    logic   [90+6+6+1+1-1:0]                            req_pld_vector               ;
    // async fifo rsp             
    logic                                               rsp_async_stall              ;
    logic                                               rsp_async_clear              ;
    logic                                               rsp_async_full_zero          ;
    logic                                               rsp_async_idle               ;
    logic   [90+6+6+1+1-1:0]                            rsp_pld_vector               ;
    // lp   
    logic                                               niu_stall                    ;
    logic                                               niu_partical_rst             ;
    logic                                               niu_idle                     ;  
    lwnoc_lp_req_signal_t                               v_stage_1_hub_rx_req    [2:0];
    lwnoc_lp_req_signal_t                               v_stage_1_hub_tx_req    [2:0];
    lwnoc_lp_req_signal_t                               v_stage_2_hub_rx_req    [3:0];
    lwnoc_lp_req_signal_t                               v_stage_2_hub_tx_req    [3:0];
    lwnoc_lp_req_signal_t                               lp_iniu_rx_req               ;
    lwnoc_lp_req_signal_t                               lp_iniu_tx_req               ;
    lwnoc_lp_req_signal_t                               niu_lp_hub_rx_req            ;
    lwnoc_lp_req_signal_t                               niu_lp_hub_tx_req            ;
    lwnoc_lp_req_signal_t                               barrier_lp_hub_tx_req        ;
    lwnoc_lp_req_signal_t                               barrier_lp_hub_rx_req        ;
    lwnoc_lp_req_signal_t                               barrier_lp_sub_hub_tx_req    ;
    lwnoc_lp_req_signal_t                               barrier_lp_sub_hub_rx_req    ;
    lwnoc_lp_req_signal_t                               async_master_hub_tx_req      ;
    lwnoc_lp_req_signal_t                               async_master_hub_rx_req      ;
    lwnoc_lp_req_signal_t                               async_slave_hub_tx_req       ;
    lwnoc_lp_req_signal_t                               async_slave_hub_rx_req       ;

    //=================================================
    // LP
    //=================================================

    assign v_stage_1_hub_rx_req[0]   = lp_iniu_rx_req;
    assign v_stage_1_hub_rx_req[1]   = niu_lp_hub_rx_req;
    assign v_stage_1_hub_rx_req[2]   = barrier_lp_hub_rx_req;
  
    assign lp_iniu_tx_req            = v_stage_1_hub_tx_req[0];
    assign niu_lp_hub_tx_req         = v_stage_1_hub_tx_req[1];
    assign barrier_lp_hub_tx_req     = v_stage_1_hub_tx_req[2];

    assign v_stage_2_hub_rx_req[0]   = barrier_lp_sub_hub_rx_req;
    assign v_stage_2_hub_rx_req[1]   = async_slave_hub_rx_req;
    assign v_stage_2_hub_rx_req[2]   = async_master_hub_rx_req;
    assign v_stage_2_hub_rx_req[3]   = lp_hub_rx_req;

    assign barrier_lp_sub_hub_tx_req = v_stage_2_hub_tx_req[0];
    assign async_slave_hub_tx_req    = v_stage_2_hub_tx_req[1];
    assign async_master_hub_tx_req   = v_stage_2_hub_tx_req[2];
    assign lp_hub_tx_req             = v_stage_2_hub_tx_req[3];

    lwnoc_lp_iniu u_lwnoc_lp_iniu(
        .clk          (clk                ),
        .rst_n        (rst_n              ),
        .rx_req       (lp_iniu_tx_req     ),
        .tx_req       (lp_iniu_rx_req     ),
        .preq         (preq               ),
        .pstate       (pstate             ),
        .pactive      (pactive            ),
        .paccept      (paccept            ),
        .pdeny        (pdeny              )
    ); 

    lwnoc_lp_hub_wrapper #(
        .NUM_TERMINAL       (3                          )
    ) u_stage_1_hub (
        .v_rx_req           (v_stage_1_hub_rx_req       ),
        .v_tx_req           (v_stage_1_hub_tx_req       )
    );

    lwnoc_lp_tniu_func_iniu #(
        .TIME_OUT_WIDTH     (TIME_OUT_WIDTH             )
    ) u_intr_lp_tniu(
        .clk                (clk                        ),
        .rst_n              (rst_n                      ),
        .rx_req             (niu_lp_hub_tx_req          ),
        .tx_req             (niu_lp_hub_rx_req          ),
        .stall              (niu_stall                  ),
        .partial_reset      (niu_partical_rst           ),
        .trans_idle         (niu_idle                   ),
        .timeout_val        (timeout_val                )
    );

    lwnoc_lp_nest u_lwnoc_lp_nest(
        .clk                (clk                        ),
        .rst_n              (rst_n                      ),
        .rx_req_main        (barrier_lp_hub_tx_req      ),
        .tx_req_main        (barrier_lp_hub_rx_req      ),
        .rx_req_sub         (barrier_lp_sub_hub_tx_req  ),
        .tx_req_sub         (barrier_lp_sub_hub_rx_req  )
    );

    lwnoc_lp_hub_wrapper #(
        .NUM_TERMINAL       (4                          )
    ) u_stage_2_hub (
        .v_rx_req           (v_stage_2_hub_rx_req       ),
        .v_tx_req           (v_stage_2_hub_tx_req       )
    );

    lwnoc_lp_tniu_async_bridge u_slv_lp_tniu(
        .clk                (clk                        ),
        .rst_n              (rst_n                      ),
        .rx_req             (async_slave_hub_tx_req     ),
        .tx_req             (async_slave_hub_rx_req     ),
        .stall_ptr          (async_req_stall            ),
        .clear_ptr          (async_req_clear            ),
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
    //=================================================
    // DTI_PR
    //================================================= 
    dti_pr u_dti_pr (
    .clk             (clk             ),
    .rst_n           (rst_n           ),
    .stall           (niu_stall       ),
    .partial_reset   (niu_partical_rst),
    .idle            (niu_idle        ),
    .req_tvalid      (req_tvalid      ),
    .req_tdata       (req_tdata       ),
    .req_tkeep       (req_tkeep       ),
    .req_tlast       (req_tlast       ),
    .req_ttid        (req_ttid        ),
    .req_tready      (req_tready      ), //custom rdy
    .rsp_tvalid      (rsp_tvalid      ),
    .rsp_tdata       (rsp_tdata       ),
    .rsp_tkeep       (rsp_tkeep       ),
    .rsp_tlast       (rsp_tlast       ),
    .rsp_ttid        (rsp_ttid        ),
    .rsp_tready      (rsp_tready      ), //dti rdy
    .req_valid       (conv_req_valid  ),
    .req_ready       (conv_req_ready  ),
    .req_data        (conv_req_data   ),
    .req_keep        (conv_req_keep   ),
    .req_tid         (conv_req_tid    ),
    .req_last        (conv_req_last   ),                 
    .rsp_valid       (conv_rsp_valid  ),
    .rsp_ready       (conv_rsp_ready  ),
    .rsp_data        (conv_rsp_data   ),
    .rsp_keep        (conv_rsp_keep   ),
    .rsp_tid         (conv_rsp_tid    ),
    .rsp_last        (conv_rsp_last   )                    
    );
    //=================================================
    // CONV
    //================================================= 
    dti_to_gnpd_conv u_dti_to_gnpd_conv (
    .req_tvalid      (conv_req_valid  ),
    .req_tdata       (conv_req_data   ),
    .req_tkeep       (conv_req_keep   ),
    .req_tlast       (conv_req_last   ),
    .req_ttid        (conv_req_tid    ),
    .req_tready      (conv_req_ready  ), //custom rdy
    .rsp_tvalid      (conv_rsp_valid  ),
    .rsp_tdata       (conv_rsp_data   ),
    .rsp_tkeep       (conv_rsp_keep   ),
    .rsp_tlast       (conv_rsp_last   ),
    .rsp_ttid        (conv_rsp_tid    ),
    .rsp_tready      (conv_rsp_ready  ), //dti rdy
    .req_valid       (req_valid       ),
    .req_ready       (req_ready       ),
    .req_payload     (req_payload     ),
    .req_srcid       (req_srcid       ),
    .req_tgtid       (req_tgtid       ),
    .req_qos         (req_qos         ), //tie1
    .req_last        (req_last        ),
    .req_threshold   (req_threshold   ), //tie1                
    .rsp_valid       (rsp_valid       ),
    .rsp_ready       (rsp_ready       ),
    .rsp_payload     (rsp_payload     ),
    .rsp_srcid       (rsp_srcid       ),
    .rsp_tgtid       (rsp_tgtid       ),
    .rsp_qos         (rsp_qos         ), //tie 1
    .rsp_last        (rsp_last        ),
    .rsp_threshold   (rsp_threshold   )  //tie 1
    );
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
