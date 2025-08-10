all:
	$(MAKE) -C src/

install:
	pip install .

clean:
	$(MAKE) -C src/ clean
	rm -f emopt/*.so



