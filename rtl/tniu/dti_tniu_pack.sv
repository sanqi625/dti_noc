package `_PREFIX_(dti_tniu_pack);

    localparam integer unsigned TBU_NUM_WIDTH             = 6;
    localparam integer unsigned AXIS_MAX_DATA_WIDTH       = 160;
    localparam integer unsigned AXIS_DATA_WIDTH           = 80;
    localparam integer unsigned AXIS_KEEP_WIDTH           = AXIS_DATA_WIDTH / 8;
    localparam integer unsigned TBU_NUM                   = 2;
    localparam integer unsigned CUSTOM_DATA_WIDTH         = 80;
    localparam integer unsigned CUSTOM_KEEP_WIDTH         = CUSTOM_DATA_WIDTH / 8;
    localparam integer unsigned TRANSACTION_MAX_NUM       = 5; 

    typedef enum logic [3:0] {
                              DTI_TBU_CONDIS_REQ = 4'h0
                             } m_msg_type_t;

    typedef enum logic [3:0] {
                              DTI_TBU_CONDIS_ACK = 4'h0
                             } s_msg_type_t;

endpackage