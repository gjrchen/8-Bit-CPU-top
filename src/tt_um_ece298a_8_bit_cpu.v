/*
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

//`include "control_block.v"
//`include "program_counter.v"

module tt_um_ece298a_8_bit_cpu_top (
    input  wire [7:0] ui_in,        // Dedicated inputs
    output wire [7:0] uo_out,       // Dedicated outputs
    input  wire [7:0] uio_in,       // IOs: Input path
    output wire [7:0] uio_out,      // IOs: Output path
    output wire [7:0] uio_oe,       // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,          // always 1 when the design is powered, so you can ignore it
    input  wire       clk,          // clock
    input  wire       rst_n         // reset_n - low to reset
);
    // Bus //
    wire [7:0] bus;                 // Bus (8-bit) (High impedance when not in use)
    wire [3:0] bus4bit;             // 4-bit Bus (lower 4 bits of the 8-bit Bus) (High impedance when not in use)
    assign bus4bit = bus[3:0];      // Assign 4-bit Bus to the lower 4 bits of the 8-bit Bus 
    wire outputting_to_bus;         // Signal to determine when nothing is outputting to the bus

    // Tri-state buffer to initialize the bus with a known value //
    assign bus = (outputting_to_bus) ? 8'bZZZZZZZZ : 8'b00000000; // Initialize the bus with a known value if nothing is outputting to the bus
   

    // Control Signals //
    wire [14:0] control_signals;        // Control Signals (15-bit), see below for the signal assignments

    // Wires //
    wire [3:0] opcode;                  // opcode from IR to Control
    wire [7:0] reg_a;                   // value from Accumulator Register to ALU
    wire [7:0] reg_b;                   // value from B Register to ALU
    
    // ALU Flags //
    wire CF;                            // Carry Flag
    wire ZF;                            // Zero Flag
    
    // Wire between MAR and RAM //
    wire [7:0] mar_to_ram_data;         //
    wire [3:0] mar_to_ram_addr;         //

    // Wires for Programmer //
    wire programming = uio_in[0];
    wire new_byte = uio_in[1];
    wire [14:0] programmer_control_signals;
    wire [14:0] controller_control_signals;

    assign control_signals = programming ? programmer_control_signals : controller_control_signals;

    // Control Signals for the Program Counter //
    wire Cp = control_signals[14];      // 
    wire Ep = control_signals[13];      // 
    wire Lp = control_signals[12];      // 

    // Control Signals for the RAM //
    wire nLma = control_signals[11];    // 
    wire nLmd = control_signals[10];    // 
    wire nCE = control_signals[9];      // 
    wire nLr = control_signals[8];      // 

    // Control Signals for the Instruction Register //
    wire nLi = control_signals[7];      // enable Instruction Register load from bus (ACTIVE-LOW)
    wire nEi = control_signals[6];      // enable Instruction Register output to the bus (ACTIVE-LOW)
    
    // Control Signals for the Accumulator Register //
    wire nLa = control_signals[5];      // enable Accumulator Register load from bus (ACTIVE-LOW)
    wire Ea = control_signals[4];       // enable Accumulator Register output to the bus (ACTIVE-HIGH)

    // Control Signals for the ALU //
    wire sub = control_signals[3];      // perform addition when 0, perform subtraction when 1
    wire Eu = control_signals[2];       // enable ALU output to the bus (ACTIVE-HIGH)
    
    // Control Signals for the B Register //
    wire nLb = control_signals[1];      // enable B Register load from bus (ACTIVE-LOW)
    
    // Control Signals for the Output Register //
    wire nLo = control_signals[0];      // 

    // Control Signals for the Bus Initialization //
    assign outputting_to_bus = (Ep | (!nCE) | (!nEi) | Ea | Eu); // Figure out when nothing is outputting to the bus   

    // Program Counter //
    ProgramCounter pc(
        .bits_in(bus4bit),      //
        .bits_out(bus4bit),     //
        .clk(clk),              //
        .clr_n(rst_n),          //
        .lp(Lp),                //
        .cp(Cp),                //
        .ep(Ep)                 //
    );
    
    control_block cb(
        .clk(clk),                  //
        .resetn(rst_n),             //
        .opcode(opcode[3:0]),       //
        .out(controller_control_signals) //
    );
    

    // ALU //
    alu alu_object(
        .clk(clk),              // Clock (Rising edge) (needed for storing CF and ZF)
        .enable_output(Eu),     // Enable ALU output to the bus (ACTIVE-HIGH)
        .reg_a(reg_a),          // Register A (8 bits)
        .reg_b(reg_b),          // Register B (8 bits)
        .sub(sub),              // Perform addition when 0, perform subtraction when 1
        .bus(bus),              // Bus (8 bits)
        .CF(CF),                // Carry Flag
        .ZF(ZF)                 // Zero Flag
    );
    
    // Accumulator Register //
    accumulator_register accumulator_object(
        .clk(clk),              // Clock (Rising edge)
        .bus(bus),              // Bus (8 bits)
        .load(nLa),             // Enable Accumulator Register load from bus (ACTIVE-LOW)
        .enable_output(Ea),     // Enable Accumulator Register output to the bus (ACTIVE-HIGH)
        .regA(reg_a),           // Register A (8 bits)
        .rst_n(rst_n)           // Reset (ACTIVE-LOW)
    );


    // Input and MAR Register //
    input_mar_register input_mar_register(
        .clk(clk),              //
        .n_load_data(nLmd),     //
        .n_load_addr(nLma),     //
        .bus(bus),              //
        .data(mar_to_ram_data), //
        .addr(mar_to_ram_addr)  //
    );

    // Instruction Register //
    instruction_register instruction_register(
        .clk(clk),              //
        .clear(~rst_n),         //
        .n_load(nLi),           //
        .n_enable(nEi),         //
        .bus(bus),              //
        .opcode(opcode)         //
    );
    
    // B Register //
    register b_register(
        .clk(clk),              //
        .n_load(nLb),           //
        .bus(bus),              //
        .value(reg_b)           //
    );
    
    // Output Register //
    register output_register(
        .clk(clk),              //
        .n_load(nLo),           //
        .bus(bus),              //
        .value(uo_out)          //
    );

    // RAM //
    tt_um_dff_mem #(
    .RAM_BYTES(16)                  // Set the RAM size to 16 bytes
    ) ram (
        .addr(mar_to_ram_addr),     //
        .data_in(mar_to_ram_data),  // 
        .data_out(bus),             //
        .lr_n(nLr),                 //
        .ce_n(nCE),                 // Connect the chip enable signal
        .clk(clk),                  // Connect the clock signal
        .rst_n(rst_n)               // Connect the reset signal
    );

    // Programmer //
    programmer programmer(
        .clk(clk),
        .resetn(rst_n),
        .ui_in(ui_in),
        .programming(programming),
        .new_byte(new_byte),
        .bus(bus),
        .out(programmer_control_signals)  
);
        
    // Wires //
    assign uio_out = 8'h00;         // Set the IO outputs to 0
    assign uio_oe = 8'h00;          // Configure the IO ports to be inputs

    wire _unused = &{uio_in[7:2], ena, ZF, CF}; // Avoid unused variable warning

endmodule
