library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity REG is
  port(CLK: in std_logic;
       RegW: in std_logic;
       DR, SR1, SR2: in unsigned(4 downto 0);
       Reg_In: in unsigned(31 downto 0);
       ReadReg1, ReadReg2: out unsigned(31 downto 0));
end REG;

architecture Behavioral of REG is
  type RAM is array (0 to 31) of unsigned(31 downto 0);
  signal Regs: RAM := (0=>(others => '0'),others => (others => '1'));  -- set all reg bits to '1'
begin
  process(clk)
  begin
    if CLK = '1' and CLK'event then
      -- in MIPS, R0 is always zero and you cannot overwrite this value
      if RegW = '1' and DR/="00000" then -- this is a modification compared with the memory model from the textbook
        Regs(to_integer(DR)) <= Reg_In;
      end if;
    end if;
  end process;
  ReadReg1 <= Regs(to_integer(SR1)); --asynchronous read
  ReadReg2 <= Regs(to_integer(SR2)); --asynchronous read
end Behavioral;