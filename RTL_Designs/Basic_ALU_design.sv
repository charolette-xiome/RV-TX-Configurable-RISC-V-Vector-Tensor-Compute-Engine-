typedef enum logic [3:0] {
    OP_ADD,
    OP_SUB,
    OP_AND,
    OP_OR,
    OP_XOR,
    OP_SLL,
    OP_SRL,
    OP_SRA,
    OP_SLT,
    OP_SLTU
} alu_op_t;


module alu #(
    parameter int unsigned WIDTH = 32
) (
    input  logic [WIDTH-1:0] a_i,
    input  logic [WIDTH-1:0] b_i,
    input  alu_op_t          op_i,
    output logic [WIDTH-1:0] result_o
);

    localparam int unsigned SHIFT_WIDTH = $clog2(WIDTH);

    logic [SHIFT_WIDTH-1:0] shamt;

    assign shamt = b_i[SHIFT_WIDTH-1:0];

    always_comb begin

        result_o = 'x;

        case (op_i)

            OP_ADD:
                result_o = a_i + b_i;

            OP_SUB:
                result_o = a_i - b_i;

            OP_AND:
                result_o = a_i & b_i;

            OP_OR:
                result_o = a_i | b_i;

            OP_XOR:
                result_o = a_i ^ b_i;

            OP_SLL:
                result_o = a_i << shamt;

            OP_SRL:
                result_o = a_i >> shamt;

            OP_SRA:
                result_o = $signed(a_i) >>> shamt;

            OP_SLT:
                result_o = ($signed(a_i) < $signed(b_i));

            OP_SLTU:
                result_o = (a_i < b_i);

            default:
                result_o = 'x;

        endcase

    end

endmodule
