#define __MAIN_C__

#include <stdint.h>
#include <stdbool.h>

// Define the raw base address values for the i/o devices

#define AHB_SW_BASE                             0x40000000
#define AHB_OUT_BASE                            0x50000000
#define AHB_RX_BASE                             0x60000000
#define AHB_TX_BASE                             0x70000000
#define AHB_ID_BASE                             0x80000000
#define AHB_DIG_BASE                            0x90000000
#define AHB_MEM_BASE                            0xa0000000
#define AHB_VGA_BASE                            0xb0000000

// Define pointers with correct type for access to 16-bit i/o devices
//
// The locations  in the devices can then be accessed as:
//    SW_REGS[0]  read only	data register
//    SW_REGS[1]  read only	datavalid register
//    OUT_REGS[0] read & write	data register
//    OUT_REGS[1] read & write	datavalid register
//    OUT_REGS[2] read		dataack register
//    RX_REGS[7:0]read only	data register
//    RX_REGS[8]  read only	byte_length register
//    RX_REGS[9]  read only	src_addr register
//    RX_REGS[16] read only	status register
//    TX_REGS[7:0]write only	data register
//    TX_REGS[8]  write only	byte_length register
//    TX_REGS[9]  write only	des_addr register
//    TX_REGS[16] read only	status register
//    ID_REGS[0]  read only	xy_addr register
//    DIG_REGS[0]  write only	data register
//    MEM_REGS[0]  not defined yet
//    VGA_REGS[0]  read & write	data register

volatile uint32_t* SW_REGS = (volatile uint32_t*) AHB_SW_BASE;
volatile uint32_t* OUT_REGS = (volatile uint32_t*) AHB_OUT_BASE;
volatile uint32_t* RX_REGS = (volatile uint32_t*) AHB_RX_BASE;
volatile uint32_t* TX_REGS = (volatile uint32_t*) AHB_TX_BASE;
volatile uint32_t* ID_REGS = (volatile uint32_t*) AHB_ID_BASE;
volatile uint32_t* DIG_REGS = (volatile uint32_t*) AHB_DIG_BASE;

volatile uint32_t* VGA_REGS = (volatile uint32_t*) AHB_VGA_BASE;

// define vga macro

//VGA Screen size
#define k_VGA_WIDTH		32
#define k_VGA_HEIGHT 	24

//Mandlebrot Set Calculation Parameters
#define k_DIVERGENCE_FACTOR 	4
#define k_CONVERGENCE_FACTOR 	15

//Block Size used in breakdown of tasks between cores
#define k_BLOCK_WIDTH		8
#define k_BLOCK_HEIGHT 	6
#define k_NUM_BLOCK_ROWS 		k_VGA_HEIGHT/k_BLOCK_HEIGHT
#define k_NUM_BLOCK_COLUMNS k_VGA_WIDTH/k_BLOCK_WIDTH

const float scale_x = 3.0 / (float)k_VGA_WIDTH ;
const float scale_y = 2.0 / (float)k_VGA_HEIGHT;


//////////////////////////////////////////////////////////////////
// Functions provided to access i/o devices
//////////////////////////////////////////////////////////////////

/////////////////////////////////////////
// sw function here
/////////////////////////////////////////

bool check_switches(void) {

  int status, switches_ready;
  
  status = SW_REGS[1];
  
  // use the addr value to select one bit of the status register
  switches_ready = status & 1;
  
  return (switches_ready == 1);

}

uint32_t read_switches(void) {

  uint32_t value;

  value = SW_REGS[0];

  return value;

}

/////////////////////////////////////////
// out function here
/////////////////////////////////////////

void write_out(uint32_t value) {

  OUT_REGS[1] = 1;
  OUT_REGS[0] = value;

}

uint32_t read_out(int addr) {

  return OUT_REGS[addr];

}

void set_out_invalid(void) {

  OUT_REGS[1] = 0;
  OUT_REGS[0] = 0;

}

void set_out_nextvalid(uint32_t value) {

  OUT_REGS[1] = 0;
  OUT_REGS[0] = value;

}

bool check_out(void) {

  int status, out_ready;
  
  status = OUT_REGS[2];
  
  // use the addr value to select one bit of the status register
  out_ready = status & 1;
  
  return (out_ready == 1);

}

/////////////////////////////////////////
// rx function here
/////////////////////////////////////////

bool check_rx(void) {

  int status, done;
  
  status = RX_REGS[16];
  
  // use the addr value to select one bit of the status register
  done = status & 1;
  //return value when buffer is not
  return (done == 1);

}

uint32_t read_rx(int addr) {

  return RX_REGS[addr];

}

/////////////////////////////////////////
// tx function here
/////////////////////////////////////////

bool check_tx(void) {

  int status, busy;
  
  status = TX_REGS[16];
  
  // use the addr value to select one bit of the status register
  busy = status & 1;

  return (busy == 0);

}
void write_tx(uint32_t addr, uint32_t value) {

  TX_REGS[addr] = value;

}

/////////////////////////////////////////
// id function here
/////////////////////////////////////////

uint32_t read_id(void) {
  return ID_REGS[0];
}

/////////////////////////////////////////
// dig function here
/////////////////////////////////////////

void write_dig(uint32_t value) {

  DIG_REGS[0] = value;
	
}

void start_dig(void) {

  DIG_REGS[1] = 1;
	
}

void finish_dig(void) {

  DIG_REGS[2] = 1;
	
}

void write_pixcel_dig(uint32_t value) {

  DIG_REGS[3] = value;
	
}

/////////////////////////////////////////
// vga function here
/////////////////////////////////////////

