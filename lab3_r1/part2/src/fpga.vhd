library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.MIPS_package.all;

ENTITY fpga IS
	PORT (
		CLOCK_50 : IN STD_LOGIC; -- 50 MHz Clock
		CLOCK2_50 : IN STD_LOGIC; -- 50 MHz Clock
		CLOCK3_50 : IN STD_LOGIC; -- 50 MHz Clock
		CLOCK4_50 : IN STD_LOGIC; -- 50 MHz Clock
		SW : IN STD_LOGIC_VECTOR(9 downto 0); -- switches
		KEY : IN STD_LOGIC_VECTOR(3 downto 0); -- push buttons
		LEDR : OUT STD_LOGIC_VECTOR(9 downto 0); -- red LEDs
		HEX0 : OUT STD_LOGIC_VECTOR(0 to 6);
		HEX1 : OUT STD_LOGIC_VECTOR(0 to 6);
		HEX2 : OUT STD_LOGIC_VECTOR(0 to 6);
		HEX3 : OUT STD_LOGIC_VECTOR(0 to 6);
		HEX4 : OUT STD_LOGIC_VECTOR(0 to 6);
		HEX5 : OUT STD_LOGIC_VECTOR(0 to 6)
		);
END ENTITY fpga;

ARCHITECTURE Behavior OF fpga IS
	component  pll IS 
		PORT 
			( 
			--locked	:	OUT  STD_LOGIC;
			outclk_0	:	OUT  STD_LOGIC;
			refclk	:	IN  STD_LOGIC;
			rst	:	IN  STD_LOGIC
			); 
	END component pll;
	component MIPS is
		port(CLK, RST: in std_logic;
			CS, WE: out std_logic;
			ADDR: out unsigned(31 downto 0);
			Mem_Bus_in: in unsigned(31 downto 0);
			Mem_Bus_out: out unsigned(31 downto 0));
	end component;
	component Memory is
		port(CS, WE, Clk: in std_logic;
			ADDR: in unsigned(31 downto 0);
			Mem_Bus_in: in unsigned(31 downto 0);
			Mem_Bus_out: out unsigned(31 downto 0));
	end component;
	component hexToSevenSegmentDecoder is
		port(
			hexDigit:in std_logic_vector(3 downto 0); 
			custom:in std_logic_vector(0 to 6);
			useCustom:in std_logic;
			blankDisplay:in std_logic;
			hex:out std_logic_vector(0 to 6)
			);
	end component;
	
	constant N: integer := 8;
	--constant W: integer := 20;
	--constant W: integer := 24;
	--constant W: integer := 26+6;
	-- recoded this to make self sizing. Note that we are starting index at zero now, will need to fix loader
	type Iarr is array(natural range <>) of unsigned(31 downto 0);
	--type Iarr is array(0 to W-1) of unsigned(31 downto 0);
	constant Instr_List: Iarr := ( -- assign by association so the address of each instruction is obvious
	-- first initialize 
	0 => assemble(R_op,0,0,2,f_and), -- clear out R2, use as base address for data
	1 => assemble(addi,2,2,256), -- base address for data
	2 => assemble(R_op,0,0,3,f_and), -- clear out R3, use as base address for weights
	3 => assemble(addi,3,3,512), -- base address for weights
	
	-- a couple of assumptions: 
	-- 1. weights and data are limited to 16 bit precision
	-- 2. the weighted sum is contained in 32 bits (not necessarily a valid assumption but will be the case most of the time)
	-- clear out total register
	4 => assemble(R_op,0,0,4,f_and), -- clear out R4
	5 => assemble(R_op,0,0,5,f_and), -- clear out R5, use to count number that are averaged together
	
	-- now start to do math
	6 => assemble(lw,2,6,0), -- load data into R6
	7 => assemble(lw,3,7,0), -- load weight into R7
	-- test if weight is zero. if neither less than or greater than then it must be zero
	
	8 => assemble(beq,7,0,7),  -- if weight zero, branch to calculate average
	
	--assemble(R_op,8,7,0,f_slt), -- set R8 to 1 if R7<0 
	--assemble(bne,8,0,3),  -- branch if not less than (offset TBD)
	--assemble(R_op,8,0,7,f_slt), -- set R8 to 1 if R7<0 
	--assemble(bne,8,0,1),  -- branch if not less than (offset TBD), have some real work to do
	-- We are done, jump to final code to take the average
	--assemble(jump,20),  
	
	-- now do some work	
	9 => assemble(R_op,6,7,0,f_mult), -- destination register is ignored in multiplication instruction
	
	-- now add the product into the total
	10 => assemble(R_op,0,0,8,f_mflo), -- retrieve lower word of product. 16 bit operands guarantees this is all we need
	11 => assemble(R_op,8,4,4,f_add), -- add to total
	12 => assemble(addi,2,2,1), -- advance to address pointer for data
	13 => assemble(addi,3,3,1), -- advance to address pointer for weight
	14 => assemble(addi,5,5,1), -- one more item in average
	
	15 => assemble(jump,6),   -- jump back for next iteration
	
	-- hopefully this is address 20	
	16 => assemble(R_op,4,5,0,f_div), -- now take average, 
	17 => assemble(R_op,0,0,8,f_mfhi), -- retrieve lower word of product. 16 bit operands guarantees this is all we need
	
	18 => assemble(R_op,0,0,2,f_and), -- clear out R2, use as base address for data
	19 => assemble(addi,2,2,255), -- store value in location 255. This puts address/data on bus so we can see results in signal tap
	20 => assemble(sw_mips,2,8,0), -- have a problem because SW is actually the switches on the entity
	21 => assemble(jump,21)   -- jump back for next iteration
	--assemble(jump,23)   -- jump back for next iteration
	
	);
	-- arrays for data which will also be loaded into memory
	constant W: integer := Instr_List'length;

	type data_weight_record is record -- problem statement does not indicate whether data/weights are signed or unsigned
		data: signed(31 downto 0);
		weight: signed(31 downto 0);
	end record;
	type data_weight_array is array (natural range <>) of data_weight_record;
	
	function populate_data_and_weight(N:integer) return data_weight_array is
		variable ret:data_weight_array(0 to N); -- the Nth is the marker indicating the end of the list
		variable s1,s2:positive; -- for the random number generator
		variable r:real;
		constant nibMax:integer:=4; -- maximum value 16 bits so that product will be contained in 32 bits
		variable sign:std_logic;
	begin
		s1:=4310;
		s2:=231513;
		for i in 0 to N-1 loop
			ret(i).data:=to_signed(0,32);
			while ret(i).data =0 loop -- why do I need to do this?
				for nib in 0 to nibMax-1 loop
					uniform(s1,s2,r);
					ret(i).data(nib*4+3 downto nib*4):=signed(to_unsigned(integer(floor(r*16.0)),4));
				end loop;
			end loop;
			if nibMax<8 then -- need to sign extend the value
				sign:=ret(i).data(nibMax*4+3);
				for b in nibMax*4 to 31 loop
					ret(i).data(b):=sign;
				end loop;
			end if;
			
			ret(i).weight:=to_signed(0,32);
			while ret(i).weight =0 loop -- why do I need to do this?
				for nib in 0 to nibMax-1 loop
					uniform(s1,s2,r);
					ret(i).weight(nib*4+3 downto nib*4):=signed(to_unsigned(integer(floor(r*16.0)),4));
				end loop;
			end loop;
			report "("&integer'image(i)&") data="&integer'image(to_integer(ret(i).data))&
			" weight"&integer'image(to_integer(ret(i).weight));
			if nibMax<8 then -- need to sign extend the value
				sign:=ret(i).weight(nibMax*4+3);
				for b in nibMax*4 to 31 loop
					ret(i).weight(b):=sign;
				end loop;
			end if;
		end loop;
		
		ret(N).weight:=to_signed(0,32);
		return ret;
	end function;
	constant data_and_weights:data_weight_array:=populate_data_and_weight(20);
	--	(to_signed(5,32),to_signed(-8,32)),
	--	(to_signed(-4,32),to_signed(12,32)),
	--	(to_signed(-4,32),to_signed(0,32)) -- end of the list
	--	);
	
	-- The last instructions perform a series of sw operations that store 
	-- registers 3-10 to memory. During the memory write stage, the testbench 
	-- will compare the value of these registers (by looking at the bus value) 
	-- with the expected output. No explicit check/assertion for branch 
	-- instructions, however if a branch does not execute as expected, an error 
	-- will be detected because the assertion for the instruction after the 
	-- branch instruction will be incorrect.
	type output_arr is array(1 to N) of integer;
	constant expected: output_arr:= (24, 12, 2, 22, 1, 288, 3, 4268066);
	
	signal CS, WE: std_logic;
	
	signal Mem_Bus_in, Mem_Bus_out, Mem_Bus_outTB,Mem_Bus_out_Mux: unsigned(31 downto 0);
	signal Address, AddressTB, Address_Mux: unsigned(31 downto 0);
	signal RST, init, WE_Mux, CS_Mux, WE_TB, CS_TB: std_logic;
	
	attribute keep:boolean; -- something new--VHDL allows you to add attributes to signals and variables
	signal clock: std_logic;
	signal clk: std_logic;
	
	attribute keep of clk:signal is true; -- tell synthesizer to "keep" clk so we can find it in signal tap
	-- like pragmas in other programming languages
	attribute keep of init:signal is true; 
	signal reset:std_logic;
	signal state,nextState:integer;
	signal count:integer;
	signal incCount:std_logic;
	signal displayMode:std_logic_vector(2 downto 0);
	signal displayValue:unsigned(15 downto 0);
	signal blankDisplay:std_logic;
	signal half:unsigned(3 downto 0);
	signal custom:std_logic_vector(0 to 6);
	constant segment6:std_logic_vector(0 to 6):="0000001";
	constant segment5:std_logic_vector(0 to 6):="0000010";
	constant segment4:std_logic_vector(0 to 6):="0000100";
	constant segment3:std_logic_vector(0 to 6):="0001000";
	constant segment2:std_logic_vector(0 to 6):="0010000";
	constant segment1:std_logic_vector(0 to 6):="0100000";
	constant segment0:std_logic_vector(0 to 6):="1000000";
	
	signal customize:std_logic;
	signal clrCount:std_logic;
