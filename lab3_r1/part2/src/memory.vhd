library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity Memory is
  port(CS, WE, Clk: in std_logic;
       ADDR: in unsigned(31 downto 0);
       Mem_Bus_in: in unsigned(31 downto 0);
       Mem_Bus_out: out unsigned(31 downto 0));
end Memory;

architecture Internal of Memory is
type RAMtype is array (0 to 4*256-1) of unsigned(31 downto 0);
constant addressBits:integer:=integer(ceil(log2(real(RAMtype'high))));
  signal RAM1: RAMtype := (others => (others => '0'));
  signal output: unsigned(31 downto 0);
begin
	
  --Mem_Bus <= "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ" when CS = '0' or WE = '1'
--else output;
	
	Mem_Bus_out<=output;
  process(Clk)
  begin
    if Clk = '0' and Clk'event then
      if CS = '1' and WE = '1' then
        RAM1(to_integer(ADDR(addressBits-1 downto 0))) <= Mem_Bus_in;
        --RAM1(to_integer(ADDR(6 downto 0))) <= Mem_Bus_in;
      end if;
    output <= RAM1(to_integer(ADDR(addressBits-1 downto 0)));
    end if;
  end process;
end Internal;