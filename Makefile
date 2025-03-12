darker-cavern.wasm: darker-cavern.scm
	guild compile-wasm -L modules -o darker-cavern.wasm darker-cavern.scm

all: darker-cavern.wasm

serve: darker-cavern.wasm
	guile -c '((@ (hoot web-server) serve))'

.PHONY: serve
