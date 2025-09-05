package dti_pack;

    localparam integer unsigned TBU_NUM_WIDTH             = 6;
    localparam integer unsigned AXIS_DATA_WIDTH           = 80;
    localparam integer unsigned TBU_NUM                   = 2;

    typedef enum logic [1:0] {
                              IDLE         = 2'b00,
                              CONNECTED    = 2'b01,
                              TRANSACTION  = 2'b10,
                              DISCONNECTED = 2'b11
                             } entry_state_t;

    typedef enum logic [3:0] {
                              DTI_TBU_CONDIS_REQ = 4'h0
                             } m_msg_type_t;

    typedef enum logic [3:0] {
                              DTI_TBU_CONDIS_ACK = 4'h0
                             } s_msg_type_t;

endpackage