module wave_display_tb ();
reg clk;
reg reset;
reg [10:0] x;
reg [9:0] y;
reg valid;
reg [7:0] read_value;
reg read_index;
wire [8:0] read_address;
wire valid_pixel;
wire [7:0] r;
wire [7:0] g;
wire [7:0] b;

wave_display hello(.clk(clk),.reset(reset),.x(x),.y(y),.valid(valid),.read_value(read_value),.read_index(read_index),.read_address(read_address),.valid_pixel(valid_pixel),.r(r),.g(g),.b(b));  // [0..1279]y,  // [0..1023]


always begin
    #5 clk = !clk;
end


initial begin
clk = 0;
reset =1;
read_index = 0;
valid = 1;
#10
reset=0;
#5
y=10'b0000001000;
x = 11'b00000000100;
read_value=8'b00000001;
#10
x = 11'b00000000000;
read_value=8'b10000001;
#10
x = 11'b01000000000;
read_value=8'b10000010;
#10
read_value = 8'b00000010;
x = 11'b01000000010;
#10
read_value = 8'b00001000;
x = 11'b01000000011;
#10
read_value = 8'b01001000;
x = 11'b01000000100;
#10
read_value = 8'b00010000;
x = 11'b01000000110;
#10
read_value = 8'b00000001;
x = 11'b01000001000;
$finish;







end
endmodule
