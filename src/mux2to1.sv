module mux2to1 #(
    parameter WIDTH = 32
) (
    input      [WIDTH-1:0] in0,
    input      [WIDTH-1:0] in1,
    input                  sel,
    output logic [WIDTH-1:0] out
);

    assign out = sel ? in1 : in0;

endmodule
