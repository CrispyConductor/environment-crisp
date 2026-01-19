function store_env --description "Store specific KEY=VALUE pairs from the environment into a file"
    set -l file $argv[1]
    if test -z "$file"
        echo "usage: store_env <filename> <variable1> [variable2] ..."
        return 1
    end
    echo '# Generated environment file' > $file
    for name in $argv[2..-1]
        if set -q $name
            eval set value \$$name
            echo "$name='$value'" >> $file
        end
    end
end