BEGIN
	reset<=not key(1);
	clockGen: pll 
	port map(clock,CLOCK_50,reset);
	
	process(SW,init)
	begin
		LEDR<=(others =>'0');
		LEDR(9)<=SW(9);
		LEDR(2 downto 0)<=SW(2 downto 0);
		LEDR(8)<=init;
	end process;
	
	with sw(0) select clk <=
	KEY(0) when '0',
	clock when '1',
	'X' when others;
	
	
	displayMode<=sw(2 downto 1)&sw(9);
	
	with displayMode select displayValue<=
	Address_MUX(15 downto 0) when "000",
	Address_MUX(31 downto 16) when "001",
	Mem_bus_in(15 downto 0) when "010",
	Mem_bus_in(31 downto 16) when "011",
	Mem_bus_out_MUX(15 downto 0) when "100",
	Mem_bus_out_MUX(31 downto 16) when "101",
	X"0000" when others;
	
	half<="000"&sw(9);   
	blankDisplay<='1' when sw(2 downto 1)="11" else '0';
	
	with sw(2 downto 1) select custom<=
	not segment3 when "00",
	(segment4 or segment5 or segment6) when "01",
	(segment1 or segment2 or segment6) when "10",
	segment6 when others; -- undefined, show dashes here and blanks in lower for displays
	
	customize<=blankDisplay;
	H0: hexToSevenSegmentDecoder port map(std_logic_vector(displayValue( 3 downto  0)),"0000000",'0',blankDisplay,HEX0);
	H1: hexToSevenSegmentDecoder port map(std_logic_vector(displayValue( 7 downto  4)),"0000000",'0',blankDisplay,HEX1);
	H2: hexToSevenSegmentDecoder port map(std_logic_vector(displayValue(11 downto  8)),"0000000",'0',blankDisplay,HEX2);
	H3: hexToSevenSegmentDecoder port map(std_logic_vector(displayValue(15 downto 12)),"0000000",'0',blankDisplay,HEX3);
	
	H4: hexToSevenSegmentDecoder port map(std_logic_vector(half),custom,customize,'0',HEX4);
	H5: hexToSevenSegmentDecoder port map("0000",custom,'1','0',HEX5);
	
	CPU: MIPS port map (CLK, RST, CS, WE, Address, Mem_Bus_in,Mem_Bus_out);
	MEM: Memory port map (CS_Mux, WE_Mux, CLK, Address_Mux, Mem_Bus_out_Mux,Mem_Bus_in);
	
	Address_Mux <= AddressTB when init = '1' else Address; 
	Mem_Bus_out_Mux<= Mem_Bus_outTB when init='1' else Mem_Bus_out;
	
	WE_Mux <= WE_TB when init = '1' else WE;
	CS_Mux <= CS_TB when init = '1' else CS;
	
	process(state,count)
		variable weightVar:signed(31 downto 0);
		variable dataVar:signed(31 downto 0);
		constant dataBase:unsigned(31 downto 0):=X"00000100";
		constant weightBase:unsigned(31 downto 0):=X"00000200";
	begin
		init<='0';
		nextState<=state;
		incCount<='0';
		clrCount<='0';
		RST<='0';
		CS_TB <= '0';
		WE_TB <= '0';
		AddresstB<=(others =>'0');
		Mem_Bus_outTB<=(others =>'0');
		dataVar:=to_signed(0,32);
		weightVar:=to_signed(0,32);
		
		
		case state is
			when 0 => 
				init<='1';
				CS_TB <= '1';
				WE_TB <= '1';
				nextState<=1;
				clrCount<='1'; -- new to support automatic sizing of program
				RST<='1';
			
			when 1 => -- load program into memory
				CS_TB <= '1';
				WE_TB <= '1';
				RST<='1';
				init<='1';
				--if count>W then
				if (count+1)>W then -- change to support automatic sizing of program
					nextState<=2;
					clrCount<='1'; -- pause while this is on
					WE_TB <= '0'; -- don't want to write here

				else 
					incCount<='1';
					AddressTB <= to_unsigned(count,32); -- change to support automatic sizing of program
					--AddressTB <= to_unsigned(count-1,32);
					Mem_Bus_outTB <= Instr_List(count);
				end if;
			
			when 2 => -- load data into memory
				CS_TB <= '1';
				WE_TB <= '1';
				RST<='1';
				init<='1';
				weightVar:=data_and_weights(count).weight;
				dataVar:=data_and_weights(count).data;
				if data_and_weights(count).weight=0 then
					nextState<=4;
					WE_TB <= '0';
				else 
					nextState<=3;
					AddressTB <= dataBase+count;
					Mem_Bus_outTB <= unsigned(data_and_weights(count).data);
				end if;
			
			when 3 => 
				CS_TB <= '1';
				WE_TB <= '1';
				RST<='1';
				init<='1';
				incCount<='1'; -- done with this record
				AddressTB <= weightBase+count;
				Mem_Bus_outTB <= unsigned(data_and_weights(count).weight);
				nextState<=2;
			
			when 4 =>
				nextState<=4;
			
			when others =>
				nextState<=0;
				
			
		end case;
	end process;
	
	process(CLK,reset)
	begin
		if reset='1' then
			state<=0;
			count<=0; -- change to support automatic sizing of program
			-- count<=1;
		elsif clk'event and clk='1' then
			state<=nextState;
			if clrCount='1' then
				count<=0;
			elsif incCount='1' then
				count<=count+1;
			end if;
		end if;
	end process;
	--	process
	--	begin
	--		rst <= '1';
	--		wait until CLK = '1' and CLK'event;
	--		
	--		--Initialize the instructions from the testbench
	--		init <= '1';
	--		CS_TB <= '1'; WE_TB <= '1';
	--		for i in 1 to W loop
	--			wait until CLK = '1' and CLK'event;
	--			AddressTB <= to_unsigned(i-1,32);
	--			Mem_Bus <= Instr_List(i);
	--		end loop; 
	--		wait until CLK = '1' and CLK'event;
	--		Mem_Bus <= "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
	--		CS_TB <= '0'; WE_TB <= '0';
	--		init <= '0';
	--		wait until CLK = '1' and CLK'event;
	--		rst <= '0';
	--		
	--		for i in 1 to N loop
	--			wait until WE = '1' and WE'event;  -- When a store word is executed
	--			wait until CLK = '0' and CLK'event;
	--			assert(to_integer(Mem_Bus) = expected(i))
	--			report "Output mismatch:" severity error;
	--		end loop;
	--		
	--		report "Testing Finished:";
	--	end process;
	
	
END Behavior;