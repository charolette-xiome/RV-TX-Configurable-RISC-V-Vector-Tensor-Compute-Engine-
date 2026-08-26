module tb_alu;

    localparam int unsigned WIDTH       = 32;
    localparam int unsigned SHIFT_WIDTH = $clog2(WIDTH);

    // ------------------------------------------------------------
    // DUT signals
    // ------------------------------------------------------------

    logic [WIDTH-1:0] a_i;
    logic [WIDTH-1:0] b_i;
    alu_op_t          op_i;

    logic [WIDTH-1:0] result_o;
    logic [WIDTH-1:0] expected;


    // ------------------------------------------------------------
    // Test statistics
    // ------------------------------------------------------------

    int pass_count;
    int fail_count;


    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------

    alu #(
        .WIDTH(WIDTH)
    ) dut (
        .a_i     (a_i),
        .b_i     (b_i),
        .op_i    (op_i),
        .result_o(result_o)
    );


    // ------------------------------------------------------------
    // Self-checking task
    // ------------------------------------------------------------

    task automatic check_alu(
        input logic [WIDTH-1:0] a,
        input logic [WIDTH-1:0] b,
        input alu_op_t          op
    );

        // Drive DUT
        a_i = a;
        b_i = b;
        op_i = op;

        // Allow combinational logic to settle
        #1;

        // --------------------------------------------------------
        // Reference model
        // --------------------------------------------------------

        case (op)

            OP_ADD:
                expected = a + b;

            OP_SUB:
                expected = a - b;

            OP_AND:
                expected = a & b;

            OP_OR:
                expected = a | b;

            OP_XOR:
                expected = a ^ b;

            OP_SLL:
                expected = a << b[SHIFT_WIDTH-1:0];

            OP_SRL:
                expected = a >> b[SHIFT_WIDTH-1:0];

            OP_SRA:
                expected = $signed(a) >>> b[SHIFT_WIDTH-1:0];

            OP_SLT:
                expected = ($signed(a) < $signed(b));

            OP_SLTU:
                expected = (a < b);

            default:
                expected = 'x;

        endcase


        // --------------------------------------------------------
        // Compare DUT with expected result
        // --------------------------------------------------------

        if (result_o !== expected) begin

            fail_count++;

            $error(
                "FAIL | OP=%s | A=%h | B=%h | EXPECTED=%h | GOT=%h",
                op.name(),
                a,
                b,
                expected,
                result_o
            );

        end
        else begin

            pass_count++;

            $display(
                "PASS | OP=%s | A=%h | B=%h | RESULT=%h",
                op.name(),
                a,
                b,
                result_o
            );

        end

    endtask


    // ------------------------------------------------------------
    // Tests
    // ------------------------------------------------------------

    initial begin

        pass_count = 0;
        fail_count = 0;

        // Initial values
        a_i = '0;
        b_i = '0;
        op_i = OP_ADD;

        #1;


        // ========================================================
        // 1. ADD
        // ========================================================

        check_alu(32'd10, 32'd5, OP_ADD);
        check_alu(32'd100, 32'd25, OP_ADD);


        // ========================================================
        // 2. SUB
        // ========================================================

        check_alu(32'd10, 32'd5, OP_SUB);
        check_alu(32'd100, 32'd25, OP_SUB);


        // ========================================================
        // 3. AND
        // ========================================================

        check_alu(32'hAAAA_AAAA, 32'h5555_5555, OP_AND);
        check_alu(32'hFFFF_0000, 32'h0F0F_0F0F, OP_AND);


        // ========================================================
        // 4. OR
        // ========================================================

        check_alu(32'hAAAA_AAAA, 32'h5555_5555, OP_OR);
        check_alu(32'hFFFF_0000, 32'h0000_FFFF, OP_OR);


        // ========================================================
        // 5. XOR
        // ========================================================

        check_alu(32'hAAAA_AAAA, 32'h5555_5555, OP_XOR);
        check_alu(32'hFFFF_0000, 32'h0F0F_0F0F, OP_XOR);


        // ========================================================
        // 6. SLL
        // ========================================================

        check_alu(32'd1, 32'd1, OP_SLL);
        check_alu(32'd1, 32'd4, OP_SLL);


        // ========================================================
        // 7. SRL
        // ========================================================

        check_alu(32'h8000_0000, 32'd1, OP_SRL);
        check_alu(32'hFFFF_FFFF, 32'd4, OP_SRL);


        // ========================================================
        // 8. SRA
        // ========================================================

        check_alu(32'h8000_0000, 32'd1, OP_SRA);
        check_alu(32'hFFFF_FFFF, 32'd4, OP_SRA);


        // ========================================================
        // 9. SLT - signed
        // ========================================================

        check_alu(32'd10, 32'd20, OP_SLT);
        check_alu(32'hFFFF_FFFF, 32'd1, OP_SLT);


        // ========================================================
        // 10. SLTU - unsigned
        // ========================================================

        check_alu(32'd10, 32'd20, OP_SLTU);
        check_alu(32'hFFFF_FFFF, 32'd1, OP_SLTU);


        // ========================================================
        // BOUNDARY / CORNER CASES
        // ========================================================

        // --------------------------------------------------------
        // ADD boundaries
        // --------------------------------------------------------

        check_alu(32'h0000_0000, 32'h0000_0000, OP_ADD);
        check_alu(32'hFFFF_FFFF, 32'h0000_0001, OP_ADD);
        check_alu(32'hFFFF_FFFF, 32'hFFFF_FFFF, OP_ADD);


        // --------------------------------------------------------
        // SUB boundaries
        // --------------------------------------------------------

        check_alu(32'h0000_0000, 32'h0000_0000, OP_SUB);
        check_alu(32'h0000_0000, 32'h0000_0001, OP_SUB);
        check_alu(32'hFFFF_FFFF, 32'h0000_0001, OP_SUB);


        // --------------------------------------------------------
        // AND boundaries
        // --------------------------------------------------------

        check_alu(32'h0000_0000, 32'hFFFF_FFFF, OP_AND);
        check_alu(32'hFFFF_FFFF, 32'hFFFF_FFFF, OP_AND);


        // --------------------------------------------------------
        // OR boundaries
        // --------------------------------------------------------

        check_alu(32'h0000_0000, 32'h0000_0000, OP_OR);
        check_alu(32'hFFFF_FFFF, 32'h0000_0000, OP_OR);


        // --------------------------------------------------------
        // XOR boundaries
        // --------------------------------------------------------

        check_alu(32'h0000_0000, 32'h0000_0000, OP_XOR);
        check_alu(32'hFFFF_FFFF, 32'hFFFF_FFFF, OP_XOR);
        check_alu(32'hFFFF_FFFF, 32'h0000_0000, OP_XOR);


        // --------------------------------------------------------
        // Shift by 0
        // --------------------------------------------------------

        check_alu(32'h1234_5678, 32'd0, OP_SLL);
        check_alu(32'h1234_5678, 32'd0, OP_SRL);
        check_alu(32'h1234_5678, 32'd0, OP_SRA);


        // --------------------------------------------------------
        // Shift by 1
        // --------------------------------------------------------

        check_alu(32'h8000_0000, 32'd1, OP_SLL);
        check_alu(32'h8000_0000, 32'd1, OP_SRL);
        check_alu(32'h8000_0000, 32'd1, OP_SRA);


        // --------------------------------------------------------
        // Shift by WIDTH-1 = 31
        // --------------------------------------------------------

        check_alu(32'h0000_0001, 32'd31, OP_SLL);
        check_alu(32'h8000_0000, 32'd31, OP_SRL);
        check_alu(32'h8000_0000, 32'd31, OP_SRA);


        // --------------------------------------------------------
        // Shift amount with all B bits = 1
        //
        // 32'hFFFF_FFFF
        // lower 5 bits = 11111 = 31
        // --------------------------------------------------------

        check_alu(32'd1, 32'hFFFF_FFFF, OP_SLL);
        check_alu(32'hFFFF_FFFF, 32'hFFFF_FFFF, OP_SRL);
        check_alu(32'h8000_0000, 32'hFFFF_FFFF, OP_SRA);


        // --------------------------------------------------------
        // Signed comparison boundaries
        // --------------------------------------------------------

        // -1 < +1
        check_alu(32'hFFFF_FFFF, 32'd1, OP_SLT);

        // INT_MIN < 0
        check_alu(32'h8000_0000, 32'd0, OP_SLT);

        // INT_MAX > -1
        check_alu(32'h7FFF_FFFF, 32'hFFFF_FFFF, OP_SLT);


        // --------------------------------------------------------
        // Unsigned comparison boundaries
        // --------------------------------------------------------

        // 0 < MAX
        check_alu(32'd0, 32'hFFFF_FFFF, OP_SLTU);

        // MAX > 1
        check_alu(32'hFFFF_FFFF, 32'd1, OP_SLTU);

        // 0 < 1
        check_alu(32'd0, 32'd1, OP_SLTU);


        // ========================================================
        // SUMMARY
        // ========================================================

        $display("");
        $display("==========================================");
        $display("             ALU TEST SUMMARY             ");
        $display("==========================================");
        $display("TOTAL TESTS : %0d", pass_count + fail_count);
        $display("PASSED      : %0d", pass_count);
        $display("FAILED      : %0d", fail_count);
        $display("==========================================");


        if (fail_count == 0)
            $display("************ ALL TESTS PASSED ************");
        else
            $error("************ TESTS FAILED ************");


        $finish;

    end

endmodule
