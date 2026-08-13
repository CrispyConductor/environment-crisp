function load_env --description "Load KEY=VALUE pairs from a file into the environment"
    # These files routinely hold API keys, so nothing here prints values. Pass
    # -v to list the names that were set.
    argparse v/verbose -- $argv
    or return 1

    set -l file $argv[1]
    if test -z "$file"
        echo "usage: load_env [-v] <filename>" >&2
        return 1
    end
    if not test -f "$file"
        echo "load_env: file not found: $file" >&2
        return 1
    end

    while read -l line
        # Trim and skip blanks
        set line (string trim -- $line)
        test -z "$line"; and continue

        # Skip full-line comments
        string match -qr '^\s*#' -- $line; and continue

        # Allow leading 'export '
        if string match -qr '^export\s+' -- $line
            set line (string replace -r '^export\s+' '' -- $line)
        end

        # Must look like KEY = VALUE (KEY starts with letter/_)
        string match -qr '^[A-Za-z_][A-Za-z0-9_]*\s*=' -- $line; or continue

        # Extract key and raw value, tolerate spaces around =
        set -l key (string replace -r '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=.*$' '$1' -- $line)
        set -l val (string replace -r '^\s*[A-Za-z_][A-Za-z0-9_]*\s*=\s*(.*)$' '$1' -- $line)

        # Handle quoting
        if string match -qr '^".*"\s*\$' -- (string join '' $val '$')
            # double-quoted -> strip outer quotes
            set val (string replace -r '^"(.*)"\s*$' '$1' -- $val)
        else if string match -qr "^'.*'\\s*\\\$" -- (string join '' $val '$')
            # single-quoted -> strip outer quotes, then undo the shell's
            # '\'' escape. These files have to stay valid shell, because
            # ~/.zshrc sources ~/.user_env_x.env directly, so store_env writes
            # single quotes escaped that way and this reverses it.
            set val (string replace -r "^'(.*)'\\s*\$" '$1' -- $val)
            set val (string replace -a -- "'\\''" "'" $val)
        else
            # unquoted -> trim whitespace
            set val (string trim -- $val)
        end

        # Handle special _IMPORT key for recursive loading
        if test "$key" = "_IMPORT"
            set import_file (string trim -- $val)
            # If a relative path, resolve it relative to the current file's directory
            if not string match -qr '^/' -- $import_file
                set import_file (string join '' (dirname $file) '/' $import_file)
            end
            if set -q _flag_verbose
                echo "load_env: importing $import_file" >&2
                load_env -v $import_file
            else
                load_env $import_file
            end
        else
            if set -q _flag_verbose
                echo "load_env: set $key" >&2
            end
            # Export
            set -gx -- $key $val
        end
    end < $file
end

