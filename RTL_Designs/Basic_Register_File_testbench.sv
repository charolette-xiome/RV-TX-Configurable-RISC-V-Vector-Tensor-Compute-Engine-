`timescale 1ns/1ps

module tb_reg_file;

    //============================================================
    // Parameters
    //============================================================

    localparam int unsigned DATA_WIDTH = 32;
    localparam int unsigned REG_COUNT  = 32;
    localparam int unsigned ADDR_WIDTH = $clog2(REG_COUNT);


    //============================================================
    // DUT Signals
    //============================================================

    logic                   clk_i;

    // Read ports
    logic [ADDR_WIDTH-1:0]  rs1_i;
    logic [ADDR_WIDTH-1:0]  rs2_i;

    logic [DATA_WIDTH-1:0]  rs1_data_o;
    logic [DATA_WIDTH-1:0]  rs2_data_o;

    // Write port
    logic [ADDR_WIDTH-1:0]  rd_i;
    logic [DATA_WIDTH-1:0]  wdata_i;
    logic                   we_i;


    //============================================================
    // Test Counters
    //============================================================

    int pass_cnt;
    int fail_cnt;


    //============================================================
    // DUT
    //============================================================

    reg_file #(
        .DATA_WIDTH(DATA_WIDTH),
        .REG_COUNT (REG_COUNT)
    ) dut (
        .clk_i      (clk_i),

        .rs1_i      (rs1_i),
        .rs2_i      (rs2_i),

        .rs1_data_o (rs1_data_o),
        .rs2_data_o (rs2_data_o),

        .rd_i       (rd_i),
        .wdata_i    (wdata_i),
        .we_i       (we_i)
    );


    //============================================================
    // Clock Generation
    //============================================================

    initial begin

        clk_i = 1'b0;

        forever
            #5 clk_i = ~clk_i;

    end


    //============================================================
    // WRITE TASK
    //
    // Writes one register on a rising clock edge.
    //============================================================

    task automatic write_reg(
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [DATA_WIDTH-1:0] data
    );

        begin

            // Change inputs away from active clock edge
            @(negedge clk_i);

            rd_i    = addr;
            wdata_i = data;
            we_i    = 1'b1;

            // Actual write happens here
            @(posedge clk_i);

            // Disable write after the edge
            @(negedge clk_i);

            we_i = 1'b0;

        end

    endtask


    //============================================================
    // READ / CHECK TASK - PORT 1
    //============================================================

    task automatic check_read1(
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [DATA_WIDTH-1:0] exp
    );

        begin

            rs1_i = addr;

            // Allow combinational read logic to settle
            #1;

            if (rs1_data_o === exp) begin

                $display(
                    "[PASS] READ1 x%0d = %h",
                    addr,
                    rs1_data_o
                );

                pass_cnt++;

            end
            else begin

                $error(
                    "[FAIL] READ1 x%0d: expected=%h actual=%h",
                    addr,
                    exp,
                    rs1_data_o
                );

                fail_cnt++;

            end

        end

    endtask


    //============================================================
    // READ / CHECK TASK - PORT 2
    //============================================================

    task automatic check_read2(
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [DATA_WIDTH-1:0] exp
    );

        begin

            rs2_i = addr;

            // Allow combinational read logic to settle
            #1;

            if (rs2_data_o === exp) begin

                $display(
                    "[PASS] READ2 x%0d = %h",
                    addr,
                    rs2_data_o
                );

                pass_cnt++;

            end
            else begin

                $error(
                    "[FAIL] READ2 x%0d: expected=%h actual=%h",
                    addr,
                    exp,
                    rs2_data_o
                );

                fail_cnt++;

            end

        end

    endtask


    //============================================================
    // MAIN TEST SEQUENCE
    //============================================================

    initial begin

        pass_cnt = 0;
        fail_cnt = 0;

        // Initial values
        rs1_i   = '0;
        rs2_i   = '0;
        rd_i    = '0;
        wdata_i = '0;
        we_i    = 1'b0;


        //========================================================
        // TEST 1
        // Basic write/read
        //========================================================

        $display("\n========================================");
        $display("TEST 1: Basic write/read");
        $display("========================================");

        write_reg(5, 32'h1234_5678);

        check_read1(5, 32'h1234_5678);


        //========================================================
        // TEST 2
        // Multiple registers
        //========================================================

        $display("\n========================================");
        $display("TEST 2: Multiple registers");
        $display("========================================");

        write_reg(1,  32'h1111_1111);
        write_reg(10, 32'hAAAA_AAAA);
        write_reg(31, 32'hFFFF_FFFF);

        check_read1(1,  32'h1111_1111);
        check_read1(10, 32'hAAAA_AAAA);
        check_read1(31, 32'hFFFF_FFFF);


        //========================================================
        // TEST 3
        // Two independent read ports
        //========================================================

        $display("\n========================================");
        $display("TEST 3: Two independent read ports");
        $display("========================================");

        rs1_i = 1;
        rs2_i = 10;

        #1;

        if ((rs1_data_o === 32'h1111_1111) &&
            (rs2_data_o === 32'hAAAA_AAAA)) begin

            $display("[PASS] Two independent read ports");

            pass_cnt++;

        end
        else begin

            $error(
                "[FAIL] Two read ports: rs1=%h rs2=%h",
                rs1_data_o,
                rs2_data_o
            );

            fail_cnt++;

        end


        //========================================================
        // TEST 4
        // Same register on both read ports
        //========================================================

        $display("\n========================================");
        $display("TEST 4: Same register on both read ports");
        $display("========================================");

        rs1_i = 5;
        rs2_i = 5;

        #1;

        if ((rs1_data_o === 32'h1234_5678) &&
            (rs2_data_o === 32'h1234_5678)) begin

            $display("[PASS] Same register read");

            pass_cnt++;

        end
        else begin

            $error(
                "[FAIL] Same register read: rs1=%h rs2=%h",
                rs1_data_o,
                rs2_data_o
            );

            fail_cnt++;

        end


        //========================================================
        // TEST 5
        // x0 must always read zero
        //========================================================

        $display("\n========================================");
        $display("TEST 5: x0 read");
        $display("========================================");

        check_read1(0, 32'h0000_0000);
        check_read2(0, 32'h0000_0000);


        //========================================================
        // TEST 6
        // Attempt to write x0
        //========================================================

        $display("\n========================================");
        $display("TEST 6: x0 write ignored");
        $display("========================================");

        write_reg(0, 32'hDEAD_BEEF);

        check_read1(0, 32'h0000_0000);
        check_read2(0, 32'h0000_0000);


        //========================================================
        // TEST 7
        // Write enable disabled
        //========================================================

        $display("\n========================================");
        $display("TEST 7: Write enable");
        $display("========================================");

        // First establish known value
        write_reg(6, 32'hAAAA_AAAA);

        // Attempt to overwrite x6 with WE = 0
        @(negedge clk_i);

        rd_i    = 6;
        wdata_i = 32'h5555_5555;
        we_i    = 1'b0;

        // IMPORTANT:
        // rd_i is WRITE address.
        // rs1_i is READ address.
        rs1_i = 6;

        @(posedge clk_i);

        #1;

        if (rs1_data_o === 32'hAAAA_AAAA) begin

            $display("[PASS] Write disabled correctly");

            pass_cnt++;

        end
        else begin

            $error(
                "[FAIL] Write occurred with we=0: actual=%h",
                rs1_data_o
            );

            fail_cnt++;

        end


        //========================================================
        // TEST 8
        // Register isolation
        //========================================================

        $display("\n========================================");
        $display("TEST 8: Register isolation");
        $display("========================================");

        write_reg(7, 32'h7777_7777);

        check_read1(6, 32'hAAAA_AAAA);
        check_read1(7, 32'h7777_7777);


        //========================================================
        // TEST 9
        // Boundary registers
        //========================================================

        $display("\n========================================");
        $display("TEST 9: Boundary registers");
        $display("========================================");

        write_reg(1,  32'h0000_0001);
        write_reg(31, 32'h8000_0000);

        check_read1(1,  32'h0000_0001);
        check_read1(31, 32'h8000_0000);


        //========================================================
        // TEST 10
        // Data patterns
        //========================================================

        $display("\n========================================");
        $display("TEST 10: Data patterns");
        $display("========================================");

        write_reg(8,  32'h0000_0000);
        write_reg(9,  32'hFFFF_FFFF);
        write_reg(10, 32'hAAAA_AAAA);
        write_reg(11, 32'h5555_5555);

        check_read1(8,  32'h0000_0000);
        check_read1(9,  32'hFFFF_FFFF);
        check_read1(10, 32'hAAAA_AAAA);
        check_read1(11, 32'h5555_5555);


        //========================================================
        // TEST 11
        // Repeated writes
        //========================================================

        $display("\n========================================");
        $display("TEST 11: Repeated writes");
        $display("========================================");

        write_reg(12, 32'h1111_1111);
        write_reg(12, 32'h2222_2222);
        write_reg(12, 32'h3333_3333);
        write_reg(12, 32'h4444_4444);

        check_read1(12, 32'h4444_4444);


        //========================================================
        // TEST 12
        // Read two registers while writing another
        //========================================================

        $display("\n========================================");
        $display("TEST 12: Simultaneous read/write");
        $display("========================================");

        write_reg(13, 32'hAAAA_AAAA);
        write_reg(14, 32'hBBBB_BBBB);

        @(negedge clk_i);

        // Read x13 and x14
        rs1_i = 13;
        rs2_i = 14;

        // Write x15
        rd_i    = 15;
        wdata_i = 32'hCCCC_CCCC;
        we_i    = 1'b1;

        @(posedge clk_i);

        #1;

        if ((rs1_data_o === 32'hAAAA_AAAA) &&
            (rs2_data_o === 32'hBBBB_BBBB)) begin

            $display("[PASS] Simultaneous read/write");

            pass_cnt++;

        end
        else begin

            $error(
                "[FAIL] Simultaneous read/write: rs1=%h rs2=%h",
                rs1_data_o,
                rs2_data_o
            );

            fail_cnt++;

        end

        we_i = 1'b0;

        // Also verify x15 was actually written
        check_read1(15, 32'hCCCC_CCCC);


        //========================================================
        // TEST 13
        // Write-first read-during-write
        //========================================================

        $display("\n========================================");
        $display("TEST 13: Write-first behavior");
        $display("========================================");

        // Old value
        write_reg(16, 32'h1111_1111);

        @(negedge clk_i);

        // Both read ports point to x16
        rs1_i = 16;
        rs2_i = 16;

        // Simultaneously write x16
        rd_i    = 16;
        wdata_i = 32'h2222_2222;
        we_i    = 1'b1;

        @(posedge clk_i);

        // Wait until NBA update + combinational read settle
        #1;

        if ((rs1_data_o === 32'h2222_2222) &&
            (rs2_data_o === 32'h2222_2222)) begin

            $display("[PASS] Write-first behavior");

            pass_cnt++;

        end
        else begin

            $error(
                "[FAIL] Write-first: rs1=%h rs2=%h",
                rs1_data_o,
                rs2_data_o
            );

            fail_cnt++;

        end

        we_i = 1'b0;


        //========================================================
        // TEST 14
        // x0 remains zero after activity
        //========================================================

        $display("\n========================================");
        $display("TEST 14: x0 remains zero");
        $display("========================================");

        check_read1(0, 32'h0000_0000);
        check_read2(0, 32'h0000_0000);


        //========================================================
        // TEST 15
        // Verify both read ports independently
        //========================================================

        $display("\n========================================");
        $display("TEST 15: Independent read verification");
        $display("========================================");

        rs1_i = 13;
        rs2_i = 15;

        #1;

        if ((rs1_data_o === 32'hAAAA_AAAA) &&
            (rs2_data_o === 32'hCCCC_CCCC)) begin

            $display("[PASS] Independent read verification");

            pass_cnt++;

        end
        else begin

            $error(
                "[FAIL] Independent reads: rs1=%h rs2=%h",
                rs1_data_o,
                rs2_data_o
            );

            fail_cnt++;

        end


        //========================================================
        // TEST 16
        // Different data patterns on both ports
        //========================================================

        $display("\n========================================");
        $display("TEST 16: Different data on both ports");
        $display("========================================");

        write_reg(17, 32'h0000_0000);
        write_reg(18, 32'hFFFF_FFFF);

        rs1_i = 17;
        rs2_i = 18;

        #1;

        if ((rs1_data_o === 32'h0000_0000) &&
            (rs2_data_o === 32'hFFFF_FFFF)) begin

            $display("[PASS] Different data on both ports");

            pass_cnt++;

        end
        else begin

            $error(
                "[FAIL] Different data: rs1=%h rs2=%h",
                rs1_data_o,
                rs2_data_o
            );

            fail_cnt++;

        end


        //========================================================
        // TEST SUMMARY
        //========================================================

        $display("\n");
        $display("========================================");
        $display("           TEST SUMMARY");
        $display("========================================");

        $display("PASS = %0d", pass_cnt);
        $display("FAIL = %0d", fail_cnt);

        if (fail_cnt == 0) begin

            $display("========================================");
            $display("        ALL TESTS PASSED");
            $display("========================================");

        end
        else begin

            $display("========================================");
            $display("        TEST FAILED");
            $display("========================================");

        end

        $finish;

    end


    //============================================================
    // Waveform Dump
    //============================================================

    initial begin

        $dumpfile("reg_file.vcd");
        $dumpvars(0, tb_reg_file);

    end

endmodule
