module encoder(simplebus.ecc pins);

//generating ecc bits
logic [7:0] r,ecc_buffer;
logic [6:0]syndrome;

//reperseting the data in the codeword to generate the ecc
logic [71:0] codeword,data_buffer;
logic [63:0] data_reg;
int count=0;

genvar i;

always_ff@(posedge pins.clock)
begin
	assert (!$isunknown (pins.reset));
	if(!pins.reset)
	begin	
	data_reg<='0;
	ecc_buffer<='0;
	end
	else		
	begin 
		 assert (!$isunknown (pins.data_in));
		 data_reg<=pins.data_in;
		 ecc_buffer<=pins.ecc_in;
	end
end


//encoding the data into he codeword to caluculate the ecc bits from this codeword
assign codeword = {data_reg[63:57],1'b0,data_reg[56:26],1'b0,data_reg[25:11],1'b0,data_reg[10:4],1'b0,data_reg[3:1],1'b0,data_reg[0],1'b0,1'b0,1'b0};


// caluculating the ecc bits using codeword
assign r[0] = ^data_reg;

assign r[1] = codeword[3]^codeword[5]^codeword[7]^codeword[9]^codeword[11]^codeword[13]^codeword[15]^codeword[17]^codeword[19]^codeword[21]^codeword[23]^codeword[25]^codeword[27]^codeword[29]^codeword[31]^codeword[33]^codeword[35]^codeword[37]^codeword[39]^codeword[41]^codeword[43]^codeword[45]^codeword[47]^codeword[49]^codeword[51]^codeword[53]^codeword[55]^codeword[57]^codeword[59]^codeword[61]^codeword[63]^codeword[65]^codeword[67]^codeword[69]^codeword[71];

assign r[2] = codeword[3]^codeword[6]^codeword[7]^codeword[10]^codeword[11]^codeword[14]^codeword[15]^codeword[18]^codeword[19]^codeword[22]^codeword[23]^codeword[26]^codeword[27]^codeword[30]^codeword[31]^codeword[34]^codeword[35]^codeword[38]^codeword[39]^codeword[42]^codeword[43]^codeword[46]^codeword[47]^codeword[50]^codeword[51]^codeword[54]^codeword[55]^codeword[58]^codeword[59]^codeword[62]^codeword[63]^codeword[66]^codeword[67]^codeword[70]^codeword[71];

assign r[3] = codeword[5]^codeword[6]^codeword[7]^codeword[12]^codeword[13]^codeword[14]^codeword[15]^codeword[20]^codeword[21]^codeword[22]^codeword[23]^codeword[28]^codeword[29]^codeword[30]^codeword[31]^codeword[36]^codeword[37]^codeword[38]^codeword[39]^codeword[44]^codeword[45]^codeword[46]^codeword[47]^codeword[52]^codeword[53]^codeword[54]^codeword[55]^codeword[60]^codeword[61]^codeword[62]^codeword[63]^codeword[68]^codeword[69]^codeword[70]^codeword[71];

assign r[4] = codeword[9]^codeword[10]^codeword[11]^codeword[12]^codeword[13]^codeword[14]^codeword[15]^codeword[24]^codeword[25]^codeword[26]^codeword[27]^codeword[28]^codeword[29]^codeword[30]^codeword[31]^codeword[40]^codeword[41]^codeword[42]^codeword[43]^codeword[44]^codeword[45]^codeword[46]^codeword[47]^codeword[56]^codeword[57]^codeword[58]^codeword[59]^codeword[60]^codeword[61]^codeword[62]^codeword[63];

assign r[5] = codeword[17]^codeword[18]^codeword[19]^codeword[20]^codeword[21]^codeword[22]^codeword[23]^codeword[24]^codeword[25]^codeword[26]^codeword[27]^codeword[28]^codeword[29]^codeword[30]^codeword[31]^codeword[48]^codeword[49]^codeword[50]^codeword[51]^codeword[52]^codeword[53]^codeword[54]^codeword[55]^codeword[56]^codeword[57]^codeword[58]^codeword[59]^codeword[60]^codeword[61]^codeword[62]^codeword[63];

assign r[6] = codeword[33]^codeword[34]^codeword[35]^codeword[36]^codeword[37]^codeword[38]^codeword[39]^codeword[40]^codeword[41]^codeword[42]^codeword[43]^codeword[44]^codeword[45]^codeword[46]^codeword[47]^codeword[48]^codeword[49]^codeword[50]^codeword[51]^codeword[52]^codeword[53]^codeword[54]^codeword[55]^codeword[56]^codeword[57]^codeword[58]^codeword[59]^codeword[60]^codeword[61]^codeword[62]^codeword[63];

assign r[7] = codeword[65]^codeword[66]^codeword[67]^codeword[68]^codeword[69]^codeword[70]^codeword[71];



//caluculating the syndrome to check the error bit position in the input data using syndrome 
assign syndrome = r[7:1] ^ ecc_buffer[7:1];


//logic for the secded 
always_comb
begin
	if(!syndrome)
	begin
		pins.data_out = {data_buffer[71:65],data_buffer[63:33],data_buffer[31:17],data_buffer[15:9],data_buffer[7:5],data_buffer[3]};
		if(r[0]==ecc_buffer[0]) 
		begin
			assert (syndrome =='0 && r[0] == ecc_buffer[0]);
			pins.error_flag= 2'b00;
		end

	end
	else if(syndrome)
	begin
		if(r[0]==ecc_buffer[0]) 
		begin
			assert (syndrome != '0 && r[0] == ecc_buffer [0]);
			pins.error_flag= 2'b10;
			pins.data_out=data_reg;
		end
		else
		begin	
			assert  (pins.reset && syndrome != '0 && r[0] != ecc_buffer [0])
			else   $info("assertion failed");
			pins.error_flag=2'b01;
			pins.data_out={data_buffer[71:65],data_buffer[63:33],data_buffer[31:17],data_buffer[15:9],data_buffer[7:5],data_buffer[3]};
	
		end
	end
	else
	begin
		pins.data_out = data_reg;
	end
end


generate
	for(i=1;i<72;i++)
	begin
		always_comb
		begin
			if(i==syndrome) data_buffer[i]=codeword[i]^1'b1;
			else data_buffer[i]=codeword[i]^1'b0;
		end
	end
endgenerate

endmodule