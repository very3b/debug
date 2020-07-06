/*
 * Minimum SPI test for write only
 *
 * 
 * 
 */
module spi (
   // Interfacing pads
   input rst_n,                            // common reset for PLL
   input SCLK, 
   input SI, 
   input SV_n, 
   output SO,               // SPI ports
   // interfacing core
   //
   output [7:0] reg00, 
   output [7:0] reg01, 
   output [7:0] reg02, 
   output [7:0] reg03, 
   output [7:0] reg04, 
   output [7:0] reg05, 
   output [7:0] reg06, 
   output [7:0] reg07 
   );


   //---------r/w----AAAA---DDD-DDDD-DDDD




   // register address
   parameter [4:0] ad_read        = 5'b11111,
                   ad_r_reg00     = 5'b00000,
                   ad_r_reg01     = 5'b00001,
		   ad_r_reg02     = 5'b00010,
		   ad_r_reg03     = 5'b00011,
		   ad_r_reg04     = 5'b00100,
		   ad_r_reg05     = 5'b00101,
		   ad_r_reg06     = 5'b00110,
		   ad_r_reg07     = 5'b00111;
		   
   // registers

   reg [7:0]    r_reg00;    // 
   reg [7:0]    r_reg01;    // 
   reg [7:0]    r_reg02;    // 
   reg [7:0]    r_reg03;    // 
   reg [7:0]    r_reg04;    // 
   reg [7:0]    r_reg05;    // 
   reg [7:0]    r_reg06;    // 
   reg [7:0]    r_reg07;    // 

   reg [4:0]     r_addr ;        // address
   reg [15:0]    r_sh_in ;       // shift register for serial in
   reg [15:0]    r_sh_out ;      // shift register for serial out
   reg           r_out ;         // output register for serial out
   reg           r_read ;        // '1' = you can read now (from addressed reg)
   reg           r_write ;       // '1' = you can write now (to addressed reg)

   reg [2:0]     cnt;       // '1' = you can write now (to addressed reg)
   // assign register values to output ports
   assign SO = r_out ;

   assign reg00= r_reg00;
   assign reg01= r_reg01;
   assign reg02= r_reg02;
   assign reg03= r_reg03;
   assign reg04= r_reg04;
   assign reg05= r_reg05;
   assign reg06= r_reg06;
   assign reg07= r_reg07;

   // address resiter
   always @(posedge SV_n or negedge rst_n) begin
      if (!rst_n) begin
         r_addr  <= 0 ;
	 r_read  <= 0 ;
	 r_write <= 0 ;
     // add counter and tx_data for read
        
      end
      else if (SV_n) begin
              if (r_sh_in[15:11] == 5'b11111) begin
                 r_addr  <= r_sh_in[4:0] ;  //read command 11111-000-000A-AAAA
		 r_read  <= 1 ;
		 r_write <= 0 ;
              end
              else  begin
                 r_addr  <= r_sh_in[15:11] ;
		 r_write <= 1 ;
		 r_read  <= 0 ;
	      end
	   end
   end // always @
   
   
   // write to addressed registers (from serial-in reg)
   // Also, shift input register for serial-in
   always @(posedge SCLK or negedge rst_n) begin
      if (!rst_n) begin
         r_reg00 <=0;
         r_reg01 <=0;
         r_reg02 <=0;
         r_reg03 <=0;
         r_reg04 <=0;
         r_reg05 <=0;
         r_reg06 <=0;
         r_reg07 <=0;
         r_sh_in <= 0;
      end // end (!rst_n)
      else if (r_write && SV_n) begin
              case (r_addr)
	         ad_r_reg00     : r_reg00     <= r_sh_in[7:0] ;
	         ad_r_reg01     : r_reg01     <= r_sh_in[7:0] ;
	         ad_r_reg02     : r_reg02     <= r_sh_in[7:0] ;
	         ad_r_reg03     : r_reg03     <= r_sh_in[7:0] ;
	         ad_r_reg04     : r_reg04     <= r_sh_in[7:0] ;
	         ad_r_reg05     : r_reg05     <= r_sh_in[7:0] ;
	         ad_r_reg06     : r_reg06     <= r_sh_in[7:0] ;
	         ad_r_reg07     : r_reg07     <= r_sh_in[7:0] ;
	         default        : ;
	      endcase // case(r_addr)
           end // if (r_write ..
           else if (!SV_n) // not write low
                   r_sh_in <= { r_sh_in[14:0] , SI } ;
    end // always @
   
   // read from addressed registers (to serial-out reg)
   // Also, shift output register for serial-out
   always @(posedge SCLK or negedge rst_n) begin
      if (!rst_n) begin
         r_sh_out <= 0 ;
         r_out <= 0 ;
      end
      else if (r_read && SV_n) begin
              case (r_addr)
	         ad_r_reg00     : r_sh_out <= { 3'd0 , r_reg00} ;
	         ad_r_reg01     : r_sh_out <= { 3'd0 , r_reg01} ;
	         ad_r_reg02     : r_sh_out <= { 3'd0 , r_reg02} ;
	         ad_r_reg03     : r_sh_out <= { 3'd0 , r_reg03} ;
	         ad_r_reg04     : r_sh_out <= { 3'd0 , r_reg04} ;
	         ad_r_reg05     : r_sh_out <= { 3'd0 , r_reg05} ;
	         ad_r_reg06     : r_sh_out <= { 3'd0 , r_reg06} ;
	         ad_r_reg07     : r_sh_out <= { 3'd0 , r_reg07} ;
	         default        : r_sh_out <= 0 ;
	      endcase // case(r_addr)
	   end // if (r_read ..
           else if (!SV_n)
                   { r_out , r_sh_out } <= { r_sh_out[15:0] , 1'b0 } ;
    end // always @
 
endmodule //spi
