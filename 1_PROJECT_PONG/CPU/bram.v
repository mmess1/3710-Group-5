// Quartus Prime Verilog Template
// True Dual Port RAM with single clock

module bram
#(parameter DATA_WIDTH=16, parameter ADDR_WIDTH=10, parameter DATA_FILE="")
(
	input [(DATA_WIDTH-1):0] data_a,
	input [(ADDR_WIDTH-1):0] addr_a,
	input we_a,
	input clk,
	input en_a,
	output reg [(DATA_WIDTH-1):0] q_a

	// Port B is disabled/commented out
	// input [(DATA_WIDTH-1):0] data_b,
	// input [(ADDR_WIDTH-1):0] addr_b,
	// input we_b, en_b,
	// output reg [(DATA_WIDTH-1):0] q_b
);

	// Declare the RAM variable
	reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];
	integer i;
	initial
	begin
		for(i=0;i<512;i=i+1)
			ram[i] = 0;

		if (DATA_FILE != "")
    	$readmemh(DATA_FILE, ram);
	end


    // Port A
    always @ (posedge clk) begin
        if (en_a) begin
            if (we_a) begin
                ram[addr_a] <= data_a;
                q_a <= data_a;
            end else begin
                q_a <= ram[addr_a];
            end
        end
    end

    // // Port B
    // always @ (posedge clk) begin
    //     if (en_b) begin
    //         if (we_b) begin
    //             ram[addr_b] <= data_b;
    //             q_b <= data_b;
    //         end else begin
    //             q_b <= ram[addr_b];
    //         end
    //     end
    // end

endmodule

module ram #(
	parameter DATA_WIDTH=16, parameter ADDR_WIDTH=10, parameter DATA_FILE0="", parameter DATA_FILE1="")
(
	input  [(DATA_WIDTH-1):0] data_a,
	// input  [(DATA_WIDTH-1):0] data_b, // Port B disabled
	input  [(ADDR_WIDTH-1):0] addr_a,
	// input  [(ADDR_WIDTH-1):0] addr_b, // Port B disabled
	input  we_a,
	// input  we_b, // Port B disabled
	input  clk,
	input  en_a
	// input  en_b // Port B disabled
	,output [(DATA_WIDTH-1):0] q_a
	// ,output [(DATA_WIDTH-1):0] q_b // Port B disabled
);

	localparam BLK_ADDR_WIDTH = ADDR_WIDTH-1;

	wire sel_a = addr_a[ADDR_WIDTH-1];
	// wire sel_b = addr_b[ADDR_WIDTH-1]; // Port B disabled

	wire [BLK_ADDR_WIDTH-1:0] addr_a_low = addr_a[BLK_ADDR_WIDTH-1:0];
	// wire [BLK_ADDR_WIDTH-1:0] addr_b_low = addr_b[BLK_ADDR_WIDTH-1:0]; // Port B disabled

	wire [DATA_WIDTH-1:0] q0_a; // q0_b disabled
	wire [DATA_WIDTH-1:0] q1_a; // q1_b disabled

	bram #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(BLK_ADDR_WIDTH), .DATA_FILE(DATA_FILE0)) bram0 (
		.data_a(data_a)
		// Port B signals disabled: .data_b(data_b),
		, .addr_a(addr_a_low)
		// , .addr_b(addr_b_low)
		, .we_a(we_a & ~sel_a)
		// , .we_b(we_b & ~sel_b) // only allow writes into block0 when sel=0
		, .clk(clk)
		, .en_a(en_a & ~sel_a)
		// , .en_b(en_b & ~sel_b) // only enable block0 when sel=0
		, .q_a(q0_a)
		// , .q_b(q0_b)
	);

	bram #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(BLK_ADDR_WIDTH), .DATA_FILE(DATA_FILE1)) bram1 (
	    .data_a(data_a), 
	    // .data_b(data_b),
	    .addr_a(addr_a_low), 
	    // .addr_b(addr_b_low),
	    .we_a(we_a & sel_a), 
	    // .we_b(we_b & sel_a), // only allow writes into block1 when sel=1
	    .clk(clk),
	    .en_a(en_a & sel_a), 
	    // .en_b(en_b & sel_a), // only enable block1 when sel=1
	    .q_a(q1_a)
		// .q_b(q1_b)
	);

	mux_2to1 mux_out_a(.in0(q0_a), .in1(q1_a), .sel(sel_a), .out(q_a));
	// mux_out_b and q_b disabled (Port B)

endmodule
