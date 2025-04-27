library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity AsynchronousFIFO is
	generic(
		DATA_WIDTH    : integer := 32;  -- The maximum number of bits per word in a single FIFO entry
		ADDRESS_WIDTH : integer := 8    -- The maximum number of bits to store the addresses of the read and write pointers
	);
	port(
		-- Read ports
		read_clk   : in  std_logic;
		read_reset : in  std_logic;
		read_en    : in  std_logic;
		read_data  : out std_logic_vector(DATA_WIDTH - 1 downto 0);

		-- Write ports
		write_clk   : in  std_logic;
		write_reset : in  std_logic;
		write_en    : in  std_logic;
		write_data  : in  std_logic_vector(DATA_WIDTH - 1 downto 0);

		-- FIFO Status ports
		full  : out std_logic;
		empty : out std_logic
	);
end AsynchronousFIFO;

architecture Behavioral of AsynchronousFIFO is
	
	constant FIFO_DEPTH : integer := 2**ADDRESS_WIDTH;

	type dataArray is array (0 to FIFO_DEPTH - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);
	signal dataFIFO : dataArray := (others => (others => '0'));  					-- Temporarily store the FIFO data
	
	-- Binary and Gray Pointers
	signal write_ptr_bin, write_ptr_gray : unsigned(ADDRESS_WIDTH - 1 downto 0);
	signal read_ptr_bin,  read_ptr_gray  : unsigned(ADDRESS_WIDTH - 1 downto 0);

	-- Cross Clock Domain Synchronisation Pointers
	signal read_ptr_gray_sync_write1,  read_ptr_gray_sync_write2  : unsigned(ADDRESS_WIDTH - 1 downto 0);
	signal write_ptr_gray_sync_read1,  write_ptr_gray_sync_read2  : unsigned(ADDRESS_WIDTH - 1 downto 0);

	-- Synced binary pointers
	signal read_ptr_bin_sync  : unsigned(ADDRESS_WIDTH - 1 downto 0);
	signal write_ptr_bin_sync : unsigned(ADDRESS_WIDTH - 1 downto 0);
	
	-- Function for Binary to Gray code conversion
	function binary_to_gray(binary : unsigned) return unsigned is
		begin
		return binary xor (binary(binary'left downto 1) & '0');
	end function;

	-- Function for Gray to Binary code conversion
	function gray_to_binary(gray : unsigned) return unsigned is
		variable binary : unsigned(gray'range);
  	  begin
    		binary(gray'left) := gray(gray'left);
  		for i in gray'left-1 downto 0 loop
    	  		binary(i) := binary(i+1) xor gray(i);
    		end loop;
    		return binary;
	end function;
	
   begin
	read_process: process(read_clk, read_reset) begin
		if(rising_edge(read_clk)) then
			if(read_reset = '1') then
				read_ptr_bin  <= (others => '0');
				read_ptr_gray <= (others => '0');
			end if;

			else
				if(full = '0' and read_en = '1') then
					read_data <= dataFIFO(to_integer(read_ptr_bin(ADDRESS_WIDTH - 1)) downto 0);
					read_ptr_bin <= read_ptr_bin + 1;
					read_ptr_gray <= binary_to_gray(read_ptr_bin + 1);
				end if;
		end if;
	end process;

	write_process: process(write_clk, write_reset) begin
		if(rising_edge(write_clk)) then
			if(write_reset = '1') then
				write_ptr_bin  <= (others => '0');
				write_ptr_gray <= (others => '0');
			end if;
	
			else
				if(empty = '0' and write_en  = '1') then
					dataFIFO(to_integer(write_ptr_bin(ADDRESS_WIDTH - 1 downto 0))) <= write_data;
					write_ptr_bin <= write_ptr_bin + 1;
					write_ptr_gray <= binary_to_gray(write_ptr_bin + 1);
				end if;

		end if;
	end process;

	-- Read pointer synchronisation into write clock
	read_pointer_sync: process(write_clk) begin
		if(rising_edge(write_clk)) then
			read_ptr_gray_sync_write1 <= read_ptr_gray;
			read_ptr_gray_sync_write2 <= read_ptr_gray_sync_write1;
		end if;
	end process;

	-- Write pointer synchronisation into read clock
	write_pointer_sync: process(read_clk) begin
		if(rising_edge(read_clk)) then
			write_ptr_gray_sync_read1 <= write_ptr_gray;
			write_ptr_gray_sync_read2 <= write_ptr_gray_sync_read1;
		end if;
	end process;

	-- Convert gray into binary code after synchronisation
	read_ptr_bin_sync <= gray_to_binary(read_ptr_gray);
	write_ptr_bin_sync <= gray_to_binary(write_ptr_gray);

	-- FIFO Status statements
	full  <= '1' when ((write_ptr_gray(ADDRESS_WIDTH downto 0) = (not read_ptr_gray_sync_write2(ADDRESS_WIDTH downto ADDRESS_WIDTH-1)) & read_ptr_gray_sync_write2(ADDRESS_WIDTH-2 downto 0)))
        	 else '0';

  	empty <= '1' when (read_ptr_gray = write_ptr_gray_sync_read2) else '0';

end Behavioral;