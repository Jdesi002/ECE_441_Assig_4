library ieee;
use ieee.NUMERIC_STD.all;
use ieee.std_logic_1164.all;

	-- Add your library and packages declaration here ...

entity fpga_tb is
end fpga_tb;

architecture TB_ARCHITECTURE of fpga_tb is
	-- Component declaration of the tested unit
	component fpga
	port(
		CLOCK_50 : in STD_LOGIC;
		CLOCK2_50 : in STD_LOGIC;
		CLOCK3_50 : in STD_LOGIC;
		CLOCK4_50 : in STD_LOGIC;
		SW : in STD_LOGIC_VECTOR(9 downto 0);
		KEY : in STD_LOGIC_VECTOR(3 downto 0);
		LEDR : out STD_LOGIC_VECTOR(9 downto 0);
		HEX0 : out STD_LOGIC_VECTOR(0 to 6);
		HEX1 : out STD_LOGIC_VECTOR(0 to 6);
		HEX2 : out STD_LOGIC_VECTOR(0 to 6);
		HEX3 : out STD_LOGIC_VECTOR(0 to 6);
		HEX4 : out STD_LOGIC_VECTOR(0 to 6);
		HEX5 : out STD_LOGIC_VECTOR(0 to 6) );
	end component;

	-- Stimulus signals - signals mapped to the input and inout ports of tested entity
	signal CLOCK_50 : STD_LOGIC;
	signal CLOCK2_50 : STD_LOGIC;
	signal CLOCK3_50 : STD_LOGIC;
	signal CLOCK4_50 : STD_LOGIC;
	signal SW : STD_LOGIC_VECTOR(9 downto 0);
	signal KEY : STD_LOGIC_VECTOR(3 downto 0);
	-- Observed signals - signals mapped to the output ports of tested entity
	signal LEDR : STD_LOGIC_VECTOR(9 downto 0);
	signal HEX0 : STD_LOGIC_VECTOR(0 to 6);
	signal HEX1 : STD_LOGIC_VECTOR(0 to 6);
	signal HEX2 : STD_LOGIC_VECTOR(0 to 6);
	signal HEX3 : STD_LOGIC_VECTOR(0 to 6);
	signal HEX4 : STD_LOGIC_VECTOR(0 to 6);
	signal HEX5 : STD_LOGIC_VECTOR(0 to 6);

	-- Add your code here ...
	signal simulationActive:boolean:=true;

begin

	-- Unit Under Test port map
	UUT : fpga
		port map (
			CLOCK_50 => CLOCK_50,
			CLOCK2_50 => CLOCK2_50,
			CLOCK3_50 => CLOCK3_50,
			CLOCK4_50 => CLOCK4_50,
			SW => SW,
			KEY => KEY,
			LEDR => LEDR,
			HEX0 => HEX0,
			HEX1 => HEX1,
			HEX2 => HEX2,
			HEX3 => HEX3,
			HEX4 => HEX4,
			HEX5 => HEX5
		);

	-- Add your stimulus here ...
	process
	begin
		while simulationActive loop
			clock_50<='0'; wait for 10 ns;
			clock_50<='1'; wait for 10 ns;
		end loop;
		wait;
	end process;
	
	process
	begin
		SW<=(others =>'0');
		KEY<=(others =>'1');
		wait for 0ns;
		
		SW(0)<='1';
		KEY(1)<='0';
		
		wait until clock_50'event and clock_50='1';
		wait until clock_50'event and clock_50='1';
		KEY(1)<='1';
		
		for i in 0 to 100000 loop
			wait until clock_50'event and clock_50='1';
		end loop;
		simulationActive<=false;
		wait;
	end process;
end TB_ARCHITECTURE;

configuration TESTBENCH_FOR_fpga of fpga_tb is
	for TB_ARCHITECTURE
		for UUT : fpga
			use entity work.fpga(behavior);
		end for;
	end for;
end TESTBENCH_FOR_fpga;

