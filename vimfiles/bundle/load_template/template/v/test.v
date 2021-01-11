`timescale 1ns / 1ps
module test
(
    input                           clk                             ,       
    input                           rst                             ,       
    input                           start                           ,       
    input                           din                             ,       
    output                          dout                                   
);
    //this is only a .v template to test load-template 

    always@(posedge clk or posedge rst)begin
        if(rst)begin
             
        end
        else begin
             
        end
    end

endmodule
