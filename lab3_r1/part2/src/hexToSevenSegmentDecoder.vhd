library ieee;
use ieee.std_logic_1164.all;

entity hexToSevenSegmentDecoder is
	port(
		hexDigit:in std_logic_vector(3 downto 0);
		custom:in std_logic_vector(0 to 6);
		useCustom:in std_logic;
		blankDisplay:in std_logic;
		hex:out std_logic_vector(0 to 6)
		);
end entity;





















architecture behavioral of hexToSevenSegmentDecoder is
	
	function hexToSegments(hexDigit:std_logic_vector(3 downto 0)) return std_logic_vector is
		variable ret:std_logic_vector(0 to 6);
	begin
		case hexDigit is
			when X"0" => ret:= not "1111110";
			when X"1" => ret:= not "0110000";
			when X"2" => ret:= not "1101101";
			when X"3" => ret:= not "1111001";
			when X"4" => ret:= not "0110011";
			when X"5" => ret:= not "1011011";
			when X"6" => ret:= not "1011111";
			when X"7" => ret:= not "1110000";
			when X"8" => ret:= not "1111111";
			when X"9" => ret:= not "1110011";
			when X"a" => ret:= not "1110111";
			when X"b" => ret:= not "0011111";
			when X"c" => ret:= not "1001110";
			when X"d" => ret:= not "0111101";
			when X"e" => ret:= not "1001111";
			when X"f" => ret:= not "1000111";
			when others => ret:="1111111";
		end case;
		return ret;
	end function;
begin
	hex<=not custom when useCustom='1' else
	"1111111" when blankDisplay='1' else 
	hexToSegments(hexDigit);
end architecture;