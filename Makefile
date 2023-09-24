# Example Makefile
# Learn more at https://projectf.io/posts/building-ice40-fpga-toolchain/

# configuration
PROJ = riscv_from_scratch
FPGA_PKG = sg48
FPGA_TYPE = up5k
PCF = upduino3.pcf
ADD_SRC =
TOP = top.v

all: ${PROJ}.bin

%.bin: %.asc
	icepack ${PROJ}.asc > ${PROJ}.bin

%.asc: %.json ${PCF}
	nextpnr-ice40 --${FPGA_TYPE} --package ${FPGA_PKG} --json ${PROJ}.json --pcf ${PCF} --asc ${PROJ}.asc

%.json: ${TOP} ${ADD_SRC}
	case "${TOP}" in \
		*.v) yosys -p "read_verilog ${TOP}" -p "opt" -p "synth_ice40" -p "write_json ${PROJ}.json" ;; \
		*.vhdl) yosys -m ghdl -p "ghdl ${TOP} -e top" -p "opt" -p "synth_ice40" -p "write_json ${PROJ}.json" ;; \
	esac

prog:
	iceprog ${PROJ}.bin

clean:
	rm -f ${PROJ}.json ${PROJ}.asc ${PROJ}.bin
.PHONY: all clean prog
