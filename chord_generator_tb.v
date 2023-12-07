module chord_generator_tb();

reg clk;
reg reset;
reg play_enable;
reg beat;
reg play;
reg [5:0] note_to_load;
reg [5:0] duration_to_load;
reg generate_next_sample;
reg new_note;
reg metaData;
reg scheduler;
reg toggle;
reg [1:0] load_notes_phase;
wire[15:0] sample_out1;
wire[15:0] sample_out2;
wire[15:0] sample_out3;
wire new_sample_ready1;
wire new_sample_ready2;
wire new_sample_ready3;


initial begin
    clk = 1'b1;
    reset = 1'b1;
    repeat (1) #5  clk = ~clk ;
    reset = 1'b0;
    forever #5 clk = ~clk;
end


initial forever begin
    beat = 1'b0;
    #40
    beat = 1'b1;
    #5;
end

// Might need to either edit the beat_generator or create a beat register where
// we have it beat at the same time as the cycle for testing purposes

 


chord_module dut(
    .clk(clk), .reset(reset), .load_notes_phase(load_notes_phase),
    .beat(beat), .note_in(note_to_load), .play(play), .toggle(toggle),
    .duration_in(duration_to_load), .scheduler(scheduler), .generate_next_sample(generate_next_sample),
   .sample1(sample_out1), .sample2(sample_out2),
    .sample3(sample_out3), .note_sample_ready1(new_sample_ready1), .note_sample_ready2(new_sample_ready2),
    .note_sample_ready3(new_sample_ready3)
);


initial begin
play = 1;
metaData = 3'b000;
scheduler = 0;
toggle = 0;
play_enable = 1;
load_notes_phase = 2'b01;
// Loading in the 3 notes of the first chord
generate_next_sample = 1;


#10
note_to_load = 6'd23;
duration_to_load = 6'd10;
#10

note_to_load = 6'd11;
duration_to_load = 6'd10;

#10

note_to_load = 6'd7;
duration_to_load = 6'd12;

#20

scheduler = 1;

// Wait for duration to count down based on beat
#100 // if beat = clk, we wait 10 cycles for there to be 10 beats which means all the signals are done

// Load in the notes for the next chord, this time with durations ending at different times
scheduler = 0;
note_to_load = 6'd50;
duration_to_load = 6'd20;
#10;

note_to_load = 6'd51;
duration_to_load = 6'd15;
#10

note_to_load = 6'd52;
duration_to_load = 6'd10;
#10
scheduler = 1;
#10
#100

scheduler = 0;
new_note = 1;
// this should change note3/dur3
note_to_load = 6'd10;
duration_to_load = 6'd80;
#10
new_note = 0;
scheduler = 1;
// this should change note2/dur2
#50
new_note = 1;
scheduler = 0;
note_to_load = 6'd11;
duration_to_load = 6'd85;
#10
new_note = 0;
scheduler = 1;
// this should change note1/dur1
#50
new_note = 1;
note_to_load = 6'd12;
duration_to_load = 6'd90;

end


endmodule