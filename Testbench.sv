/*
Interface signals for the Design, Golden modules 
*/
interface simplebus (input logic clock,reset,input [63:0]data_in,input [7:0]ecc_in);
   logic  [63:0] data_out;
   logic  [63:0] data_out_exp;
   logic  [1:0]  error_flag;
   logic  [1:0]  error_flag_exp;
  
 modport ecc (input  data_in,
              input  ecc_in,
			  output data_out,
			  output error_flag,
			  input clock,
			  input reset);
			  
 modport golden_ecc (input  data_in,
					 input  ecc_in,
					 output data_out_exp,
					 output error_flag_exp,
					 input clock,
					 input reset);
			  
endinterface

module top;

parameter PERIOD=10;

logic [63:0] data_in;
logic [63:0] data_out;
logic [7:0] ecc_in,ecc1;
bit clock ='1;
bit Error ='0;
bit reset ;
logic [1:0] error_flag;

logic [63:0]data_out_exp,data_in_exp; 
logic [1:0]error_flag_exp;
logic [7:0]ecc_in_exp; 

simplebus bus(.*);
encoder   e  (bus.ecc);
golden    g  (bus.golden_ecc);

always #(PERIOD/2) clock=~clock;

/*
Function to generate the ECC bits
*/
function logic [7:0] ecc_generate (input [63:0] data_in);
 
logic [7:0]R;

logic[71:1]func_dbits_codeword,func_eccbits_codeword;


int bit_count;  //information vector bit index

    //Information bits are stored in non-power-of-2 locations
begin
    //clear all bits
    func_dbits_codeword = 0;

	bit_count=0;
    for (int cw_count=1; cw_count<72; cw_count++) 
	begin
		if (2**$clog2(cw_count) != cw_count)
			func_dbits_codeword[cw_count] = data_in[bit_count++];
	end

   
     
    for (int p_count =1; p_count <=7; p_count++)  //parity-index
	begin
		R[p_count]=1'b0;
		for (int cw_count=1; cw_count<72; cw_count++) //codeword-index
		begin
			if (|(2**(p_count-1) & cw_count))
			begin
			R[p_count] = ((R[p_count])^(func_dbits_codeword[cw_count]));
			end
		end
	end
 

    //databits don't change ... copy into codeword
    func_eccbits_codeword  = func_dbits_codeword;

    //put parity vector at power-of-2 locations
    for (int i=1; i<72; i=i+1)
	begin
      func_eccbits_codeword[2**(i-1)] = R[i];
    end

   
     //calculating even parity R0
//          R[0] = ^func_eccbits_codeword;
    R[0] = (^data_in[63:0]);
    return (R);
         
end        
endfunction

/*
A functon to generate a single bit error
*/

function logic [63:0] err_data(input  [31:0]data1,data2, input  [5:0]n_bits);
	logic [63:0]err_data_buffer;
	err_data_buffer={data2,data1};
	
	foreach (err_data_buffer[i])
		if(i==n_bits)	err_data[n_bits]=~err_data_buffer[n_bits];
		else			err_data[i]=err_data_buffer[i];

endfunction

/*
A function to generate a double bit error.
*/

