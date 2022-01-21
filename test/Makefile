TESTS=Logger
TARGETS=$(TESTS:%=run/%)
OBJS=$(TESTS:%=dist/%.wasm)

all: $(TARGETS)

run/%: dist/%.wasm
	wasmtime $<

dist:
	@mkdir -p $@

dist/%.wasm: %.mo ../src/%.mo | dist
	moc $$(vessel sources) -wasi-system-api -o $@ $<

clean:
	rm -rf dist

.PHONY: all clean
.PRECIOUS: ${OBJS}
