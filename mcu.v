//module mcu(
//    input clk,
//    input reset,
//    input play_button,
//    input next_button,
//    input song_done,
//    output play,
//    output reset_player,
//    output [1:0] song
    
//);
    
//    reg [3:0] next_state;
//    wire [3:0] cur_state; //4 bits {play (1 bit), reset_player (1 bit), song (2 bits)}
//    dff #(4) ff(.clk(clk), .d(next_state), .q(cur_state));
    
//    assign play = cur_state[3]; //accesses MSB
//    assign reset_player = cur_state[2]; 
//    assign song = cur_state[1:0];
    
//    always @(*) begin
//        casex({play_button, next_button, song_done, reset})
//            4'bxxx1: next_state = {1'b0, 1'b1, 2'b00}; //if reset, pause system and returns to song 0, and set reset_player HIGH
//            4'bxx1x, 
//            4'bx1xx: next_state = {1'b0, 1'b1, cur_state[1:0]+1}; //if next_button pressed or song is done, pause at the start of the next song, and set reset_player HIGH
//            4'b1xxx: next_state = {~cur_state[3], 1'b0, cur_state[1:0]}; //play button toggles current play/pause
//            default: next_state = cur_state;
//        endcase
//    end
//endmodule



module mcu(
    input clk,
    input reset,
    input play_button,
    input next_button,
    input song_done,
    output play,
    output reset_player,
    output [1:0] song
);
    
    reg [3:0] next_state;
    wire [3:0] cur_state; //4 bits {play (1 bit), reset_player (1 bit), song (2 bits)}
    dff #(4) ff(.clk(clk), .d(next_state), .q(cur_state));
    
    assign play = cur_state[3]; //accesses MSB
    assign reset_player = cur_state[2]; 
    assign song = cur_state[1:0];
    
    always @(*) begin
        // Default assignments
        next_state[3] = cur_state[3];       // retain play state by default
        next_state[2] = 1'b0;               // reset_player defaults to 0
        next_state[1:0] = cur_state[1:0];   // retain current song by default

        // Reset logic
        if(reset) begin
            next_state = {1'b0, 1'b1, 2'b00}; // Reset
        end
        // Next song logic (either by next_button or song_done)
        else if(next_button || song_done) begin
            next_state[2] = 1'b1; // Set reset_player high
            next_state[3] = 1'b0;
            if(cur_state[1:0] == 2'b11) begin
                next_state[1:0] = 2'b00;  // Explicitly roll over
            end else begin
                next_state[1:0] = cur_state[1:0] + 1;
            end
        end 
        // Play button logic
        else if(play_button) begin
            next_state[3] = ~cur_state[3]; // Toggle play/pause
        end
    end
endmodule