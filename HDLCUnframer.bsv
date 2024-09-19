import GetPut::*;
import FIFOF::*;
import Assert::*;

interface HDLCUnframer;
    interface Put#(Bit#(1)) in;
    interface Get#(Tuple2#(Bool, Bit#(8))) out;
endinterface

module mkHDLCUnframer(HDLCUnframer);
    // Sugestão de elementos de estado (podem ser alterados caso conveniente)
    FIFOF#(Tuple2#(Bool, Bit#(8))) fifo_out <- mkFIFOF;
    Reg#(Bool) start_of_frame <- mkReg(True);
    Bit#(9) octet_reset_value = 9'b1_0000_0000;
    Reg#(Bit#(9)) octet <- mkReg(octet_reset_value);
    Reg#(Bit#(6)) flag_detector <- mkReg(0);

    interface out = toGet(fifo_out);

    interface Put in;
        method Action put(Bit#(1) b);
            let next_octet = octet >> 1 | extend(b) << 8;
            let next_flag_detector = {flag_detector[4:0], b};
            let next_start_of_frame = start_of_frame;

            if (next_flag_detector == 6'b111110) begin
                next_octet = octet; // Manter o octeto atual
            end else if (next_flag_detector[5:0] == 6'b111111 && b == 1) begin
                // Flag detectada
                next_octet = octet_reset_value;
                next_start_of_frame = True;
            end

            if (next_octet[0] == 1'b1) begin
                // Byte completo
                fifo_out.enq(tuple2(start_of_frame, next_octet[8:1]));
                next_octet = octet_reset_value;
                next_start_of_frame = False;
            end

            octet <= next_octet;
            flag_detector <= next_flag_detector;
            start_of_frame <= next_start_of_frame;
        endmethod
    endinterface
endmodule