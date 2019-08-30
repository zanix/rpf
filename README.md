# rpf

Simple rsync profiler

### Table of Contents

* [Description](#description)
* [Example](#example)
* [Security](#security)

### <a name="description"></a> Description
With `rpf` you can create, save and run different rsync configurations via named profiles.

### <a name="example"></a> Example
Let's create new profile named 'backup' by typing `rpf -c backup`

Assume that our user name is `user`.

`rpf` creates following directories:
* `/home/user/.rpf`
* `/home/user/.rpf/shared` - here you can place config files shared by multiple profiles
* `/home/user/.rpf/profiles` - here all profiles are saved as subdirectories

So `rpf` created for us `/home/user/.rpf/profiles/backup`, that contains files `conf` and `excluded`.

`conf` defines rsync configuration:
```
# rsync config template
#
# Write each rsync option on separate line. For option details see man rsync.
# Empty lines and lines starting with # are ignored. Dynamic references
# (e.g. using command substitution) are not supported.
#
# Config files shared between different profiles should be saved in
# /home/user/.rpf/shared
#
# Example configuration:
#
--verbose
--archive
--human-readable
# exclude all files that match pattern in:
--exclude-from=/home/user/.rpf/profiles/backup/exclude
--relative
# perform trial run, make no changes
--dry-run
# source, e.g.
/home/user
# destination, e.g.
/mnt/usb_drive/users_backup
```
Now we can edit, add or remove rsync options as needed.

In `exclude` we can define paths or patterns of files and directories we want to exclude from transfer. To exclude `Trash` and `Downloads` add following lines:
```
- /home/user/.local/share/Trash
- /home/user/Downloads
```
Or transfer only `Documents` and `Projects` and exclude everything else:
```
+ /home/user/Documents
+ /home/user/Projects
- **
```
For subtler pattern configuration, see `man rsync`, section FILTER RULES, or google for tutorials.

When we are ready, we can start rsync transfer by typing `rpf backup`

That's it.

For additional `rpf` options see `rpf --help`.

### <a name="security"></a> Security
`rpf` is not secure against code injection in `conf` file. Any additional code (e.g. `; ./run_evil_script`) is also executed. Therefore, protect your `.rpf/` config directory from malicious users by appropriate permissions. Moreover, exploitation of this behavior can also lead to unexpected side effects.
