# ls commands
### Recent all files

### Recently modified directories
export def rlsd [] { ls -as | where type == dir and modified > ((date now) - 7day) | sort-by modified}

### Recently modified files
export def rls [] { ls -as | where modified > ((date now) - 7day) | sort-by modified}

### Recently modified directories in home directory
export def hrlsd [] { ls -as ~ | where type == dir and modified > ((date now) - 7day) | sort-by modified}

### Recently modified files in home directory
export def hrls [] { ls -as ~ | where modified > ((date now) - 7day) | sort-by modified}

#nunununununununununununununununununununununununununununununun # lol https://www.asciiart.eu/art-and-design/dividers
# yt-dlp

### Download music from youtube
export def --wrapped yt-tdlp-music [
    ...rest: string # URL and extra arguments to pass to yt-dlp
] {
    yt-dlp -f bestaudio -x --audio-format mp3 --audio-quality 320k --embed-thumbnail --add-metadata --parse-metadata "%(upload_date>%d.%m.%Y)s:%(meta_date)s" --add-metadata --postprocessor-args "-id3v2_version 3" ...$rest
}

#nunununununununununununununununununununununununununununununun
# journal

# Old journal - encrypted journal management
export def old-journal [
    file?: string  # Optional journal file path (defaults to today's date)
] {
    let journal_dir = $"($env.HOME)/.journal"
    let git_dir = $"($journal_dir)/.git"

    # Pull latest changes
    git --work-tree $journal_dir --git-dir $git_dir pull

    # Determine file path
    let journal_file = if ($file | is-empty) {
        $"($journal_dir)/(date now | format date '%Y-%m-%d').jmd"
    } else {
        $file
    }

    # Create temp file in /tmp (cleared on reboot)
    let tempfile = mktemp --tmpdir-path /tmp --suffix .md

    # Check if journal file exists - if not, temp file is already empty from mktemp
    if not ($journal_file | path exists) {
        print $"Creating new journal entry: ($journal_file)"
    } else {
        # Find available identity files and prompt for selection
        let identities = ls $"($env.HOME)/.age" | where name =~ "identity" and name =~ ".txt$" | get name
        let identity_file = $identities | input list "Select identity for decryption:"
        
        # Decrypt the file
        age -d -i $identity_file -o $tempfile $journal_file
    }

    # Edit with nvim
    nvim $tempfile

    # Encrypt the file back
    age -e -o $journal_file -r age1yubikey1qgnj33t5gvvckwp2wj0uyvekr9lf5k9vhqm5hw8p7m6lkyr0ue8mz7pczvh -r age1yubikey1qtk6dvr86lten62sh9s3tclkkewft696tgl6p9et40u69fu79kntqdm7um3 $tempfile

    # Clean up temp file
    rm $tempfile

    # Commit and push changes
    git --work-tree $journal_dir --git-dir $git_dir add -A
    git --work-tree $journal_dir --git-dir $git_dir commit -m "Edited journal"
    git --work-tree $journal_dir --git-dir $git_dir push
}

#nunununununununununununununununununununununununununununununun
# passage

# Fuzzy find and select a passage entry
export def --wrapped page [...args] {
    let prefix = ($env.PASSAGE_DIR? | default $"($env.HOME)/.passage/store")

    $env.FZF_DEFAULT_OPTS = ""

    let name = (
        glob $"($prefix)/**/*.age"
        | each { |it|
            $it
            | str replace $"($prefix)/" ""
            | str replace ".age" ""
        }
        | to text
        | fzf --height 40% --reverse --no-multi
        | str trim
    )

    passage ...$args $name
}

#nunununununununununununununununununununununununununununununun
# OpenCode auth.json provider swap utilities

# Swap a provider entry in OpenCode auth.json safely without reading/printing contents in Nushell.
# One of --from | --json | --file must be provided.
export def oc-auth-swap [
    target: string,                  # provider id to update, e.g. 'github-copilot'
    --from: string,                  # copy value from another provider key in auth.json
    --json: string,                  # inline JSON object for the provider value
    --file: path                     # path to a JSON file containing the provider object
] {
    let auth_path = $"($env.HOME)/.local/share/opencode/auth.json"

    # Validate flags: exactly one of --from, --json, --file
    let choices = (
        [ $from, $json, $file ]
        | where { |x| not ($x | is-empty) }
        | length
    )

    if $choices == 0 {
        error make { msg: "Provide exactly one of --from, --json, or --file" }
    }
    if $choices > 1 {
        error make { msg: "Use only one of --from, --json, or --file" }
    }

    # Ensure auth.json exists
    if not ($auth_path | path exists) {
        error make { msg: $"Auth file not found: ($auth_path)" }
    }

    # Backup current file
    cp $auth_path $"($auth_path).bak"

    # Perform update using Nushell structured JSON (open parses JSON automatically)
    let data = (open $auth_path)

    if not ($file | is-empty) {
        let obj = (open $file)
        $data | upsert $target $obj | to json | save -f $auth_path
    } else if not ($json | is-empty) {
        let obj = ($json | from json)
        $data | upsert $target $obj | to json | save -f $auth_path
    } else {
        # Ensure source key exists
        if not ($data | columns | any { |x| $x == $from }) {
            error make { msg: $"Source key not found in auth.json: ($from)" }
        }
        let obj = ($data | get $from)
        $data | upsert $target $obj | to json | save -f $auth_path
    }

    # Preserve restrictive permissions
    ^chmod 600 $auth_path
}

# Convenience: switch GitHub Copilot between work/personal entries kept in the same file.
# Expects keys 'github-copilot-work' and 'github-copilot-personal' to exist.
export def oc-copilot-use [
    which: string  # 'work' | 'personal'
] {
    let src = if $which == 'work' {
        'github-copilot-work'
    } else if $which == 'personal' {
        'github-copilot-personal'
    } else {
        error make { msg: "Use 'work' or 'personal'" }
    }
    oc-auth-swap 'github-copilot' --from $src
}

# Start OpenCode with Copilot profile selection. If 'work' is selected,
# force the model to github-copilot/gpt-5 and open chat; otherwise, just open chat.
export def oc-copilot-start [] {
    let choice = (["work", "personal"] | input list "Choose Copilot profile" | default "work")

    # Switch auth.json provider based on selection
    oc-copilot-use $choice

    # Launch OpenCode: force model for 'work', otherwise plain chat
    if $choice == 'work' {
        opencode -m github-copilot/gpt-5 -c
    } else {
        opencode -c
    }
}
