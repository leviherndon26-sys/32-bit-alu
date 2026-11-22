// 32-bit ALU
// Operations (op):
//   2'b00  ADD : result = a + b
//   2'b01  SUB : result = a - b
//   2'b10  SLL : result = a << b[4:0]   (shift left logical)
//   2'b11  SRL : result = a >> b[4:0]   (shift right logical)
//
// Flags:
//   zero     - result is 0
//   negative - result[31]
//   carry    - carry out of bit 31 (ADD), no-borrow (SUB: 1 when a >= b unsigned)
//   overflow - signed overflow (ADD/SUB only)

module ALU (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [1:0]  op,
    output reg  [31:0] result,
    output wire        zero,
    output wire        negative,
    output reg         carry,
    output reg         overflow
);

    localparam OP_ADD = 2'b00;
    localparam OP_SUB = 2'b01;
    localparam OP_SLL = 2'b10;
    localparam OP_SRL = 2'b11;

    // 33-bit results so bit 32 holds the carry out
    wire [32:0] add_ext = {1'b0, a} + {1'b0, b};
    wire [32:0] sub_ext = {1'b0, a} + {1'b0, ~b} + 33'd1;   // a - b = a + ~b + 1

    always @(*) begin
        // defaults (prevents latches)
        result   = 32'd0;
        carry    = 1'b0;
        overflow = 1'b0;

        case (op)
            OP_ADD: begin
                result   = add_ext[31:0];
                carry    = add_ext[32];
                overflow = (a[31] == b[31]) && (result[31] != a[31]);
            end
            OP_SUB: begin
                result   = sub_ext[31:0];
                carry    = sub_ext[32];
                overflow = (a[31] != b[31]) && (result[31] != a[31]);
            end
            OP_SLL: result = a << b[4:0];
            OP_SRL: result = a >> b[4:0];
        endcase
    end

    assign zero     = (result == 32'd0);
    assign negative = result[31];

endmodule