/*
 * Minimum SPI support 8-bit read/write
 *
 * 2 clock cycle wasted for ead 
 * 
 */

`timescale 1ns / 1ps
module spi8 (
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


   //---------r/w----AAA-AAAA-DDDD-DDDD




   // 7 bit register address
   parameter [6:0] ad_read        = 7'b11111,
                   ad_r_reg00     = 7'b00000,
                   ad_r_reg01     = 7'b00001,
		   ad_r_reg02     = 7'b00010,
		   ad_r_reg03     = 7'b00011,
		   ad_r_reg04     = 7'b00100,
		   ad_r_reg05     = 7'b00101,
		   ad_r_reg06     = 7'b00110,
		   ad_r_reg07     = 7'b00111;
		   
   // registers

   reg [7:0]    r_reg00;    // 
   reg [7:0]    r_reg01;    // 
   reg [7:0]    r_reg02;    // 
   reg [7:0]    r_reg03;    // 
   reg [7:0]    r_reg04;    // 
   reg [7:0]    r_reg05;    // 
   reg [7:0]    r_reg06;    // 
   reg [7:0]    r_reg07;    // 

   reg [6:0]     r_addr ;        // address

   //shift register for a command frame write
   reg [15:0]    r_sh_in ;       // shift register for serial in
   
   //shift register for a command frame read
   reg [7:0]    r_sh_out ;      // shift register for serial out
   reg           r_out ;         // output register for serial out
   reg           r_read ;        // '1' = you can read now (from addressed reg)
   reg           r_write ;       // '1' = you can write now (to addressed reg)

   // bit cnt  16-bit 4bits
   reg [4:0]     bitcnt;      
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
	 bitcnt     <= 0 ;
     // add counter and tx_data for read
        
      end
      else if (SV_n) begin
              if (bitcnt == 4'd8) begin
               // read proces done  reset r/w status registers 
		 r_read  <= 0 ;
              end
              else /*if (bitcnt == 4'd16)*/  begin //disable length check
                 r_addr  <= r_sh_in[14:8] ;
		 r_write <= 1 ;
		 r_read  <= 0 ;
	      end
	   end //SV_n 
   end // always @

   

  //async reset for cnt 
   always @(negedge SV_n or negedge !rst_n ) begin 
      if (!rst_n || !SV_n) begin
       bitcnt<=0;
       end
   end


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
           else if (!SV_n & !r_read) //when not reading
                   r_sh_in <= { r_sh_in[14:0] , SI } ;
                   bitcnt  <= bitcnt +5'b0001;
    end // always @
  


   // determin read process starts  half clock offset
   always @(negedge SCLK  or negedge rst_n) begin
      if( !rst_n) begin
        r_addr <=0;
        r_read <=0;
        r_write<=0;
        bitcnt<=0;
      end
      else if (!SV_n && bitcnt == 4'd8 && r_sh_in[7]==1 ) begin
         r_addr  <= r_sh_in[6:0] ;  //read command 1AAA-AAAA-XXXX-XXXX
	 r_read  <= 1 ;
         r_write <= 0 ;
      end 
   end

   always @(posedge SCLK or negedge rst_n) begin
      if (!rst_n) begin
         r_sh_out <= 0 ;
        // r_out <= 0 ;
      end
      else if (r_read) begin
              case (r_addr) //[6:0] r_addr
	         ad_r_reg00     : {r_out, r_sh_out}  <=  {r_reg00, 1'b0} ;
	         ad_r_reg01     : {r_out, r_sh_out}  <=  {r_reg01, 1'b0} ;
	         ad_r_reg02     : {r_out, r_sh_out}  <=  {r_reg02, 1'b0} ;
	         ad_r_reg03     : {r_out, r_sh_out}  <=  {r_reg03, 1'b0} ;
	         ad_r_reg04     : {r_out, r_sh_out}  <=  {r_reg04, 1'b0} ;
	         ad_r_reg05     : {r_out, r_sh_out}  <=  {r_reg05, 1'b0} ;
	         ad_r_reg06     : {r_out, r_sh_out}  <=  {r_reg06, 1'b0} ;
	         ad_r_reg07     : {r_out, r_sh_out}  <=  {r_reg07, 1'b0} ;
	         default        : r_sh_out <= 0 ;
	      endcase // case(r_addr)
	   end // if (r_read ..
    end // always @
 
   always @(negedge SCLK or negedge rst_n) begin
      if (!rst_n) begin
         r_sh_out <= 0 ;
         r_out <= 0 ;
      end
     else  if (r_read ) begin
         { r_out , r_sh_out } <= { r_sh_out[7:0] , 1'b0 } ;
     end
   end //always


 
endmodule //spi
