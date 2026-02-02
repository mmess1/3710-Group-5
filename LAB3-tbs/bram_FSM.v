module bram_FSM (
    input  wire         Clk,
    input  wire         Rst,
    input  wire [15:0]  q_a, // ram input 1
    input  wire [15:0]  q_b, // ram input 2

    output reg  [15:0]  data_a,
    output reg  [15:0]  data_b,
    output reg  [9:0]   addr_a,
    output reg  [9:0]   addr_b,
    output reg          we_a,		// wrie enable
    output reg          we_b,
    output reg          en_a,			// turn on ram block a
    output reg          en_b,

    output reg  [15:0]  bram_output
);

/*
Design a FSM wrapper that:




State: 1: read

- data ram1: q_a
- data ram2:q_b

- enable a (read)



State 2: Modify

add 1


State 3: Write

Output:

- adder_a, adder_b

- data_a, data_b

- enables ( only b )


State 4: re-read;

input: expected read add

output: enable (b)


State 5: stop --> display




1) Reads data from the above locations that was initialized to known values.
3) Modifies this data. E.g., you could fetch the data and increment it by a constant.
2) Re-writes the modified data in various locations (potentially the same locations) in memory;
1) Re-reads the data from memory and verifies that the correct updated data was read.
4) stop
– And finally, displays the updated data from one of those locations on the 7-Segment display
*/



    localparam s_init  = 4'd0; // Initial state
    localparam s_read  = 4'd1; // read from block 0 at addr
	 localparam s_modify = 4'd2; // modify data
    localparam s_write = 4'd3; // write q_a into block 1 at addr
	 localparam s_reread = 4'd4; 
	 
    localparam s_final = 4'd5; // read block 1 and display (cycle)

    reg [3:0] PS; // Present State
    reg [3:0] NS; // Next State

    reg [8:0] fib; // current fib index
    reg [8:0] fib_next; // next fib index
	 
	 
	 // updated memory value
	  reg  [15:0]  new_data;
	 

    always @(posedge Clk, negedge Rst) begin
        if (~Rst) begin
            PS   <= s_init;
            fib <= 9'd0;
        end else begin
            PS   <= NS;
            fib <= fib_next;
        end
    end

	 // increment by fib
    // Set Next State
    always @(*) begin
        NS        = PS;
        fib_next = fib;
        case (PS)
            s_init: begin
               // NS        = s_read;
                fib_next = 9'd0;
					 NS = (fib == 9'd11) ? s_final : s_read;

            end

            s_read: begin
                //NS = s_write;
					 fib_next = (fib == 9'd11) ? 9'd0 : (fib + 9'd1);
					 NS = s_modify;
            end

            s_modify: begin
                // NS        = (fib == 9'd11) ? s_final : s_read;
                fib_next = (fib == 9'd11) ? 9'd0 : (fib + 9'd1);
					 NS = s_write;
            end
				
				s_write: begin
                //NS        = (fib == 9'd11) ? s_final : s_read;
                fib_next = (fib == 9'd11) ? 9'd0 : (fib + 9'd1);
					 
					NS = s_reread;
            end

            s_reread: begin
                //NS        = s_final;
                fib_next = (fib == 9'd11) ? 9'd0 : (fib + 9'd1);
					 NS = s_final;
            end
				 s_final: begin
					 NS = s_final;
				end
            default: begin
                NS        = s_init;
                fib_next = 9'd0;
            end
        endcase
    end
	 
	 
/*
Design a FSM wrapper that:




State: 1: read

- data ram1: q_a
- data ram2:q_b

- enable a (read)



State 2: Modify

add 1


State 3: Write

Output:

- adder_a, adder_b 

- data_a, data_b

- enables ( only b )


State 4: re-read;

input: expected read add

output: enable (b)

*/

    // Set Outputs
    always @(*) begin
        data_a      = 16'd0;
        data_b      = 16'd0;
        addr_a      = 10'd0;
        addr_b      = 10'd0;
        we_a        = 1'b0;
        we_b        = 1'b0;
        en_a        = 1'b0;
        en_b        = 1'b0;
        bram_output = 16'd0;

        case (PS)
            s_init: begin
                bram_output = 16'd0;
            end

            s_read: begin // read fom A --> write to B
				
                en_a   = 1'b1; // enable a read
			  
                addr_a = {1'b0, fib}; // block 0
            end

		      s_modify: begin
					// modify data
					new_data = q_a + 1;
					data_b = new_data;
				
				end
				
            s_write: begin
				
				// read fom A --> write to B
				 en_b   = 1'b1; // enable b
             we_b   = 1'b1; //  enable write b
				 
				 en_a   = 1'b0; // dont enable read on 
					 
             addr_b = {1'b1, fib}; // block 1
			
             data_b = q_a; // new data
					 
            end

				
				s_reread: begin // reader again from B OR A
					
                en_a   = 1'b1; // enable A read
                addr_a = {1'b1, fib}; // block b --> Add == 512 + fib
					 
				end
				

            s_final: begin
                en_a        = 1'b1;
                we_a        = 1'b0;
                addr_a      = {1'b1, fib}; // block 1
                bram_output = q_a;
            end
        endcase
    end

endmodule
