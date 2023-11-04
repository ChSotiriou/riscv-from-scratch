module bench();
   reg CLK;
   wire RESET = 1; 
   wire [4:0] LEDS;

   SOC uut(
     .clk_12M(CLK),
     .rst(RESET),
     .leds(LEDS)
   );

   reg[4:0] prev_LEDS = 0;
   initial begin
      CLK = 0;
      forever begin
	 #1 CLK = ~CLK;
	 if(LEDS != prev_LEDS) begin
	   //  $display("LEDS = %b",LEDS);
	 end
	 prev_LEDS <= LEDS;
      end
   end
endmodule