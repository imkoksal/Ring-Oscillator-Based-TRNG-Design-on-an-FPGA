`timescale 1ns / 1ps

module fro_trng_array_top #(
    parameter int ro_num = 31,
    // Minimum 512-1024 cycles recommended to accumulate sufficient thermal jitter
    parameter int DECIMATION_FACTOR = 5,
    parameter int STAGE_ARRAY [0:30] = '{
        31, 17, 23, 19, 13,
        23, 13, 11, 29, 17,
        13, 29, 29, 31, 37,
        13, 17, 19, 23, 17,
        29, 11, 17, 19, 13,
        41, 17, 23, 13, 29,
        37
    }
)(
    (* DONT_TOUCH = "true" *) input  logic clk,       // 125 MHz onboard clock
    input  logic en,
    input  logic rst
    //output logic out,
    //output logic out_inv
);

    // -------------------------------------------------------------------------
    // Clocking & System Reset
    // -------------------------------------------------------------------------
    logic trng_sample_clk;
    logic clk_locked;

    // IMPORTANT: In the Clocking Wizard GUI, disable Spread Spectrum (SSCG)
    // and set Input Frequency explicitly to 125.000 MHz.
    clk_wiz_0 clk_gen_inst (
        .clk_in1(clk),
        .clk_out1(trng_sample_clk),
        .reset(rst),
        .locked(clk_locked)
    );

    // Hold internal logic in reset until PLL/MMCM is stable
    logic sys_rst;
    assign sys_rst = rst || (!clk_locked);

    // -------------------------------------------------------------------------
    // Ring Oscillator Array
    // -------------------------------------------------------------------------
    (* DONT_TOUCH = "true" *) logic [ro_num-1:0] ro_samples_a;
    (* DONT_TOUCH = "true" *) logic [ro_num-1:0] ro_samples_b;
    (* DONT_TOUCH = "true" *) logic [ro_num-1:0] ro_samples_c;

    genvar i;
    generate
        for (i = 0; i < ro_num; i++) begin: ro_row
            (* DONT_TOUCH = "TRUE" *)
            ro_unit #(
                .stage(STAGE_ARRAY[i])
            ) ro_inst (
                .clk(trng_sample_clk),
                .en(en),
                .rst(sys_rst), 
                .aout(ro_samples_a[i]),
                .bout(ro_samples_b[i]),
                .cout(ro_samples_c[i])
            );
        end
    endgenerate

    // Spatial XOR reduction tree across all rings
    (* DONT_TOUCH = "true" *) logic raw_entropy_bit;
    assign raw_entropy_bit = (^ro_samples_a) ^ (^ro_samples_b) ^ (^ro_samples_c);

    // -------------------------------------------------------------------------
    // Jitter Decimation Unit
    // -------------------------------------------------------------------------
    // Subsamples the XOR tree every DECIMATION_FACTOR cycles so that accumulated
    // jitter drifts significantly between successive captures.
    logic [15:0] decim_cnt;
    logic        decimated_strobe;
    logic        decimated_sample;

    always_ff @(posedge trng_sample_clk or posedge sys_rst) begin
        if (sys_rst) begin
            decim_cnt        <= 16'd0;
            decimated_strobe <= 1'b0;
            decimated_sample <= 1'b0;
        end else begin
            if (decim_cnt >= (DECIMATION_FACTOR - 1)) begin
                decim_cnt        <= 16'd0;
                decimated_strobe <= 1'b1;
                decimated_sample <= raw_entropy_bit;
            end else begin
                decim_cnt        <= decim_cnt + 1'b1;
                decimated_strobe <= 1'b0;
            end
        end
    end

    // -------------------------------------------------------------------------
    // Von Neumann Debiasing / Whitening Filter
    // -------------------------------------------------------------------------
    // Takes consecutive non-overlapping bit pairs (b0, b1):
    // 2'b01 -> 1'b0
    // 2'b10 -> 1'b1
    // 2'b00, 2'b11 -> discarded
    logic vn_toggle;
    logic vn_prev_bit;
    logic vn_valid;
    logic vn_bit;

    always_ff @(posedge trng_sample_clk or posedge sys_rst) begin
        if (sys_rst) begin
            vn_toggle   <= 1'b0;
            vn_prev_bit <= 1'b0;
            vn_valid    <= 1'b0;
            vn_bit      <= 1'b0;
        end else begin
            vn_valid <= 1'b0; // Default pulse
            if (decimated_strobe) begin
                vn_toggle <= ~vn_toggle;
                if (!vn_toggle) begin
                    // First bit of the pair
                    vn_prev_bit <= decimated_sample;
                end else begin
                    // Second bit of the pair: evaluate transition
                    if (vn_prev_bit == 1'b0 && decimated_sample == 1'b1) begin
                        vn_bit   <= 1'b0;
                        vn_valid <= 1'b1;
                    end else if (vn_prev_bit == 1'b1 && decimated_sample == 1'b0) begin
                        vn_bit   <= 1'b1;
                        vn_valid <= 1'b1;
                    end
                end
            end
        end
    end

    // -------------------------------------------------------------------------
    // Non-Overlapping 32-Bit Word Collector
    // -------------------------------------------------------------------------
    (* DONT_TOUCH = "true" *)(* mark_debug = "true" *) logic [31:0] shift_reg_word;
    (* DONT_TOUCH = "true" *)(* mark_debug = "true" *) logic        valid;
    logic [4:0]  bit_fill_cnt;
    logic [31:0] temp_shift;

    always_ff @(posedge trng_sample_clk or posedge sys_rst) begin
        if (sys_rst) begin
            shift_reg_word <= 32'h0;
            temp_shift     <= 32'h0;
            bit_fill_cnt   <= 5'd0;
            valid          <= 1'b0;
        end else begin
            valid <= 1'b0; // Single-cycle strobe

            if (vn_valid) begin
                temp_shift <= {temp_shift[30:0], vn_bit};

                if (bit_fill_cnt == 5'd31) begin
                    shift_reg_word <= {temp_shift[30:0], vn_bit};
                    valid          <= 1'b1; // Exactly 32 fresh bits assembled
                    bit_fill_cnt   <= 5'd0;
                end else begin
                    bit_fill_cnt   <= bit_fill_cnt + 1'b1;
                end
            end
        end
    end
    
        // -------------------------------------------------------------------------
        // Top Outputs & Debug Core
        // -------------------------------------------------------------------------
    // assign out     = shift_reg_word[0];
    // assign out_inv = ~shift_reg_word[0];

    // Trigger your ILA on (valid == 1) to capture exclusively fresh 32-bit words
    ila_0 ila_ip (
        .clk(trng_sample_clk),
        .probe0(valid),           // 1-bit strobe
        .probe1(shift_reg_word)   // 32-bit complete word
    );

endmodule
