module golden(simplebus.golden_ecc pins);

logic [7:0] r,ecc_buffer;
logic [6:0] syndrome;
logic [63:0] data_reg;
logic[71:0]codeword,data_buffer;
logic [71:1] cw_w_dbits,cw;

always_ff@(posedge pins.clock)
begin
	if(!pins.reset)
		begin
		data_reg <='0;
		ecc_buffer <='0;
		end
	else
	begin
		data_reg <=pins.data_in;
		ecc_buffer <=pins.ecc_in;
	end
end


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


function logic [71:0] databits_in_codeword (input [63:0] d);

logic [72:1] func_dbits_codeword;
int bit_count, cw_count;

begin
    //This function puts the information bits vector in the correct location
    //Information bits are stored in non-power-of-2 locations

    //clear all bits
    func_dbits_codeword = 0;

    bit_count=0; //information vector bit index
    for (cw_count=1; cw_count<=71; cw_count++)
		if (2**$clog2(cw_count) != cw_count)
		func_dbits_codeword[cw_count] = d[bit_count++];
		
end
return func_dbits_codeword;

endfunction


function logic [72:1] store_ecc_in_codeword (input logic [72:1] cw,input logic [8:1] ecc );
logic [71:1]store_P_in_codeword;
begin
    //databits don't change ... copy into codeword
    store_P_in_codeword  = cw;

    //put parity vector at power-of-2 locations
    for (int i=1; i<=7; i=i+1)
		store_P_in_codeword[2**(i-1)] = ecc[i];
end
return store_P_in_codeword;

endfunction //store_p_in_codeword



//Step 1: Load all databits in codeword
assign cw_w_dbits = databits_in_codeword(data_reg);

//Step 2: Calculate p-vector
assign r [7:0] = ecc_generate (data_reg);

//Step 3: Store p-vector in codeword
assign cw = store_ecc_in_codeword(cw_w_dbits, r);  
assign syndrome = ecc_buffer[7:1] ^ r[7:1]; 

/*
Based on the syndrome, LSB of the input ECC and generated ECC, 
Single bit, Double bit, Zero bit errors are differentiated.
*/

always_comb
begin
if(!syndrome)
	begin
		if(r[0]==ecc_buffer[0]) 
		pins.data_out_exp = data_reg;
		pins.error_flag_exp= 2'b00;
	end
else if(syndrome)
begin
	if(r[0]==ecc_buffer[0])
	begin
		pins.error_flag_exp= 2'b10;
		pins.data_out_exp=data_reg;
	end
	else
	begin
		pins.error_flag_exp=2'b11;
		for(int i=1;i<72;i++)
		begin
			if(i==syndrome) 
			data_buffer[syndrome]=cw_w_dbits[syndrome]^1'b1;
			
			else data_buffer[i]=cw_w_dbits[i]^1'b0;
		end
		pins.data_out_exp = {data_buffer[71:65],data_buffer[63:33],data_buffer[31:17],data_buffer[15:9],data_buffer[7:5],data_buffer[3]};

	end
end
else
begin
	pins.error_flag_exp=2'b00;
	pins.data_out_exp='0;
end

	
end
endmodule



