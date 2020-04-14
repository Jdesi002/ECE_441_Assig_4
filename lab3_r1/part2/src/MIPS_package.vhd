library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package MIPS_package is
	constant addi: unsigned(5 downto 0) := "001000";  -- 8 
	constant andi: unsigned(5 downto 0) := "001100";  -- 12
	constant ori:  unsigned(5 downto 0) := "001101";  -- 13
	constant lw:   unsigned(5 downto 0) := "100011";  -- 35
	constant sw_mips:   unsigned(5 downto 0) := "101011";  -- 43 -- name change beause of aliasing with switches
	constant beq:  unsigned(5 downto 0) := "000100";  -- 4
	constant bne:  unsigned(5 downto 0) := "000101";  -- 5
	constant jump: unsigned(5 downto 0) := "000010";  -- 2
	constant R_op: unsigned(5 downto 0) := "000000";
	
	-- definitions for funct fields
	constant f_add: unsigned(5 downto 0):="100000"; -- 0x20
	constant f_sub: unsigned(5 downto 0):="100010";
	constant f_and: unsigned(5 downto 0):="100100";
	constant f_or:  unsigned(5 downto 0):="100101";
	constant f_shr: unsigned(5 downto 0):="000010";
	constant f_shl: unsigned(5 downto 0):="000000";
	constant f_jr:  unsigned(5 downto 0):="001000"; -- 0x08
	constant f_slt: unsigned(5 downto 0):="101010";

	-- following required for mult,multu,div,divu
	constant f_div: unsigned(5 downto 0):="011010";
	constant f_divu: unsigned(5 downto 0):="011011";
	constant f_mult: unsigned(5 downto 0):="011000";
	constant f_multu: unsigned(5 downto 0):="011001";
	constant f_mfhi: unsigned(5 downto 0):="010000";
	constant f_mflo: unsigned(5 downto 0):="010010";
	constant f_mthi: unsigned(5 downto 0):="010000";
	constant f_mtlo: unsigned(5 downto 0):="010011";

	function Nop return unsigned;
	function assemble(opcode:unsigned(5 downto 0);rs,rt,rd:integer range 0 to 31;shamt:integer range 0 to 31;funct:unsigned(5 downto 0)) return unsigned;
	function assemble(opcode:unsigned(5 downto 0);rs,rt,rd:integer range 0 to 31;funct:unsigned(5 downto 0)) return unsigned;
	function assemble(opcode:unsigned(5 downto 0);rs,rt:integer range 0 to 31;immediate:integer range -128*256 to (128*256-1)) return unsigned;
	function assemble(opcode:unsigned(5 downto 0);addr: integer range 0 to (4*256*256*256-1)) return unsigned;

	function assemble(opcode:unsigned(5 downto 0);rs,rt,rd:unsigned(4 downto 0);shamt:unsigned(4 downto 0);funct:unsigned(5 downto 0)) return unsigned;
	function assemble(opcode:unsigned(5 downto 0);rs,rt,rd:unsigned(4 downto 0);funct:unsigned(5 downto 0)) return unsigned;
	function assemble(opcode:unsigned(5 downto 0);rs,rt:unsigned(4 downto 0);immediate:unsigned(15 downto 0)) return unsigned;
	function assemble(opcode:unsigned(5 downto 0);addr: unsigned(25 downto 0)) return unsigned;
	
	
end package MIPS_package;

package body MIPS_package is
	function nop return unsigned is
	  variable ret:unsigned(31 downto 0);
	begin
	  ret:=assemble(R_op,0,0,0,f_and); -- one possible noop
	  return ret;
   end function;
	
	function assemble(opcode:unsigned(5 downto 0);rs,rt,rd:unsigned(4 downto 0);funct:unsigned(5 downto 0)) return unsigned is
	variable ret:unsigned(31 downto 0);
	begin
		if opcode="000000" and (funct=f_shr or funct=f_shl) then
			assert false report "Illegal instruction" severity error;
		end if;
		ret:=assemble(opcode,rs,rt,rd,"00000",funct);
		return ret;
	end function;

	function assemble(opcode:unsigned(5 downto 0);rs,rt,rd:unsigned(4 downto 0);shamt:unsigned(4 downto 0);funct:unsigned(5 downto 0)) return unsigned is
	variable ret:unsigned(31 downto 0);
	begin
		ret:=opcode&rs&rt&rd&shamt&funct;
		return ret;
	end function;

	function assemble(opcode:unsigned(5 downto 0);rs,rt:unsigned(4 downto 0);immediate:unsigned(15 downto 0)) return unsigned is
	variable ret:unsigned(31 downto 0);
	begin
		ret:=opcode&rs&rt&immediate;
		return ret;
	end function;
	
	function assemble(opcode:unsigned(5 downto 0);addr:unsigned(25 downto 0)) return unsigned is
	variable ret:unsigned(31 downto 0);
	begin
		ret:=opcode&addr;
		return ret;
	end function;
	
	function assemble(opcode:unsigned(5 downto 0);addr:integer range 0 to (4*256*256*256-1)) return unsigned is
	variable ret:unsigned(31 downto 0);
	begin
		ret:=opcode&to_unsigned(addr,26);
		return ret;
	end function;
	
	
	function assemble(opcode:unsigned(5 downto 0);rs,rt,rd:integer range 0 to 31;shamt:integer range 0 to 31;funct:unsigned(5 downto 0)) return unsigned is
	variable ret:unsigned(31 downto 0);
	begin
		ret:=assemble(opcode,to_unsigned(rs,5),to_unsigned(rt,5),to_unsigned(rd,5),to_unsigned(shamt,5),funct);
		return ret;
	end function;
	
	function assemble(opcode:unsigned(5 downto 0);rs,rt,rd:integer range 0 to 31;funct:unsigned(5 downto 0)) return unsigned is
	variable ret:unsigned(31 downto 0);
	begin
		ret:=assemble(opcode,rs,rt,rd,0,funct);
		return ret;
	end function;
	
	function assemble(opcode:unsigned(5 downto 0);rs,rt:integer range 0 to 31;immediate:integer range -128*256 to (128*256-1)) return unsigned is
	variable ret:unsigned(31 downto 0);
	begin
		ret:=assemble(opcode,to_unsigned(rs,5),to_unsigned(rt,5),unsigned(to_signed(immediate,16)));
		return ret;
	end function;

end package body;