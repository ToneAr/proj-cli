# Completions for proj command

# Helper function to get available domains
function __proj_domains
    set -l base_dir $PROJ_BASE
    if test -z "$base_dir"
        set base_dir "$HOME/Working"
    end

    # Extract domain names from *-projects directories
    for dir in $base_dir/*-projects
        if test -d "$dir"
            set -l domain (basename $dir | string replace -- '-projects' '')
            echo $domain
        end
    end
	# Extract domain names for resource-* directories
	for dir in $base_dir/resource-projects/resource-*
        if test -d "$dir"
            set -l domain (basename $dir | string replace -- 'resource-' '')
            echo $domain
        end
    end
end

# Helper function to get projects for a given domain
function __proj_projects -a domain
    set -l base_dir $PROJ_BASE
    if test -z "$base_dir"
        set base_dir "$HOME/Working"
    end

    set -l project_root
    set -l prefix

    switch $domain
        case "function"
            set project_root "$base_dir/resource-projects/resource-functions"
            set prefix "resource-function-"
        case "paclet"
            set project_root "$base_dir/resource-projects/resource-paclets"
            set prefix "resource-paclet-"
        case "*"
            set project_root "$base_dir/$domain-projects"
            set prefix "$domain-project-"
    end

    if test -d "$project_root"
        for proj in $project_root/$prefix*
            if test -d "$proj"
                basename $proj | string replace -- "$prefix" ''
            end
        end
    end
end

# Helper to check if we're completing a subcommand
function __proj_needs_command
    set -l cmd (commandline -opc)
    test (count $cmd) -eq 1
end

# Helper to check if we're completing a domain (after subcommand or as first arg)
function __proj_needs_domain
    set -l cmd (commandline -opc)
    set -l count (count $cmd)

    # proj <domain>
    if test $count -eq 1
        return 0
    end

    # proj <subcommand> <domain>
    if test $count -eq 2
        switch $cmd[2]
            case 'help' 'h'
                return 1
            case 'edit' 'e' 'add' 'a' 'open' 'o' 'find' 'f' 'new' 'n' 'delete' 'd'
                return 0
            case '*'
                # Could be a domain already
                return 1
        end
    end

    return 1
end

# Helper to check if we're completing a project name
function __proj_needs_project
    set -l cmd (commandline -opc)
    set -l count (count $cmd)

    # proj <domain> <project>
    if test $count -eq 2
        # Check if second arg is NOT a subcommand (meaning it's a domain)
        switch $cmd[2]
            case 'help' 'h' 'edit' 'e' 'add' 'a' 'open' 'o' 'find' 'f' 'new' 'n' 'delete' 'd'
                return 1
            case '*'
                return 0
        end
    end

    # proj <subcommand> <domain> <project>
    if test $count -eq 3
        switch $cmd[2]
            case 'edit' 'e' 'open' 'o' 'find' 'f' 'new' 'n' 'delete' 'd'
                return 0
        end
    end

    return 1
end

# Get the domain from command line for project completion
function __proj_get_domain
    set -l cmd (commandline -opc)
    set -l count (count $cmd)

    if test $count -eq 2
        # proj <domain>
        switch $cmd[2]
            case 'help' 'h' 'edit' 'e' 'add' 'a' 'open' 'o' 'find' 'f' 'new' 'n' 'delete' 'd'
                return
            case '*'
                echo $cmd[2]
        end
    else if test $count -ge 3
        # proj <subcommand> <domain>
        echo $cmd[3]
    end
end

# Disable file completions for proj
complete -c proj -f

# Subcommand completions
complete -c proj -n __proj_needs_command -a 'help' -d 'Show usage information'
complete -c proj -n __proj_needs_command -a 'open' -d 'Navigate to project directory'
complete -c proj -n __proj_needs_command -a 'edit' -d 'Open project in editor'
complete -c proj -n __proj_needs_command -a 'find' -d 'Find existing project'
complete -c proj -n __proj_needs_command -a 'new' -d 'Create new project'
complete -c proj -n __proj_needs_command -a 'add' -d 'Clone git repository as project'
complete -c proj -n __proj_needs_command -a 'delete' -d 'Delete project directory'

# Domain completions
complete -c proj -n __proj_needs_domain -a '(__proj_domains)' -d 'Project domain'

# Project name completions
complete -c proj -n __proj_needs_project -a '(__proj_projects (__proj_get_domain))' -d 'Project name'
