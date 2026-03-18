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

#nunununununununununununununununununununununununununununununun
# ripgrep + fzf + bat

# Fuzzy search with ripgrep, preview with bat, and open in $EDITOR
export def --wrapped rgbat [query: string, ...args] {
    let preview = "bat --color=always --style=numbers --line-range :500 {1} | awk -v hl={2} '{if(NR==hl){gsub(/\\033\\[0m/,\"\\033[0;7m\");print $0 \"\\033[0m\"}else{print}}'"
    (^rg -n --no-heading --color=always $query ...$args |
    ^fzf --ansi --delimiter ':'
        --preview $preview
        --preview-window '+{2}-/2'
        --color 'hl+:reverse,hl:reverse'
        --bind 'ctrl-d:preview-half-page-down,ctrl-u:preview-half-page-up'
        --bind $"enter:become\(($env.EDITOR) {1} +{2}\)")
}

#nunununununununununununununununununununununununununununununun
# obsidian

# Add a todo item to Obsidian daily note
export def todo [
    ...text: string  # Text for the todo item
] {
    let content = $"- [ ] ($text | str join ' ')"
    obsidian daily:prepend $"content=($content)"
}

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
# force the model to github-copilot/gpt-5; extra args are forwarded to opencode.
export def --wrapped oc-copilot-start [...rest: string] {
    let choice = (["work", "personal"] | input list "Choose Copilot profile" | default "work")

    # Switch auth.json provider based on selection
    oc-copilot-use $choice

    # Launch OpenCode: force model for 'work', forward all extra args
    if $choice == 'work' {
        opencode -m github-copilot/gpt-5 ...$rest
    } else {
        opencode ...$rest
    }
}

#nunununununununununununununununununununununununununununununun
# models.dev API

# Fetch models from models.dev API and search through them interactively
#
# Usage:
#   list-models
#   list-models | get 0

