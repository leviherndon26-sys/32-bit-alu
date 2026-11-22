`timescale 1ns/1ns

module ALU_tb;

    reg  [31:0] a, b;
    reg  [1:0]  op;
    wire [31:0] result;
    wire        zero, negative, carry, overflow;

    // Waveform helpers (only for viewing in GTKWave)
    reg  [8*3-1:0] op_name;   // "ADD", "SUB", "SLL", "SRL" shown as text
    reg  [7:0]     test_num;  // which test is running
    reg            pass;      // 1 = this test passed

    integer errors = 0;

    localparam STEP = 10;     // each test lasts 10 ns in the waveform

    ALU dut (
        .a(a), .b(b), .op(op),
        .result(result), .zero(zero), .negative(negative),
        .carry(carry), .overflow(overflow)
    );

    always @(*) begin
        case (op)
            2'b00:   op_name = "ADD";
            2'b01:   op_name = "SUB";
            2'b10:   op_name = "SLL";
            2'b11:   op_name = "SRL";
            default: op_name = "???";
        endcase
    end

    task check;
        input [31:0] ta, tb;
        input [1:0]  top;
        input [31:0] expected;
        input        exp_c, exp_v;
        begin
            test_num = test_num + 1;
            a = ta; b = tb; op = top;
            #1;   // let the ALU settle, then check
            pass = (result === expected && carry === exp_c && overflow === exp_v &&
                    zero === (expected == 0) && negative === expected[31]);
            if (!pass) begin
                $display("FAIL #%0d %s a=%h b=%h -> result=%h c=%b v=%b z=%b n=%b (expected %h c=%b v=%b)",
                         test_num, op_name, ta, tb, result, carry, overflow, zero, negative,
                         expected, exp_c, exp_v);
                errors = errors + 1;
            end else begin
                $display("PASS #%0d %s a=%h b=%h -> result=%h c=%b v=%b z=%b n=%b",
                         test_num, op_name, ta, tb, result, carry, overflow, zero, negative);
            end
            #(STEP - 1);
        end
    endtask

    initial begin
        $dumpfile("ALU_tb.vcd");
        $dumpvars(1, ALU_tb);   // top level only: no ALU internals in the waveform

        test_num = 0;
        pass     = 1;

        // ADD
        check(32'd5,          32'd7,          2'b00, 32'd12,         0, 0);
        check(32'hFFFFFFFF,   32'd1,          2'b00, 32'd0,          1, 0); // carry, zero
        check(32'h7FFFFFFF,   32'd1,          2'b00, 32'h80000000,   0, 1); // signed overflow
        check(32'h80000000,   32'h80000000,   2'b00, 32'd0,          1, 1);

        // SUB
        check(32'd10,         32'd3,          2'b01, 32'd7,          1, 0);
        check(32'd3,          32'd10,         2'b01, 32'hFFFFFFF9,   0, 0); // negative
        check(32'd42,         32'd42,         2'b01, 32'd0,          1, 0); // zero
        check(32'h80000000,   32'd1,          2'b01, 32'h7FFFFFFF,   1, 1); // signed overflow

        // SLL
        check(32'd1,          32'd4,          2'b10, 32'd16,         0, 0);
        check(32'h0000000F,   32'd28,         2'b10, 32'hF0000000,   0, 0);
        check(32'hDEADBEEF,   32'd0,          2'b10, 32'hDEADBEEF,   0, 0);
        check(32'd1,          32'd31,         2'b10, 32'h80000000,   0, 0);
        check(32'd1,          32'd33,         2'b10, 32'd2,          0, 0); // only b[4:0] used

        // SRL
        check(32'h80000000,   32'd31,         2'b11, 32'd1,          0, 0);
        check(32'hF0000000,   32'd4,          2'b11, 32'h0F000000,   0, 0); // zero-fill
        check(32'd16,         32'd4,          2'b11, 32'd1,          0, 0);
        check(32'd1,          32'd1,          2'b11, 32'd0,          0, 0);

        if (errors == 0) $display("\nALL TESTS PASSED");
        else             $display("\n%0d TEST(S) FAILED", errors);
        $finish;
    end

endmodule
