`define ARMED 3'b001
`define ACTIVE 3'b010
`define WAIT 3'b100

module wave_capture (
    input clk,
    input reset,
    input new_sample_ready,
    input [15:0] new_sample_in,
    input wave_display_idle, //when high, flip RAM writing section and move from wait to armed
    output wire [8:0] write_address,
    output wire write_enable,
    output wire [7:0] write_sample,
    output wire read_index 
);
// internal signals
wire [2:0] state;
reg [2:0] next_state;
wire [7:0] count;
reg[7:0] next_count;
reg final_sample_written;
wire pos_zero_cross;
reg [8:0] temp_address;
wire [15:0] intermediate_sample;
wire [15:0] previous_sample;
reg [7:0] temp_written;
reg temp_enable_in;

dff  #(3) ffState(.clk(clk), .d(next_state), .q(state)); // FF for state 

dffre ffIndex (.clk(clk), .d(~read_index), .q(read_index), .r(reset), .en(wave_display_idle && state == `WAIT)); // FF for changing the index


always @(*) begin
// state logic and address logic
    casex({reset, state})
    4'b1xxx : {next_state, temp_address} = {`ARMED, 9'b0};  //temp_address should be specified in all cases
    4'b0001: {next_state, temp_address} = {{pos_zero_cross ? `ACTIVE : `ARMED}, temp_address}; //armed
    4'b0010: {next_state, temp_address} = {{final_sample_written ? `WAIT : `ACTIVE}, {read_index, count} };     //active
    4'b0100: {next_state, temp_address} = { {wave_display_idle ? `ARMED : `WAIT}, temp_address };    //wait
    default: {next_state, temp_address} = {`ARMED, 9'd0};    
    endcase
    
    //counter logic for when we are in active state
    casex({reset, state})
    4'b1xxx : {next_count, final_sample_written} = {8'd0, 1'b0};
    4'b0001 : {next_count, final_sample_written} = {8'd0, 1'b0};
    4'b0010 : 
    if (count == 8'd255)
        begin
            next_count = 8'd0;
            final_sample_written = 1'b1;
        end
        else begin
            next_count = count + 1;
            final_sample_written = 1'b0;
        end 
    4'b0100: {next_count, final_sample_written} = {next_count, 1'b0};    
    endcase
    
    // write_sample logic for when we are in active state + write_enable logic
    casex({reset, state})
    4'b1xxx :   {temp_written, temp_enable_in} = {8'd0, 1'b0};
    4'b0010:   {temp_written, temp_enable_in} = {new_sample_in[15:8] + 8'd128, 1'b1}; // shift 8 MSB of sample up to have only positive values
    default:   {temp_written, temp_enable_in} = {8'd0, 1'b0};
    endcase
end
    
dffre #(8) ffCount(.clk(clk), .d(next_count), .q(count), .r(1'b0), .en(new_sample_ready));  // ff for counter in active state

// assignment of write_address to internal register
assign write_address = temp_address;

// pos zero cross logic
dffre #(16) sampleFF1(.clk(clk), .d(new_sample_in), .q(previous_sample), .r(reset), .en(~new_sample_ready)); // FF for holding a previous sample for comparison. for positve zero cross purposes
assign pos_zero_cross =  (new_sample_in[15] != 1'b1 && previous_sample[15] == 1'b1); // current sample should be positive, previous sample should be negative


//assignment of write_sample to internal register
assign write_sample = temp_written;

//assignemnt of write_enable to internal register and new_sample_ready
assign write_enable = temp_enable_in && new_sample_ready;
endmodule