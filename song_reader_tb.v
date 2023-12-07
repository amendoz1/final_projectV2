module song_reader_tb();

    reg clk, reset, play, note_done;
    reg [1:0] song;
    wire [5:0] note;
    wire [5:0] duration;
    wire song_done, new_note;

    song_reader dut(
        .clk(clk),
        .reset(reset),
        .play(play),
        .song(song),
        .song_done(song_done),
        .note(note),
        .duration(duration),
        .new_note(new_note),
        .note_done(note_done)
    );

    // Clock and reset
    initial begin
        clk = 1'b0;
        reset = 1'b1;
        repeat (3)#5 clk = ~clk;
        reset = 1'b0;
        forever #5 clk = ~clk;
    end

    // Tests
    initial begin
        // First Block of Tests: Tests most basic case: playing music throughout with a high note_done signal on every other clock cycle // CONSISTENT
        #15
        play = 0;
        note_done=0;
        song = 2'b00;
        #30
        note_done = 1;
        play = 1;
        #10 
        note_done = 0;
        #10
        note_done = 1;
        #10
        note_done = 0;
        #10
        note_done = 1;
        #10
        note_done = 0;
        //  Second block of tests: Test extended periods of note_done being 0 ... CONSISTENT
        #10
        note_done = 1;
        #20
        note_done = 0;
        #20
        note_done = 1;
        #10
        note_done = 0;
        #30
        note_done = 1;
        // Third Block of Tests: Pausing
        #10 
        note_done = 0;
       #10
       note_done = 1;
       play = 0;
       #10
       note_done = 0;
       
       #20
       play = 1;
       #10
       note_done = 1;
       #30
       $finish;
        
//        note_done = 0;
//        #duration
       
//        play = 1;
        
        
//        note_done = 1;
//        note_done = 0;
//        #duration
//        note_done = 1;

//        note_done = 0;
//        #duration
//        note_done = 1;

//        note_done = 0;
//        #duration
//        note_done = 1;

//        note_done = 0;
//        #duration
//        note_done = 1;

//        note_done = 0;
//        #duration
//        note_done = 1;

//        note_done = 0;
//        #duration
//        play = 0;
        
        
        
        

    end

endmodule