export def list-models [] {
  # Fetch API data once and store in a variable
  print "Fetching models from models.dev..."
  let api_data = (http get https://models.dev/api.json)

  # Get available providers and let user select using selector
  let providers = ($api_data | columns)
  let selected_provider = ($providers | input list --fuzzy "Select provider:")

  # Get models for the selected provider
  let provider_data = ($api_data | get -o $selected_provider)
  if ($provider_data | is-empty) {
    print $"❌ Provider '($selected_provider)' not found"
    return
  }

  let models = ($provider_data | get -o models)
  if ($models | is-empty) {
    print $"❌ No models found for provider '($selected_provider)'"
    return
  }

  # Convert to table format
  let models_table = ($models | into record | transpose)

  # Get model names for fuzzy selection
  let model_names = ($models_table | get column0)

  # Let user fuzzy select from models
  let selected_model = ($model_names | input list --fuzzy $"Select model for ($selected_provider):")

  # Return the full details of selected model
  $models_table | where column0 == $selected_model | flatten | reject column0
}


#nunununununununununununununununununununununununununununununun
# zellij open tab with predefined layout and directory selection zoxide interactive

# Usage:
#  dev-tab --name "My Tab" --directory "~/projects"

export def dev-tab [
    --name (-n): string  # Optional tab name
    --directory (-d): string  # Optional starting directory
] {

    # Use zoxide interactive to select directory
    mut selected_dir = ""

    if ($directory | is-empty) {
        $selected_dir = (zoxide query --interactive)
    } else {
        $selected_dir = $directory
    }

    if ($selected_dir | is-empty) {
        print "No directory selected"
        return
    }

    # Change to the selected directory
    cd $selected_dir

    # Get the folder name for default tab name
    mut folder_name = (pwd | path basename)

    # Use provided name or default to folder name
    let tab_name = if ($name | is-empty) {
        $folder_name
    } else {
        $name
    }

    # Build and execute the zellij command
    let cmd = $"zellij action new-tab --layout dev-layout --name ($tab_name)"
    nu -c $cmd
}

#nunununununununununununununununununununununununununununununun
# Create a pull request in Azure DevOps with interactive commit message selection and optional auto-complete settings.
#
# Usage:
#  # create a PR with defaults, grab URL to clipboard, and prepend title of PR to an Obsidian note
#  create-pr | each {$in.url | pbcopy;  obsidian prepend file="Collections/Companies/COMPANY" content=$"($in.title)";}

# Create a pull request in Azure DevOps
export def create-pr [
    --source-branch: string = ""  # Source branch (defaults to current branch)
    --target-branch: string = "main"  # Target branch
    --org: string = ""  # Azure DevOps organization
    --project: string = ""  # Azure DevOps project
    --repo: string = ""  # Repository name
    --work-item: int = 0  # Work item ID to link to PR
    --auto-complete  # Enable auto-complete with post-completion options
] {
    # Check if PAT is set
    let pat = $env.AZURE_DEVOPS_PAT? | default ""
    if ($pat | is-empty) {
        print "Error: AZURE_DEVOPS_PAT environment variable not set"
        print "Set it with: $env.AZURE_DEVOPS_PAT = your_token"
        return
    }

    # Get current branch if not specified
    let current_branch = if ($source_branch | is-empty) {
        git branch --show-current | str trim
    } else {
        $source_branch
    }

    print $"Using source branch: ($current_branch)"

    # Get recent commit messages for title selection
    let commits = git log --oneline -10 | lines | each { |line|
        let hash = $line | split column " " | get column0 | get 0
        let message = $line | str replace $"($hash) " ""
        {
            hash: $hash
            message: $message
        }
    }

    if ($commits | is-empty) {
        print "Error: No commits found"
        return
    }

    # Select commit using fzf or manual selection
    let selected_commit = if (which fzf | is-not-empty) {
        let selection = $commits | each { |commit| $"($commit.hash) ($commit.message)" } | to text | fzf --prompt "Select commit for PR title: "
        if ($selection | is-empty) {
            print "No selection made"
            return
        }
        let hash = $selection | split column " " | get column0 | get 0
        $commits | where hash == $hash | get 0
    } else {
        # Fallback to manual selection
        print "Select a commit message for PR title:"
        $commits | enumerate | each { |item|
            print $"($item.index + 1): ($item.item.message)"
        }

        let selection = input "Enter selection (1-10): " | into int
        if ($selection < 1 or $selection > ($commits | length)) {
            print "Invalid selection"
            return
        }
        $commits | get ($selection - 1)
    }

    let title = $selected_commit.message

    print $"Selected title: ($title)"

    # Ask if description is needed
    let use_description = input "Use commit message as description? (y/N): " | str downcase
    let description = if ($use_description == "y" or $use_description == "yes") {
        $title
    } else {
        ""
    }

    # Extract org, project, and repo from git remote if not provided
    let remote_info = if ($org | is-empty) or ($project | is-empty) or ($repo | is-empty) {
        let remote_url = git remote get-url origin | str trim

        # Parse Azure DevOps URL patterns:
        # https://dev.azure.com/org/project/_git/repo
        # https://org@dev.azure.com/org/project/_git/repo
        # git@ssh.dev.azure.com:v3/org/project/repo
        if ($remote_url | str contains "dev.azure.com") {
            if ($remote_url | str starts-with "git@ssh.dev.azure.com") {
                # SSH format: git@ssh.dev.azure.com:v3/org/project/repo
                let parts = $remote_url | str replace "git@ssh.dev.azure.com:v3/" "" | split row "/"
                {
                    org: ($parts | get 0)
                    project: ($parts | get 1)
                    repo: ($parts | get 2)
                }
            } else {
                # HTTPS format: https://dev.azure.com/org/project/_git/repo
                let parts = $remote_url | str replace --regex "https://.*dev.azure.com/" "" | split row "/"
                {
                    org: ($parts | get 0)
                    project: ($parts | get 1)
                    repo: ($parts | get 3)  # Skip "_git" at index 2
                }
            }
        } else {
            { org: "", project: "", repo: "" }
        }
    } else {
        { org: $org, project: $project, repo: $repo }
    }

    # Use extracted values or prompt for missing ones
    let org_name = if ($org | is-empty) {
        if ($remote_info.org | is-empty) {
            input "Azure DevOps organization: "
        } else {
            print $"Using organization from git remote: ($remote_info.org)"
            $remote_info.org
        }
    } else {
        $org
    }

    let project_name = if ($project | is-empty) {
        if ($remote_info.project | is-empty) {
            input "Azure DevOps project: "
        } else {
            print $"Using project from git remote: ($remote_info.project)"
            $remote_info.project
        }
    } else {
        $project
    }

    let repo_name = if ($repo | is-empty) {
        if ($remote_info.repo | is-empty) {
            input "Repository name: "
        } else {
            print $"Using repository from git remote: ($remote_info.repo)"
            $remote_info.repo
        }
    } else {
        $repo
    }

    # Ask for work item if not provided
    let work_item_id = if ($work_item == 0) {
        let wi_input = input "Work item ID to link (leave empty to skip): "
        if ($wi_input | is-empty) {
            0
        } else {
            $wi_input | into int
        }
    } else {
        $work_item
    }

    # Create PR payload
    let payload = if ($work_item_id > 0) {
        let base_payload = {
            sourceRefName: $"refs/heads/($current_branch)"
            targetRefName: $"refs/heads/($target_branch)"
            title: $title
            description: $description
            workItemRefs: [
                {
                    id: $work_item_id
                }
            ]
        }

        if $auto_complete {
            $base_payload | merge {
                autoCompleteSetBy: {
                    id: "me"
                }
                completionOptions: {
                    transitionWorkItems: true
                    deleteSourceBranch: true
                }
            }
        } else {
            $base_payload
        }
    } else {
        let base_payload = {
            sourceRefName: $"refs/heads/($current_branch)"
            targetRefName: $"refs/heads/($target_branch)"
            title: $title
            description: $description
        }

        if $auto_complete {
            $base_payload | merge {
                autoCompleteSetBy: {
                    id: "me"
                }
                completionOptions: {
                    transitionWorkItems: true
                    deleteSourceBranch: true
                }
            }
        } else {
            $base_payload
        }
    }

    # Create authorization header
    let auth_string = $":($pat)" | encode base64
    let url = $"https://dev.azure.com/($org_name)/($project_name)/_apis/git/repositories/($repo_name)/pullrequests?api-version=7.0"

    print "Creating pull request..."
    print $"URL: ($url)"
    print $"Source: ($current_branch) -> Target: ($target_branch)"
    if $auto_complete {
        print "Auto-complete enabled: will complete work items and delete source branch"
    }
    if ($work_item_id > 0) {
        print $"Linking work item: ($work_item_id)"
    }

    # Make the API request with error handling
    let response = try {
        http post $url ($payload | to json) --headers {
            "Authorization": $"Basic ($auth_string)"
            "Content-Type": "application/json"
        }
    } catch { |err|
        # Try to get the response body for more details
        let detailed_response = try {
            http post $url ($payload | to json) --headers {
                "Authorization": $"Basic ($auth_string)"
                "Content-Type": "application/json"
            } --allow-errors
        } catch { |inner_err|
            null
        }

        if ($detailed_response != null) {
            print $"❌ API Error: ($err)"
            print $"Response body: ($detailed_response | to json --indent 2)"
        } else {
            print $"❌ Network Error: ($err)"
        }
        return
    }

    # Handle response
    if ($response != null) {
        if ($response | get -o pullRequestId | is-not-empty) {
            let pr_id = $response | get pullRequestId
            let pr_url = $"https://dev.azure.com/($org_name)/($project_name)/_git/($repo_name)/pullrequest/($pr_id)"
            print $"✅ Pull request created successfully!"

            # Return structured data for piping
            {
                id: $pr_id
                url: $pr_url
                title: $title
                source_branch: $current_branch
                target_branch: $target_branch
            }
        } else {
            print "❌ Unexpected response format"
            print $"Response: ($response | to json --indent 2)"
            null
        }
    } else {
        null
    }
}
