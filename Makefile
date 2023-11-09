# Example Makefile
# Learn more at https://projectf.io/posts/building-ice40-fpga-toolchain/

# configuration
PROJ = riscv_from_scratch
FPGA_PKG = sg48
FPGA_TYPE = up5k
PCF = upduino3.pcf
ADD_SRC = processor.v memory.v clockworks.v
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
	sudo /home/user/oss-cad-suite/libexec/iceprog ${PROJ}.bin -X

sim:
	iverilog -DBENCH -DBOARD_FREQ=10 -o build/sim bench_iverilog.v top.v
	vvp build/sim

clean:
	rm -f ${PROJ}.json ${PROJ}.asc ${PROJ}.bin
.PHONY: all clean prog sim
