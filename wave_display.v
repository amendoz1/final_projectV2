module wave_display (
    input clk,
    input reset,
    input [10:0] x,  
    input [9:0]  y,  
    input valid,
    input [7:0] read_value,
    input read_index,
    output wire [8:0] read_address,
    output wire valid_pixel,
    output wire [7:0] r,
    output wire [7:0] g,
    output wire [7:0] b
);


reg [8:0] read_addr;
assign read_address = read_addr;


always @(*) begin
    casex({x})
        11'b000xxxxxxxx: read_addr = {9'b000000000}; //should this be 9bits of x instead of read index + 7 dont care bits?
        11'b001xxxxxxxx: read_addr = {read_index, 1'b0, x[7:1]}; //I THINK IT SHOULD BE {read_index, 1'b0, x[7:1] } SINCE THE ADRESS IS SUPPPOSED TO BE 9 BITS
        11'b010xxxxxxxx: read_addr = {read_index, 1'b1, x[7:1]}; //SHOULDN'T THIS BE X[7:0] SINCE THE HANDOUT SAYS WE SHOULD BE USING 8 BITS FROM THE X? or it should be {read_index, 1'b1, x[7:1]}
        11'b011xxxxxxxx: read_addr = {9'b000000000} ; //should this be 9bits of x instead of read index + 7 dont care bits?
         default: read_addr =  {9'b000000000};
        endcase
    end
        

assign valid_pixel = ((x[10:0] >  11'b00100000010 && x[10:0] < 11'b01011111101) && ~y[9] && valid) ? 1'b1 : 1'b0;

wire [7:0] read_value_adj = (read_value >> 1)+ 6'd32;



wire [8:0] prev_addr;
dffr #(9) display_addr_flipflop(.clk(clk), .r(reset), .d(read_address), .q(prev_addr));


wire compare;
//ram value

//read ddre changes is the enable
reg [7:0] cur_ram;
wire [7:0] prev_ram;
wire [7:0] temp;
dffre #(8) rap(.clk(clk),.d(cur_ram),.q(prev_ram),.r(reset),.en(compare));
always @(*) begin
   // if(valid_pixel) begin
        cur_ram = read_value_adj; // what does this mean
   // end
end
assign compare = (read_address != prev_addr);

wire condition;
assign condition = (valid  &&( (y[8:1] <= cur_ram  && y[8:1] >= prev_ram) | (y[8:1]>= cur_ram  && y[8:1] <= prev_ram)));


wire [5:0] char_selection_q = 6'd18;
wire [7:0] tcgrom_d;
reg [7:0] color;

tcgrom tcgrom(.addr({char_selection_q, y[4:2]}), .data(tcgrom_d));

always @* begin     
        case (x[4:2])
            3'h0 : color = tcgrom_d[7];
            3'h1 : color = tcgrom_d[6];
            3'h2 : color = tcgrom_d[5];
            3'h3 : color = tcgrom_d[4];
            3'h4 : color = tcgrom_d[3];
            3'h5 : color = tcgrom_d[2];
            3'h6 : color = tcgrom_d[1];
            3'h7 : color = tcgrom_d[0];                            
        endcase 
    end  
    
//wire digi;
//assign digi = (valid && y[9]);

//// lets do 111111
//wire [2:0]xvar;
//assign xvar = x - 6'b1111111;
//wire [3:0]yvar;
//assign yvar = y - 6'b111111;
assign g =(condition)? 8'b11111111: 8'b0;
assign b =(condition)? 8'b11111111: 8'b0;
assign r =(condition)? 8'b11111111: 8'b0;

//wire [7:0]data; 
//tcgrom digdis(.addr(yvar),.data(data));
//assign r =(condition)? 8'b11111111:(digi ? (data[xvar]? 8'b11111111: 8'b0):8'b0);
endmodule