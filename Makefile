#.SUFFIXES: .erl .beam
#.erl.beam:
#	erlc -o ebin src/$$(basename $<)
all: src/session_simulation.erl
	erlc -o ebin $<
