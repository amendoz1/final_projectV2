//
//  music_player module
//
//  This music_player module connects up the MCU, song_reader, note_player,
//  beat_generator, and codec_conditioner. It provides an output that indicates
//  a new sample (new_sample_generated) which will be used in lab 5.
//

module music_player(
    // Standard system clock and reset
    input clk,
    input reset,

    // Our debounced and one-pulsed button inputs.
    input play_button,
    input next_button,

    // The raw new_frame signal from the ac97_if codec.
    input new_frame,

    // This output must go high for one cycle when a new sample is generated.
    output wire new_sample_generated,

    // Our final output sample to the codec. This needs to be synced to
    // new_frame.
    output wire [15:0] sample_out
);
    // The BEAT_COUNT is parameterized so you can reduce this in simulation.
    // If you reduce this to 100 your simulation will be 10x faster.
    parameter BEAT_COUNT = 1000;


//
//  ****************************************************************************
//      Master Control Unit
//  ****************************************************************************
//   The reset_player output from the MCU is run only to the song_reader because
//   we don't need to reset any state in the note_player. If we do it may make
//   a pop when it resets the output sample.
//
 
    wire play;
    wire reset_player;
    wire [1:0] current_song;
    wire song_done;
    mcu mcu(
        .clk(clk),
        .reset(reset),
        .play_button(play_button),
        .next_button(next_button),
        .play(play),
        .reset_player(reset_player),
        .song(current_song),
        .song_done(song_done)
    );

//
//  ****************************************************************************
//      Song Reader
//  ****************************************************************************
//
    wire [5:0] note_to_play;
    wire [5:0] duration_for_note;
    wire new_note;
    wire note_done;

    wire [5:0] note_to_play2;
    wire [5:0] duration_for_note2;
    wire new_note2;
    wire note_done2;

    wire [5:0] note_to_play3;
    wire [5:0] duration_for_note3;
    wire new_note3;
    wire note_done3;

    wire note_done_final = note_done || note_done2 || note_done3;
    song_reader song_reader(
        .clk(clk),
        .reset(reset | reset_player),
        .play(play),
        .song(current_song),
        .song_done(song_done),
        .note(note_to_play),
        .duration(duration_for_note),
        .new_note(new_note),
        .note_done(note_done_final)
    );

//   
//  ****************************************************************************
//      Note Player
//  ****************************************************************************
//  
    wire beat;
    wire generate_next_sample;
    wire [15:0] note_sample;
    wire note_sample_ready;

    wire generate_next_sample2;
    wire [15:0] note_sample2;
    wire note_sample_ready2;

    wire generate_next_sample3;
    wire [15:0] note_sample3;
    wire note_sample_ready3;

    wire note_sample_ready_final = note_sample | note_sample_ready2 | note_sample3;


    chord_generator generator_for_chords(
    .clk(clk),
    .reset(reset),
    .play_enable(play),
    .beat(beat),
    //.song(current_song),
    .note_to_load(note_to_play), 
    .duration_to_load(duration_for_note),
    .generate_next_sample(generate_next_sample),
    .new_note(new_note),
   // output one_note_is_done,
    // I dont think we need to ouptut the notes or duration note1, note2, note3, //done
    //output [5:0] duration1, duration2, duration3, //done
    .sample_out1(note_sample),
    .sample_out2(note_sample2),
    .sample_out3(note_sample3), //done
    .new_sample_ready1(note_sample_ready),
    .new_sample_ready2(note_sample_ready2),
    .new_sample_ready3(note_sample_ready3)  //done
    


    );

    // note_player note_player1(
    //     .clk(clk),
    //     .reset(reset),
    //     .play_enable(play),
    //     .note_to_load(note_to_play), //
    //     .duration_to_load(duration_for_note), //
    //     .load_new_note(new_note),
    //     .done_with_note(note_done), //
    //     .beat(beat),
    //     .generate_next_sample(generate_next_sample), //
    //     .sample_out(note_sample), //
    //     .new_sample_ready(note_sample_ready) //
    // );

    //     note_player note_player2(
    //     .clk(clk),
    //     .reset(reset),
    //     .play_enable(play),
    //     .note_to_load(note_to_play2), //
    //     .duration_to_load(duration_for_note2), //
    //     .load_new_note(new_note_final),
    //     .done_with_note(note_done2), //
    //     .beat(beat),
    //     .generate_next_sample(generate_next_sample2), //
    //     .sample_out(note_sample2), //
    //     .new_sample_ready(note_sample_ready2) //
    // );

    //     note_player note_player3(
    //     .clk(clk),
    //     .reset(reset),
    //     .play_enable(play),
    //     .note_to_load(note_to_play3), //
    //     .duration_to_load(duration_for_note3), //
    //     .load_new_note(new_note_final),
    //     .done_with_note(note_done3), //
    //     .beat(beat),
    //     .generate_next_sample(generate_next_sample3), //
    //     .sample_out(note_sample3), //
    //     .new_sample_ready(note_sample_ready3) //
    // );
      

    
    wire generate_next_sample_final = generate_next_sample | generate_next_sample2 | generate_next_sample3; // If one pulse must find a way to wait till the latest
    wire [15:0] note_sample_final =  note_sample>>>2 + note_sample2>>>2 + note_sample3>>>2; //divide by four to not be over idk how to dived by 3
//   
//  ****************************************************************************
//      Beat Generator
//  ****************************************************************************
//  By default this will divide the generate_next_sample signal (48kHz from the
//  codec's new_frame input) down by 1000, to 48Hz. If you change the BEAT_COUNT
//  parameter when instantiating this you can change it for simulation.
//  
    beat_generator #(.WIDTH(10), .STOP(BEAT_COUNT)) beat_generator(
        .clk(clk),
        .reset(reset),
        .en(generate_next_sample),
        .beat(beat)
    );

//  
//  ****************************************************************************
//      Codec Conditioner
//  ****************************************************************************
//  
    assign new_sample_generated = generate_next_sample;
    codec_conditioner codec_conditioner(
        .clk(clk),
        .reset(reset),
        .new_sample_in(note_sample_final),
        .latch_new_sample_in(note_sample_ready_final),
        .generate_next_sample(generate_next_sample_final),
        .new_frame(new_frame),
        .valid_sample(sample_out)
    );

endmodule