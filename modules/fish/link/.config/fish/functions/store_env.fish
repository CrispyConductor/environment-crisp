function store_env --description "Store specific KEY=VALUE pairs from the environment into a file"
	set -l file $argv[1]
	if test -z "$file"
		echo "usage: store_env <filename> <variable1> [variable2] ..." >&2
		return 1
	end

	echo '# Generated environment file' >$file

	for name in $argv[2..-1]
		if set -q $name
			# `set -l` keeps the temporary out of the global scope; the previous
			# version used a bare `eval set value ...` and leaked it.
			set -l value $$name
			# Single quotes inside the value would otherwise terminate the
			# quoting and produce a file load_env cannot read back.
			set -l escaped (string replace -a -- "'" "'\\''" "$value")
			echo "$name='$escaped'" >>$file
		end
	end
end
