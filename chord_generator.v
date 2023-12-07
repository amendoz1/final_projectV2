`define NOTE_WIDTH 6
`define DURATION_WIDTH 6
`define META_WIDTH 3
`define PLAY_DENOTER 1

//STATE ASSIGNMENTS IF NECESSARY
`define RESET_STATE 3'b000
`define WAIT 3'b001
`define LOAD_FIRST 3'b010
`define LOAD_SECOND 3'b011
`define LOAD_THIRD  3'b100

module chord_generator(
    input clk,
    input reset, 
    input play_enable, // play_enable signal for note player
    input beat, //beat for ticking down duration
    input [5:0] note_to_load, duration_to_load, // note and duration from song_reader (loaded one at a time)
    input scheduler,
    input [2:0] metaData,
    input generate_next_sample, // output from codec to tell note_players to go on to the next sample
    input new_note, //output from songReader that tells us to load in a new note in one of our 3 notes
    output reg [5:0] note1,
    output reg [5:0] note2, 
    output reg [5:0] note3, //done
    output reg [5:0] duration1, 
    output reg [5:0] duration2, 
    output reg [5:0] duration3, //
    output[15:0] sample_out1, sample_out2, sample_out3, final_sample, //done
    output new_sample_ready1, new_sample_ready2, new_sample_ready3 //done
);



wire [2:0] state;
reg [2:0] next_state;

wire duration1_done;
wire duration2_done;
wire duration3_done;

wire actual_play_enable = (scheduler && play_enable);

dffr #(3) fsm(
    .clk(clk),
    .r(reset),
    .d(next_state),
    .q(state)
);

wire [2:0] prev_state;
wire [2:0] prevprev_state;

dffr #(3) prevfsm(
    .clk(clk),
    .r(reset),
    .d(state),
    .q(prev_state)
);

dffr #(3) prevprevfsm(
    .clk(clk),
    .r(reset),
    .d(prev_state),
    .q(prevprev_state)
);

// Assign what states/ which note player to load
always @(*) begin

   casex(state)
    
    `WAIT, `RESET_STATE :  // might need to revisit the inclusion of the load states as i do not believe we would want them to be able to transition back into themselves... not sure if thats possible though
    // depending on which note is done, then we move into the state that assigns the latest note to it
    if (duration1_done) 
    begin
        next_state = `LOAD_FIRST;
    end 
    else if (duration2_done) begin
        next_state = `LOAD_SECOND;
    end
    else if (duration3_done) begin
        next_state = `LOAD_THIRD;
    end
    // if none of the notes are done we remain in the wait state and do nothing 
    else begin
        next_state = `WAIT;
    end   
    
    `LOAD_FIRST:
    if (duration2_done) begin
        next_state = `LOAD_SECOND;
    end
    else if (duration3_done) begin
        next_state = `LOAD_THIRD;
    end
    else begin
        next_state = `WAIT;
    end
     
    `LOAD_SECOND:
    if (duration1_done) 
    begin
        next_state = `LOAD_FIRST;
    end 
        else if (duration3_done) begin
        next_state = `LOAD_THIRD;
    end
    // if none of the notes are done we remain in the wait state and do nothing 
    else begin
        next_state = `WAIT;
    end   
    
    `LOAD_THIRD:
    if (duration1_done) 
    begin
        next_state = `LOAD_FIRST;
    end 
    else if (duration2_done) begin
        next_state = `LOAD_SECOND;
    end
    else begin
        next_state = `WAIT;
    end   

    default : next_state = `WAIT;
    endcase
end


 //assign notes and durations
always @(*) begin
    casex(state)
    `WAIT : {note1, note2, note3, duration1, duration2, duration3} = {note1, note2, note3, duration1, duration2, duration3};
    `LOAD_FIRST : {note1, duration1} = (duration1_done) ? {note_to_load, duration_to_load}: {note1,duration1};
    `LOAD_SECOND : {note2, duration2} = (duration2_done)? {note_to_load, duration_to_load}: {note2, duration2};
    `LOAD_THIRD : {note3, duration3} = (duration3_done) ? {note_to_load, duration_to_load}: {note3,duration3};
    `RESET_STATE : {note1, note2, note3, duration1, duration2, duration3} = {6{6'd0}};
    default: {note1, note2, note3, duration1, duration2, duration3} = {6{6'd0}};
    endcase
end



//////Note Players
note_player np1(
    .clk(clk),
    .reset(reset),
    .play_enable(actual_play_enable),
    .note_to_load(note1),
    .duration_to_load(duration1),
    .load_new_note(new_note),
    .done_with_note(duration1_done),
    .beat(beat),
    .generate_next_sample(generate_next_sample),
    .sample_out(sample_out1),
    .new_sample_ready(new_sample_ready1),
    .load_new_enable(state == `LOAD_FIRST)
);

note_player np2(
    .clk(clk),
    .reset(reset),
    .play_enable(actual_play_enable),
    .note_to_load(note2),
    .duration_to_load(duration2),
    .load_new_note(new_note),
    .done_with_note(duration2_done),
    .beat(beat),
    .generate_next_sample(generate_next_sample),
    .sample_out(sample_out2),
    .new_sample_ready(new_sample_ready2),
    .load_new_enable(state == `LOAD_SECOND)
);

note_player np3(
    .clk(clk),
    .reset(reset),
    .play_enable(actual_play_enable),
    .note_to_load(note3),
    .duration_to_load(duration3),
    .load_new_note(new_note),
    .done_with_note(duration3_done),
    .beat(beat),
    .generate_next_sample(generate_next_sample),
    .sample_out(sample_out3),
    .new_sample_ready(new_sample_ready3),
    .load_new_enable(state == `LOAD_THIRD)
);

wire signed [15:0] a,b,c;
assign a = sample_out1;
assign b = sample_out2;
assign c = sample_out3;
assign final_sample = ((a>>>2) + (b>>>2)+(c>>>2));

endmodule
