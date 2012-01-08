#!/bin/sh
wordlist="$HOME/code/beale.wordlist.asc"
nrolls=5
downloadloc=http://world.std.com/~reinhold/beale.wordlist.asc

isint() {
	[ "$1" -eq "$1" ] 2>/dev/null;
}

while (( $# )); do
	case "$1" in
		-n|--nrolls)
			nrolls=$2
			shift
			;;
		-w|--wordlist)
			wordlist=$2
			shift
			;;
		--download)
			if command -v curl >/dev/null; then
				curl -s -O "$downloadloc"
				exit 0
			elif command -v wget >/dev/null; then
				wget -q "$downloadloc"
				exit 0
			else
				echo "No wget or curl available; could not download." >&2
			fi
			;;
		*)
			if isint "$1"; then
				nrolls=$1
			else
				echo "Unknown option $1" >&2
			fi
			;;
	esac
	shift
done

for (( i=0; i<$nrolls; ++i )); do
	# The sequence of rolls for this word
	rseq=
	for j in {1..5}; do
		# `od -N1 -An -i /dev/urandom` echos a random byte in decimal
		# notation (to the extent that /dev/urandom is random)
		let "roll=$(od -N1 -An -i /dev/urandom) * 6 / 256 + 1"
		rseq=$rseq$roll
	done
	# print out the word on the line for $rseq
	grep "^$rseq" "$wordlist" | cut -f2
done
