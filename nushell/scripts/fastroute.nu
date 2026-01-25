# Fast route - Add MikroTik mangle rules for domain A records
# Routes traffic to specific domains via wan1

# Resolve domain A records using dig
def get-a-records [domain: string]: nothing -> list<string> {
    let result = (do { dig +short A $domain } | complete)
    
    if $result.exit_code != 0 {
        print $"(ansi red)Error resolving ($domain): ($result.stderr)(ansi reset)"
        return []
    }
    
    $result.stdout
    | lines
    | where { |line| $line =~ '^\d+\.\d+\.\d+\.\d+$' }  # Filter only valid IPv4 addresses
}

# Add a single mangle rule to MikroTik router
def add-mangle-rule [
    ip: string
    domain: string
    --router: string = "192.168.10.1"
    --user: string = "admin"
    --dry-run
]: nothing -> record {
    let cmd = $"/ip/firewall/mangle/add chain=prerouting action=mark-routing new-routing-mark=to-wan1 passthrough=yes dst-address=($ip) dst-address-list=!local-networks log=no comment=\"quicky ($domain)\""
    
    if $dry_run {
        print $"(ansi yellow)[DRY-RUN](ansi reset) ssh ($user)@($router) ($cmd)"
        return { ip: $ip, domain: $domain, status: "dry-run" }
    }
    
    let result = (do { ssh $"($user)@($router)" $cmd } | complete)
    
    if $result.exit_code == 0 {
        print $"(ansi green)[OK](ansi reset) Added rule for ($ip) (($domain))"
        { ip: $ip, domain: $domain, status: "added" }
    } else {
        print $"(ansi red)[FAIL](ansi reset) Failed to add rule for ($ip): ($result.stderr)"
        { ip: $ip, domain: $domain, status: "failed", error: $result.stderr }
    }
}

# Main command to add fast route rules for a domain
export def fastroute [
    domain: string           # Domain to resolve and create rules for
    --router (-r): string = "192.168.10.1"  # MikroTik router IP
    --user (-u): string = "admin"            # SSH username
    --dry-run (-n)           # Show commands without executing
]: nothing -> table {
    print $"(ansi cyan)Resolving A records for ($domain)...(ansi reset)"
    
    let ips = get-a-records $domain
    
    if ($ips | is-empty) {
        print $"(ansi red)No A records found for ($domain)(ansi reset)"
        return []
    }
    
    print $"Found ($ips | length) IP addresses: ($ips | str join ', ')"
    print ""
    
    $ips | each { |ip|
        add-mangle-rule $ip $domain --router $router --user $user --dry-run=$dry_run
    }
}

# List existing quicky rules on the router
export def "fastroute list" [
    --router (-r): string = "192.168.10.1"
    --user (-u): string = "admin"
] {
    let result = (do { ssh $"($user)@($router)" '/ip/firewall/mangle/print where comment~"quicky"' } | complete)
    
    if $result.exit_code != 0 {
        print $"(ansi red)Error: ($result.stderr)(ansi reset)"
        return
    }
    
    print $result.stdout
}

# Remove fastroute rules for a specific domain
export def "fastroute remove" [
    domain: string           # Domain pattern to match in comments
    --router (-r): string = "192.168.10.1"
    --user (-u): string = "admin"
    --dry-run (-n)
]: nothing -> nothing {
    let cmd = $"/ip/firewall/mangle/remove [find where comment~\"quicky ($domain)\"]"
    
    if $dry_run {
        print $"(ansi yellow)[DRY-RUN](ansi reset) ssh ($user)@($router) ($cmd)"
        return
    }
    
    let result = (do { ssh $"($user)@($router)" $cmd } | complete)
    
    if $result.exit_code == 0 {
        print $"(ansi green)[OK](ansi reset) Removed rules for ($domain)"
    } else {
        print $"(ansi red)[FAIL](ansi reset) ($result.stderr)"
    }
}

# Remove all fastroute (quicky) rules
export def "fastroute clear" [
    --router (-r): string = "192.168.10.1"
    --user (-u): string = "admin"
    --dry-run (-n)
]: nothing -> nothing {
    let cmd = '/ip/firewall/mangle/remove [find where comment~"quicky"]'
    
    if $dry_run {
        print $"(ansi yellow)[DRY-RUN](ansi reset) ssh ($user)@($router) ($cmd)"
        return
    }
    
    let result = (do { ssh $"($user)@($router)" $cmd } | complete)
    
    if $result.exit_code == 0 {
        print $"(ansi green)[OK](ansi reset) Cleared all fastroute rules"
    } else {
        print $"(ansi red)[FAIL](ansi reset) ($result.stderr)"
    }
}
