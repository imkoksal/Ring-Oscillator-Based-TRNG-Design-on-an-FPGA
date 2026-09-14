`timescale 1ns / 1ps

module fred_gate(
    input logic c,
    input logic a,
    input logic b,
    output logic C,
    output logic A,
    output logic B
    );

(* KEEP = "true", DONT_TOUCH = "true" *)assign C = c;
(* KEEP = "true", DONT_TOUCH = "true" *)assign A = (~c & a) | (c & b);
(* KEEP = "true", DONT_TOUCH = "true" *)assign B = (c & a) | (~c & b);

endmodule