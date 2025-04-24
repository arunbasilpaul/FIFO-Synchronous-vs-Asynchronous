library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SynchronousFIFO is
	generic(
		FIFO_DEPTH : integer := 32;  -- The maximum number of entries that can be stored
		DATA_WIDTH : integer := 8    -- The maximum number of bits per word in a single FIFO entry
	);
	port(
		clk      : in  std_logic;
		reset    : in  std_logic;
		write_en : in  std_logic;
		read_en  : in  std_logic;
		data_in  : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
		full     : out std_logic;
		empty    : out std_logic;
		data_out : out std_logic_vector(DATA_WIDTH - 1 downto 0)
	);
end SynchronousFIFO;

architecture BEHAV of SynchronousFIFO is
	type dataArray is array (0 to FIFO_DEPTH - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);
	signal dataFIFO : dataArray := (others => (others => '0'));  					-- Temporarily store the FIFO data
	signal write_ptr, read_ptr : integer range 0 to FIFO_DEPTH - 1 := 0; 				-- Pointers to store the pointer locations
	signal counter : integer range 0 to FIFO_DEPTH - 1 := 0;					-- Counts to check if FIFO is empty or full

  begin

	synchronousFifoProcess: process(clk, reset) 
	  begin
		if(rising_edge(clk)) then
			if(reset = '1') then	-- Reset conditions
				write_ptr <= 0;
				read_ptr  <= 0;
				counter   <= 0;
				data_out  <= (others => '0');
			else
				if(counter < FIFO_DEPTH and write_en = '1') then	-- Check if the write is enabled and the FIFO is not full
					dataFIFO(write_ptr) <= data_in;
					write_ptr <= (write_ptr + 1) mod FIFO_DEPTH;	-- Implement a circular (wrapping) pointer
					counter <= counter + 1;
				end if;
	
				if(counter > 0 and read_en = '1') then			-- Check if the read is enabled and the FIFO is not empty
					data_out <= dataFIFO(read_ptr);
					read_ptr <= (read_ptr + 1) mod FIFO_DEPTH;	-- Implement a circular (wrapping) pointer
					counter <= counter - 1;
				end if;

			end if;
		end if;

		empty <= '1' when counter = 0 else '0';
		full  <= '1' when counter = FIFO_DEPTH else '0';

	end process;
			
end BEHAV;