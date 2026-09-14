`timescale 1ns / 1ps
(* DONT_TOUCH = "TRUE", KEEP_HIERARCHY = "TRUE" *)
module ro_unit#(
    parameter stage = 3
    )(
    (* DONT_TOUCH = "true" *)input logic clk,
    input logic en,
    input logic rst,
(* DONT_TOUCH = "true" *)  output logic aout,
(* DONT_TOUCH = "true" *)  output logic bout,
(* DONT_TOUCH = "true" *)  output logic cout

    );
        //(* mark_debug = "true" *)
    (* KEEP = "true", DONT_TOUCH = "true" *) logic [stage-1:0] c_out;
    (* KEEP = "true", DONT_TOUCH = "true" *) logic [stage-1:0] c_not;
    (* KEEP = "true", DONT_TOUCH = "true" *) logic [stage-1:0] A_out;
    (* KEEP = "true", DONT_TOUCH = "true" *) logic [stage-1:0] B_out;
    
    genvar i;
    generate
        for (i = 0; i < stage; i++) begin: fred_gen
            logic c_in, a_in, b_in;
            logic xor_in, xor_result;
            
            if (i == 0) begin
            // Son stage'i başa geri bağladık
                (* DONT_TOUCH = "true" *)(* mark_debug = "true" *) assign c_in = en & c_not[stage - 1];
                (* DONT_TOUCH = "true" *)(* mark_debug = "true" *) assign b_in = ~A_out[stage - 1];
                (* DONT_TOUCH = "true" *)(* mark_debug = "true" *) assign a_in = ~B_out[stage - 1];
            end 
            else begin
                (* DONT_TOUCH = "true" *)(* mark_debug = "true" *) assign c_in = c_not[i - 1];
                (* DONT_TOUCH = "true" *)(* mark_debug = "true" *) assign b_in = A_out[i - 1];
                (* DONT_TOUCH = "true" *)(* mark_debug = "true" *) assign a_in = B_out[i - 1]; 
            end
            
            fred_gate fred(
            .c(c_in),
            .a(a_in),
            .b(b_in),
            .C(c_out[i]),
            .A(A_out[i]),
            .B(B_out[i])
            );
            
            (* DONT_TOUCH = "true" *)(* mark_debug = "true" *) assign c_not[i] = ~c_out[i];
        end
    endgenerate
    
    // ÖRNEKLEME FF'leri

//(* DONT_TOUCH = "true" *) logic [stage-1:0] samples;
(* KEEP = "true", DONT_TOUCH = "true" *) logic [stage-1:0] sample_buf_a;
(* KEEP = "true", DONT_TOUCH = "true" *) logic [stage-1:0] sample_buf_b;
(* KEEP = "true", DONT_TOUCH = "true" *) logic [stage-1:0] sample_buf_c;

(* DONT_TOUCH = "true" *)(* mark_debug = "true" *) assign sample_buf_a = A_out[stage-1];
(* DONT_TOUCH = "true" *)(* mark_debug = "true" *) assign sample_buf_b = B_out[stage-1];
(* DONT_TOUCH = "true" *)(* mark_debug = "true" *) assign sample_buf_c = c_out[stage-1];

//assign sample = sample_buf;

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        aout <= 0;
        bout <= 0;
        cout <= 0;
    end else begin
        (* DONT_TOUCH = "true" *)(* mark_debug = "true" *) aout <= sample_buf_a;
        (* DONT_TOUCH = "true" *)(* mark_debug = "true" *) bout <= sample_buf_b;
        (* DONT_TOUCH = "true" *)(* mark_debug = "true" *)cout <= sample_buf_c;

    end
    
end   


endmodule