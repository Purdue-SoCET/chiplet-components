// Author:      Minh Tran
// Description: Test bench for the default settings versions of Flex STP SR
`ifndef SR_SIZE_BITS
    `define SR_SIZE_BITS 8
`endif

`ifndef MSB
    `define MSB 1
`endif

module tb_socetlib_shift_reg();
  // Define parameters
  // Common parameters
  localparam CLK_PERIOD        = 2.5;
  localparam PROPAGATION_DELAY = 0.8; // Allow for 800 ps for FF propagation delay

  localparam  INACTIVE_VALUE     = 1'b1;
  localparam  SR_MAX_BIT         = `SR_SIZE_BITS - 1;
  localparam  RESET_OUTPUT_VALUE = {`SR_SIZE_BITS{1'b1}};

  // Declare Test Case Signals
  integer tb_test_num;
  string  tb_test_case;
  string  tb_stream_check_tag;
  int     tb_bit_num;
  logic   tb_mismatch;
  logic   tb_check;

  // Declare the Test Bench Signals for Expected Results
  logic [SR_MAX_BIT:0] tb_expected_output;
  logic tb_test_data [];

  // Declare DUT Connection Signals
  logic                tb_clk;
  logic                tb_nRST;
  logic                tb_shift_enable;
  logic                tb_serial_in;
  logic                tb_parallel_load;
  logic [SR_MAX_BIT:0] tb_parallel_in;
  logic [SR_MAX_BIT:0] tb_parallel_out;

// Task for standard DUT reset procedure
  task reset_dut;
  begin
    // Activate the reset
    tb_nRST = 1'b0;

    // Maintain the reset for more than one cycle
    @(posedge tb_clk);
    @(posedge tb_clk);

    // Wait until safely away from rising edge of the clock before releasing
    @(negedge tb_clk);
    tb_nRST = 1'b1;

    // Leave out of reset for a couple cycles before allowing other stimulus
    // Wait for negative clock edges, 
    // since inputs to DUT should normally be applied away from rising clock edges
    @(negedge tb_clk);
    @(negedge tb_clk);
  end
  endtask

  // Task to cleanly and consistently check DUT output values
  task check_output;
    input string check_tag;
  begin
    tb_mismatch = 1'b0;
    tb_check    = 1'b1;
    if(tb_expected_output == tb_parallel_out) begin // Check passed
      $info("Correct parallel output %s during %s test case", check_tag, tb_test_case);
    end
    else begin // Check failed
      tb_mismatch = 1'b1;
      $error("Incorrect parallel output %s during %s test case", check_tag, tb_test_case);
    end

    // Wait some small amount of time so check pulse timing is visible on waves
    #(0.1);
    tb_check =1'b0;
  end
  endtask

  // Task to manage the timing of sending one bit through the shift register
  task send_bit;
    input logic bit_to_send;
  begin
    // Synchronize to the negative edge of clock to prevent timing errors
    @(negedge tb_clk);
    
    // Set the value of the bit
    tb_serial_in = bit_to_send;
    // Activate the shift enable
    tb_shift_enable = 1'b1;

    // Wait for the value to have been shifted in on the rising clock edge
    @(posedge tb_clk);
    #(PROPAGATION_DELAY);

    // Turn off the Shift enable
    tb_shift_enable = 1'b0;
  end
  endtask

  // Task to contiguosly send a stream of bits through the shift register
  task send_stream;
    input logic bit_stream [];
  begin
    // Coniguously stream out all of the bits in the provided input vector
    for(tb_bit_num = 0; tb_bit_num < bit_stream.size(); tb_bit_num++) begin
      // Send the current bit
      send_bit(bit_stream[tb_bit_num]);
    end
  end
  endtask

  task load_value;
    input [SR_MAX_BIT:0] value;
  begin
    @(negedge tb_clk);
    tb_parallel_in = value;
    tb_parallel_load = 1;

    @(posedge tb_clk);
    #(PROPAGATION_DELAY);
    tb_parallel_load = 0;
  end
  endtask

  // Clock generation block
  always begin
    // Start with clock low to avoid false rising edge events at t=0
    tb_clk = 1'b0;
    // Wait half of the clock period before toggling clock value (maintain 50% duty cycle)
    #(CLK_PERIOD/2.0);
    tb_clk = 1'b1;
    // Wait half of the clock period before toggling clock value via rerunning the block (maintain 50% duty cycle)
    #(CLK_PERIOD/2.0);
  end

/* verilator lint_off PINMISSING */

  // DUT Portmap
  socetlib_shift_reg #(.NUM_BITS(`SR_SIZE_BITS), .SHIFT_MSB(`MSB), .RESET_VAL(INACTIVE_VALUE)) DUT
                    (.clk(tb_clk), .nRST(tb_nRST), 
                    .serial_in(tb_serial_in), 
                    .shift_enable(tb_shift_enable),
                    .parallel_load(tb_parallel_load),
                    .parallel_in(tb_parallel_in),
                    .parallel_out(tb_parallel_out));

/* verilator lint_on PINMISSING */

  // Test bench main process
  initial begin
    $dumpfile("waveform.fst");
    $dumpvars(0, tb_socetlib_shift_reg);
    // Initialize all of the test inputs
    tb_nRST            = 1'b1; // Initialize to be inactive
    tb_serial_in        = 1'b1; // Initialize to inactive value
    tb_shift_enable     = 1'b0; // Initialize to be inactive
    tb_parallel_in      = '0;
    tb_parallel_load    = 0;
    tb_test_num         = 0;    // Initialize test case counter
    tb_test_case        = "Test bench initializaton";
    tb_stream_check_tag = "N/A";
    tb_bit_num          = -1;   // Initialize to invalid number
    tb_mismatch         = 1'b0;
    tb_check            = 1'b0;
    // Wait some time before starting first test case
    #(0.1);

    //TEST 1:
    tb_test_num  = tb_test_num + 1;
    tb_test_case = "Power on Reset";
    // Note: Do not use reset task during reset test case since we need to specifically check behavior during reset
    // Wait some time before applying test case stimulus
    #(0.1);
    // Apply test case initial stimulus
    tb_serial_in = 1'b0;
    tb_nRST     = 1'b0;

    // Wait for a bit before checking for correct functionality
    #(CLK_PERIOD * 0.5);

    // Check that internal state was correctly reset
    tb_expected_output = RESET_OUTPUT_VALUE;
    check_output("after reset applied");

    // Check that the reset value is maintained during a clock cycle
    #(CLK_PERIOD);
    check_output("after clock cycle while in reset");
    
    // Release the reset away from a clock edge
    @(negedge tb_clk);
    tb_nRST  = 1'b1;   // Deactivate the chip reset
    // Check that internal state was correctly keep after reset release
    #(PROPAGATION_DELAY);
    check_output("after reset was released");

    //TEST 2:
    tb_test_num  = tb_test_num + 1;
    tb_test_case = "Contiguous Zero Fill";
    tb_serial_in = 1'b1;
    reset_dut();

    // Define the test data stream for this test case
    tb_test_data = '{`SR_SIZE_BITS{1'b0}};

    // Define the expected result
    tb_expected_output = '0;

    // Contiguously stream enough zeros to fill the shift register
    send_stream(tb_test_data);

    // Check the result of the full stream
    check_output("after zero fill stream");

    //TEST 3:
    tb_test_num  = tb_test_num + 1;
    tb_test_case = "DisContiguous Zero Fill";
    tb_serial_in = 1'b1;
    reset_dut();

    // Define the test data stream for this test case
    tb_test_data = '{`SR_SIZE_BITS{1'b0}};

    // Bootstrap the expected output signal
    tb_expected_output = RESET_OUTPUT_VALUE;

    // Disconiguously stream out all of the bits in the provided input vector
    for(tb_bit_num = 0; tb_bit_num < tb_test_data.size(); tb_bit_num++) begin
      // Send the current bit
      send_bit(tb_test_data[tb_bit_num]);
      // Update expected output value
      tb_expected_output = {tb_expected_output[(SR_MAX_BIT-1):0], 1'b0};

      // Check that the current bit got pulled in
      $sformat(tb_stream_check_tag, "for bit %0d", tb_bit_num);
      check_output(tb_stream_check_tag);
      @(posedge tb_clk);
      $sformat(tb_stream_check_tag, "after bit %0d's pause", tb_bit_num);
      check_output(tb_stream_check_tag);

      // Add some spacing between the check and the start of the next bit
      #(0.25 * CLK_PERIOD);
    end
    //TEST 4:
    tb_test_num  = tb_test_num + 1;
    tb_test_case = "Contiguous One Fill";
    // Start out with inactive value and reset the DUT to isolate from prior tests
    tb_serial_in = 1'b1;
    reset_dut();

    // Define the test data stream for this test case
    tb_test_data = '{`SR_SIZE_BITS{1'b1}};

    // Define the expected result
    tb_expected_output = '1;

    // Contiguously stream enough zeros to fill the shift register
    send_stream(tb_test_data);

    // Check the result of the full stream
    check_output("after one fill stream");

    // TEST 5:
    tb_test_num ++;
    tb_test_case = "Parallel load random";

    tb_expected_output = (`SR_SIZE_BITS)'($urandom);
    load_value(tb_expected_output);

    check_output("after parallel load");

    $finish;

  end
endmodule