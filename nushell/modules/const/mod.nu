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