function logic [63:0] double_error(input  [31:0]data1,data2, input  [5:0]n_bits);
	logic [63:0]err_data_buffer;
	err_data_buffer={data2,data1};
	
	foreach (err_data_buffer[i])
		if(n_bits==6'h3F)
		begin
			if      (n_bits==i)			double_error[n_bits]=~err_data_buffer[n_bits];
			else if (n_bits-1==i)	    double_error[i]=~err_data_buffer[i];
			else					    double_error[i]=err_data_buffer[i];
		end
		else
		begin
			if      (n_bits==i)			double_error[n_bits]=~err_data_buffer[n_bits];
			else if (n_bits+1==i) 	    double_error[i]=~err_data_buffer[i];
			else					    double_error[i]=err_data_buffer[i];
		end

endfunction

/*
The Class datatype consists of randomization of data 
Weighted distribution has assigned to generate zero, single, Double bit error.
Coverage bins has been used to verify all the corner cases has been covered or not. 
*/

class no_error;
	randc logic [63:32]data2;
	randc logic [31:0]data1;
	randc logic [5:0]n_bits;
	typedef enum {ZERO, SINGLE, DOUBLE} mode;
	randc mode error_mode;
	bit [31:0] w_zero=21, w_single=70, w_double=9;
	
	  
	constraint c_len{
		error_mode dist { ZERO	:= w_zero,
			              SINGLE:= w_single, 
	  		              DOUBLE:= w_double};}  	

    covergroup cg;
        d2   : coverpoint data2
					{
					bins D2_0 = {'1};
					bins D2_1 = {'0};
					bins D2_2 = {8'hAAAAAAAA};
					bins D2_3 = {8'h55555555};
					}
		d1   : coverpoint data1	
					{
					bins D1_0 = {'1};
					bins D1_1 = {'0};
					bins D1_2 = {8'hAAAAAAAA};
					bins D1_3 = {8'h55555555};
					}
		bits : coverpoint n_bits
					{
					bins n0 = {2,5};
					bins n1 = {[8:15]};
					}
		error: coverpoint error_mode;
		cros : cross d2,d1;
	 
    endgroup			
endclass

/*
Task for the inputs based on the randomization of modes in the class datatype.
*/

task error_inject(no_error n1);
begin
	automatic int ZERO=0;
	automatic int SINGLE=1;
	automatic int DOUBLE=2;
	assert(n1.randomize());
//	$display("***time= %t****** e1.error_mode=%s",$time,e1.error_mode);
    assert(n1.randomize());
	if(n1.error_mode== ZERO)
	begin
		@(negedge clock)
		data_in={n1.data2,n1.data1};
		data_in_exp=data_in;
		ecc_in = ecc_generate({n1.data2,n1.data1});
		ecc_in_exp=ecc_in;
	end
	else if(n1.error_mode== SINGLE)
	begin

		@(negedge clock);
		data_in=err_data(n1.data1,n1.data2,n1.n_bits);
		data_in_exp=data_in;
		ecc_in=ecc_generate({n1.data2,n1.data1});
		ecc_in_exp=ecc_in;
		ecc1= ecc_generate(err_data(n1.data1,n1.data2,n1.n_bits));
	end
	else if(n1.error_mode== DOUBLE)
	begin
		@(negedge clock);
		data_in=double_error(n1.data1,n1.data2,n1.n_bits);
		data_in_exp=data_in;
		ecc_in=ecc_generate({n1.data2,n1.data1});
		ecc_in_exp=ecc_in;
		ecc1= ecc_generate(double_error(n1.data1,n1.data2,n1.n_bits));
	end
	
	else
	begin
		@(negedge clock)
		data_in={n1.data2,n1.data1};
		data_in_exp=data_in;
		ecc_in_exp=ecc_in;
		ecc_in = ecc_generate({n1.data2,n1.data1});
	end	
end
endtask

initial
begin
	no_error n1;
	n1=new();
	reset=0;
	@(negedge clock);
	reset=1;

	data_in='1;
	data_in_exp=data_in;
	ecc_in=ecc_generate(data_in);
	ecc_in_exp=ecc_in;

	@(negedge clock);
	data_in='0;
	data_in_exp=data_in;
	ecc_in=ecc_generate(data_in);
	ecc_in_exp=ecc_in;
	for(int i=0;i<5000;i++)
	begin
		error_inject(n1);
	end
	
if 	(Error) 	$display("***** Error in the design******");
else 			$display("***** Design passed ***********");

$finish;

end

always_ff@(posedge clock)
begin
	if(bus.data_out !== bus.data_out_exp)
	begin
		Error='1;
		$display("***Error*** At time=%t data_in=%x, data_out=%x, data_in_exp=%x, data_out_exp=%x",$time,data_in,data_out,data_in_exp,data_out_exp);
	end
end

endmodule









