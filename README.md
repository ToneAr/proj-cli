# PROJ CLI (Fish)
Fish utility function for project navigation in a structured
work repository.

## Usage
| Form | Description |
| ---- | ----------- |
| `proj [(o\|open])] <domain> <project_name>` | Navigate to a project directory |
| `proj (e\|edit) <domain> <project_name>`    | Open a project directory in the system editor |
| `proj (f\|find) <domain> <search_term>`     | Find am existing project directory |
| `proj (n\|new) <domain> <project_name> [(-d\|--desc) description]  [(-v\|--verbose)]`  | Create a new project directory |
| `proj (a\|add) <domain> <git-clone-url> [(-n\|--name) project_name] [(-v\|--verbose)]` | Add a git repository as a new project |
| `proj (d\|delete) <domain> <project_name>`  | Deletes the project directory |


## Work repository structure
By default, `PROJ_BASE` is set to `$HOME/Working`, however, it
can be changed by setting the `PROJ_BASE` environment variable.

```directory
$PROJ_BASE
├─ $DOMAIN-projects
┆  └─ $DOMAIN-project-$PROJECT_NAME
└─ resource-projects
   ├─ function-projects
   └─ paclet-projects
```