void writeHalfByteMemory(uint32_t address, uint32_t value) {

  VGA_REGS[address] = value;
	
}

uint32_t readHalfByteMemory(uint32_t address) {

	return VGA_REGS[address];
	
}

//////////////////////////////////////////////////////////////////
// Other Functions
//////////////////////////////////////////////////////////////////

void write_remote_memory(uint32_t pixel_x, uint32_t pixel_y, uint32_t rgb) {
	write_tx(0, pixel_x);
	write_tx(1, pixel_y);
	write_tx(2, rgb);
	// message byte length
    write_tx(8, 12);
	// dest_addr 2,2
    write_tx(9, 0xa);
}

void write_finish(uint32_t block_number) {
	// finish signals
  write_tx(0, (block_number << 16) | 0xdead );
  // message byte length
  write_tx(8, 4);
  // dest_addr 2,2
  write_tx(9, 0xa);
}

// Mandlebrot set boundaries
// -2.0 < x < 1.0
// -1.0 < y < 1.0
//Mathematical Backend for calculation for Mandlebrot Set
//computes the number of iterations at each point in the screen
uint8_t iteratePoint(uint16_t x_pos, uint16_t y_pos) {
	float z_re = ( scale_x * (float)x_pos ) - 2.0 ;
	float z_im = ( scale_y*(float)y_pos ) - 1.0 ;
	float x = 0;
	float y = 0;
	float x_sq = 0;
	float y_sq = 0;
	uint8_t number_of_iterations = 0;
	while( ( (x_sq + y_sq) < k_DIVERGENCE_FACTOR) && (number_of_iterations < k_CONVERGENCE_FACTOR) ) {
		y = 2*x*y + z_im;
		x = x_sq - y_sq + z_re;
		//reduce number of floating point calculations required
		x_sq = x*x;
		y_sq = y*y;
		number_of_iterations++;
	}
	return number_of_iterations;
}

//Function to draw the mandlebrot set
void drawMandlebrotSet(uint32_t block_number ) {
	uint16_t x;
	uint16_t y;
	uint16_t num_block_cols = 4; // divided full screen in to 4 columns
	uint16_t row_num = (block_number/num_block_cols);
	uint16_t column_num = (block_number % num_block_cols);
	uint16_t y_lower_bound = (k_BLOCK_HEIGHT * row_num );
	uint16_t y_upper_bound = y_lower_bound + k_BLOCK_HEIGHT;
	uint16_t x_lower_bound = (k_BLOCK_WIDTH * column_num);
	uint16_t x_upper_bound = x_lower_bound + k_BLOCK_WIDTH;
  uint8_t output_half_byte;

	for( y = y_lower_bound ; y < y_upper_bound ; y++ ) {
		for( x = x_lower_bound ; x < x_upper_bound ; x++ ) {;
      output_half_byte = iteratePoint( x, y );
			while ( ! check_tx() );
      write_remote_memory(x, y, output_half_byte); 
		}
	}
}

//////////////////////////////////////////////////////////////////
// Main Function
//////////////////////////////////////////////////////////////////
//0000(0,0)
//0001(0,1)
//0101(1,0)

int main(void) {
	uint32_t ID;
  uint32_t local_block_num;

	ID = read_id();
  local_block_num = ID & 0xf;

  //////////////////////
  // ID (2,2) code here
  //////////////////////
  if(local_block_num == 0xa){
    uint32_t Num_Byte, Num_Word;
    uint32_t temp_data [8];
    uint32_t count_finish = 0;
    uint32_t x, y;
    uint32_t output_half_byte;
    uint32_t address;

    int switch_temp=0;
		int VGA_address;
		
		// flag for start calculation
		while ( !check_switches() )
			;
		start_dig();
		write_out(1);
		
    //repeat forever
    while(1) {
		
      	
				
			
      // read rx data
      if( check_rx() ){
        Num_Byte = read_rx( 8 );
        Num_Word = Num_Byte >> 2;
        for(uint8_t i = 0; i < Num_Word; i++){
            temp_data[i] = read_rx(i);
        }

        if(Num_Byte == 12){
          Num_Byte = 0;
          Num_Word = 0;
          x = temp_data[0];
          y = temp_data[1];
          output_half_byte = temp_data[2] & 0xf;
          address = x + y * k_VGA_WIDTH;
          
          writeHalfByteMemory(address, output_half_byte);
        }

        // judge the data
        else if(Num_Word == 1 && (temp_data[0] & 0xffff) == 0xdead){
          Num_Byte =0;
          Num_Word = 0;
          count_finish++;
          // write out finish number
          write_dig(count_finish);
        }
      }
			
			// after finish counting
			if(count_finish == 16){
				finish_dig() ;
				set_out_invalid() ;
				
				// loop after finish calculating graph
				while(1) {
					if (check_switches()) {
        		switch_temp = read_switches();
						VGA_address = readHalfByteMemory(switch_temp);
						write_pixcel_dig(VGA_address) ;
      		}
						
				}
			
			}
			  
     }
  }
  //////////////////////
  // ID (0,0) code here
  //////////////////////
  else if (local_block_num == 0) {
    drawMandlebrotSet( local_block_num );
    write_finish(local_block_num);
    
    drawMandlebrotSet( 0xa );
		write_finish(0xa);

    //repeat forever
    while(1) {
      // do nothing
    }
    //loops end here
  }
  //////////////////////
  // all other id code here
  //////////////////////
  else {
    drawMandlebrotSet( local_block_num );
    write_finish(local_block_num);
    
    //repeat forever
    while(1) {
      // do nothing
    }
    //loops end here
  }
  
  return 0;
}


