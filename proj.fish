# Function to aid with project management
# Usage: `
# - proj [open] <domain> <project_name>
#   Open a project direectory in Neovim
#
# - proj find <domain> <search_term>
#   Find am existing project directory
#
# - proj new <domain> <project_name>
#   Create a new project directory
#
# - proj add <domain> <git-clone-url>
#   Add a gitrepository as a new project
#
# - proj delete <domain> <project_name>
#   Deletes the project directory`

# Main function

function proj
	switch $argv[1]
		case 'help' 'h'
			_print_usage
			return
		case 'edit' 'e'
			_edit_proj $argv
			return
		case 'add' 'a'
			_add_project $argv
			return
		case 'open' 'o'
			_open_proj $argv
			return
		case 'find' 'f'
			_search_proj $argv
			return
		case 'new' 'n'
			_new_proj $argv
			return
		case 'delete' 'd'
			_delete_proj $argv
			return
		case '*'
			if test (count $argv) -eq 2
				_open_proj $argv
				return
			end
			echo "Unknown command: $argv[1]"
			_print_usage
	end
end

# Help

function _print_usage
	echo "
Usage:
- proj [(o|open])] <domain> <project_name>
  Navigate to a project directory

- proj (e|edit) <domain> <project_name>
  Open a project directory in the default text editor

- proj (f|find) <domain> <search_term>
  Find am existing project directory

- proj (n|new) <domain> <project_name> [(-d|--desc) description] [(-v|--verbose)]
  Create a new project directory

- proj (a|add) <domain> <git-clone-url> [(-n|--name) project_name] [(-v|--verbose)]
  Add a git repository as a new project

- proj (d|delete) <domain> <project_name>
  Deletes the project directory
"
end

# Sub-functions

function _edit_proj
	_open_proj $argv
	$EDITOR .
end

function _add_project
	argparse 'n/name=' 'v/verbose' -- $argv
	set out
	set project_name
	if set -q _flag_verbose
		set out /dev/stdout
	else
		set out /dev/null
	end
	if set -q _flag_name
		set project_name $_flag_name
	else
		read -P "Enter project name: " project_name
	end
	if test -z "$project_name"
		set_color red
		echo -e "Project name cannot be empty"
		set_color normal
		return 1
	end
	set git_url $argv[3]
	set domain (_get_proj_domain $argv)
	set project_path (_get_proj_path $domain $project_name)
	if test -d $project_path
		set_color red
		echo -e "Project directory already exists: $project_path"
		set_color normal
		return 1
	end
	set parent_dir (dirname $project_path)
	if not test -d $parent_dir
		mkdir -p $parent_dir
	end
	git clone $git_url $project_path &> $out
	if test $status -eq 0
		set_color green
		echo "Project cloned to: $project_path"
		set_color normal
	else
		set_color red
		echo -e "Failed to clone repository"
		set_color normal
		return 1
	end
end

function _open_proj
	set project_path (_get_proj_path $argv)
	if test -d $project_path
		cd $project_path
	else
		set_color red
		echo -e "Project directory does not exist: $project_path"
		set_color normal
		return 1
	end
end

function _new_proj
	argparse 'd/desc=' 'v/verbose' -- $argv
	set out
	if set -q _flag_verbose
		set out /dev/stdout
	else
		set out /dev/null
	end
	set project_path (_get_proj_path $argv)
	set project_name (basename $project_path)
	if not test -d $project_path
		if set -q _flag_desc
			set project_description $_flag_desc
		else
			read -P "Enter project description: " project_description
			if test -z "$project_description"
				set_color red
				echo -e "Project description cannot be empty"
				set_color normal
				return 1
			end
		end
		mkdir -p $project_path
		cd $project_path
		echo "# $project_name" > README.md
		echo "" >> README.md
		echo "$project_description" >> README.md
		begin
			git init
			and git branch -M main
			and git add .
			and git commit -m "Initial commit"
		end > $out
		set_color green
		echo "Created project directory: $project_path"
		set_color normal
	else
		set_color red
		echo -e "Project directory already exists: $project_path"
		set_color normal
		return 1
	end
end

function _delete_proj
	set project_path (_get_proj_path $argv)
	if test -d $project_path
		read -P "Are you sure? [y/N]: " confirm
		if test (string match -ri '^y(es)?$' -- $confirm)
			rm -rf $project_path
			set_color green
			echo "Deleted project directory: $project_path"
			set_color normal
			return
		else
			set_color red
			echo -e "Aborted deletion"
			set_color normal
			return 1
		end
	else
		set_color red
		echo -e "Project directory not found: $project_path"
		set_color normal
		return 1
	end
end

function _search_proj
	set search_term ""
	if test (count $argv) -eq 3
		set search_term $argv[3]
	else if test (count $argv) -eq 2
		set search_term $argv[2]
	else
		echo "Usage: proj search <search_term>"
		return 1
	end
	set dirs $(_get_proj_root $argv)
	set found 0
	for dir in $dirs
		if test -d $dir
			for proj in (find $dir -maxdepth 1 -type d -iname "*$search_term*")
				if test $proj != $dir
					echo $proj
					set found 1
				end
			end
		end
	end
	if test $found -eq 0
		set_color red
		echo -e "No projects found matching: $search_term"
		set_color normal
	end
end

# Utilities

function _get_proj_base
	set -q PROJ_BASE; or set PROJ_BASE "$HOME/Working"
	echo $PROJ_BASE
end

function _get_proj_domain
	set domain
	if test (count $argv) -eq 2
		set domain $argv[1]
	else
		set domain $argv[2]
	end
	echo $domain
end

function _get_proj_root
	set domain (_get_proj_domain $argv)
	set base (_get_proj_base)
	if test $domain = "function"
		echo $base/resource-projects/resource-functions
		return
	end
	if test $domain = "paclet"
		echo $base/resource-projects/resource-paclets
		return
	end
	echo $base/$domain-projects
end

function _get_proj_name
	set name
	if test (count $argv) -eq 3
		set name $argv[3]
	else if test (count $argv) -eq 2
		set name $argv[2]
	end
	echo (string upper $name)
end

function _get_proj_path
	set domain (_get_proj_domain $argv)
	set project_name (_get_proj_name $argv)
	set project_root (_get_proj_root $argv)
	echo $project_root/$domain-project-$project_name
end

