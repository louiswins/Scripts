#!/bin/sh
WORDLIST=$HOME/code/beale.wordlist

isint() {
	[ "$1" -eq "$1" 2>/dev/null ];
}

if [ $# -ge 1 ] && isint "$1"; then
	nrolls=$1;
else
	nrolls=5;
fi

if [ $# -ge 2 -a -f "$2" ]; then
	WORDLIST=$2
fi

for (( i=0; i<$nrolls; ++i )); do
	# The sequence of rolls for this word
	rseq=;
	for j in {1..5}; do
		# `od -N1 -An -i /dev/urandom` echos a random byte in decimal
		# notation (to the extent that /dev/urandom is random)
		let "roll=$(od -N1 -An -i /dev/urandom)*6 / 256 + 1";
		rseq="$rseq$roll";
	done;
	# print out the word on the line for $rseq
	grep "^$rseq" $WORDLIST | cut -f2
done
