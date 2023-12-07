`define SONG_WIDTH 4
`define NOTE_WIDTH 6
`define DURATION_WIDTH 6
`define META_DATA 3

// ----------------------------------------------
// Define State Assignments
// ----------------------------------------------
`define SWIDTH 3
`define PAUSED             3'b000
`define WAIT               3'b001
`define INCREMENT_ADDRESS  3'b010
`define RETRIEVE_NOTE      3'b011
`define NEW_NOTE_READY     3'b100


module song_reader(
    input clk,
    input reset,
    input beat,
    input play,
    input [1:0] song,
    input note_done,
    output wire song_done,
    output  [5:0] note,
    output  [5:0] duration,
    //output  [5:0] wait_duration,
    output  scheduler,
    output wire new_note
);
    wire [`SONG_WIDTH-1:0] curr_note_num, next_note_num;
    wire [15:0] note_and_duration;
//    wire [`SONG_WIDTH + 1:0] rom_addr = {song, curr_note_num};
    wire [`SONG_WIDTH + 1:0] rom_addr = {song, curr_note_num};
    wire [5:0] wait_duration;
    wire [`SWIDTH-1:0] state;
    reg  [`SWIDTH-1:0] next;

    // For identifying when we reach the end of a song
    wire overflow;
    
    // count signals for the wait counter
    wire [5:0] count;
    wire [5:0] next_count;
    wire wait_done;
    
    // temp registers for outputs... not sure if i need them. i thought it would be weird for the outputs to loop back into the song reader for the wait logic...
//    reg [5:0] temp_note;
//    reg [5:0] temp_duration;
//    reg [5:0] temp_wait_duration;
//    reg temp_scheduler;
    
    
    // might be a good idea to add enable, since we only want to move on to the next note if the MSB of the ram output is 0 or if its 1, if we're done counting
    dffr #(`SONG_WIDTH) note_counter (
        .clk(clk),
        .r(reset),
        .d(next_note_num),
        .q(curr_note_num)
    );
    
    dffr #(`SWIDTH) fsm (
        .clk(clk),
        .r(reset),
        .d(next),
        .q(state)
    );
    
    dffre #(6) wait_counter (
        .clk(clk),
        .r(reset || wait_done),
        .d(count + 1),
        .q(count),
        .en(scheduler == 1 && state == `WAIT && beat)
        
    );
    
    assign wait_done = (count == wait_duration); // duration is part of the output of the ram when we have a wait note, can i have it 

    song_rom rom(.clk(clk), .addr(rom_addr), .dout(note_and_duration));

    always @(*) begin
        case (state)
            `PAUSED:            next = play ? `RETRIEVE_NOTE : `PAUSED;
            `RETRIEVE_NOTE:     next = play ? `NEW_NOTE_READY : `PAUSED;
            `NEW_NOTE_READY:    next = play ? `WAIT: `PAUSED;
            
            // im thinking our scheduler should affect because if its 1 we should just be waiting x amount of time until we increment addresses (start retreiving the next note)
            `WAIT:            
             if (!play) begin
                next = `PAUSED;
             end
             
             else if (note_done && scheduler == 0)begin
                next = `INCREMENT_ADDRESS;
             end
             
             else if (wait_done && scheduler == 1) begin
                next = `INCREMENT_ADDRESS;
             end 
             else begin
                next = `WAIT;
             end
             
            `INCREMENT_ADDRESS: next = (play && ~overflow) ? `RETRIEVE_NOTE
                                                           : `PAUSED;
            default:            next = `PAUSED;
        endcase
    end

    assign {overflow, next_note_num} =
        (state == `INCREMENT_ADDRESS) ? {1'b0, curr_note_num} + 1
                                      : {1'b0, curr_note_num};
    assign new_note = (state == `NEW_NOTE_READY);
    
    // assign temp outputs based on if we have a wait note or real note
//    always @(*) begin
//        casex(note_and_duration)
//        16'b0000000001xxxxxx:
//            {temp_note, temp_duration, temp_scheduler, temp_wait_duration} = {6'b000000, 6'b000000, 1'b1, note_and_duration[5:0]};
       
//        default:
//            {temp_note, temp_duration, temp_scheduler, temp_wait_duration} = {note_and_duration[14:9], note_and_duration[8:3], 1'b0, 6'b000000}; 
//        endcase
//    end
    
    
    assign scheduler = note_and_duration[15];
    assign note = note_and_duration[14:9];
    assign duration = note_and_duration[8:3];
    assign wait_duration = (scheduler) ? note_and_duration[8:3]: 1'b1;
     
    assign song_done = overflow;
    
    
//    assign note = temp_note;
//    assign duration = temp_duration;
//    assign wait_duration = temp_wait_duration;
//    assign scheduler = temp_scheduler;
  
endmodule