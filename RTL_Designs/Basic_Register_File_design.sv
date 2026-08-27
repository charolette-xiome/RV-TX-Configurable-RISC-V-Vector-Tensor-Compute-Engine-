module reg_file #(
    parameter int unsigned DATA_WIDTH = 32,
    parameter int unsigned REG_COUNT  = 32,
    localparam int unsigned ADDR_WIDTH = $clog2(REG_COUNT)
) (
    input  logic                  clk_i,

    // Write port
    input  logic                  we_i,
    input  logic [ADDR_WIDTH-1:0] rd_i,
    input  logic [DATA_WIDTH-1:0] wdata_i,

    // Read ports
    input  logic [ADDR_WIDTH-1:0] rs1_i,
    input  logic [ADDR_WIDTH-1:0] rs2_i,

    output logic [DATA_WIDTH-1:0] rs1_data_o,
    output logic [DATA_WIDTH-1:0] rs2_data_o
);

    // Register storage
    logic [DATA_WIDTH-1:0] regs [0:REG_COUNT-1];


    //============================================================
    // WRITE LOGIC
    //============================================================

    always_ff @(posedge clk_i) begin

        if (we_i && (rd_i != '0))
            regs[rd_i] <= wdata_i;

    end


    //============================================================
    // READ LOGIC
    //============================================================

    always_comb begin

        // Read port 1
        if (rs1_i == '0)
            rs1_data_o = '0;
        else
            rs1_data_o = regs[rs1_i];

        // Read port 2
        if (rs2_i == '0)
            rs2_data_o = '0;
        else
            rs2_data_o = regs[rs2_i];

    end

endmodule
