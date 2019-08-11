# rpf

Simple rsync profiler

## Description
With rpf you can store different rsync configurations in named profiles.

## Example
Let's create new profile named 'backup'. Create the profile by typing
`rpf -c backup`

`rpf` created couple of templates in `/home/joe/.rpf/profiles/backup` in our home directory. Assume, that our user name is `joe`.

Default rsync configuration template `conf` looks like this:
```# rsync config template
#
# Write each rsync option on separate line. For details see man rsync.
# Empty lines and lines starting with # are ignored. Dynamic references
# (e.g. using command substitution) are not supported.
#
# Config files shared between different profiles should be saved in
# ${shared_dir}
#
# Example configuration:
#
--verbose
--archive
--human-readable
# file with patterns of files and directories in source excluded
# from transfer
--exclude-from="${profiles_dir}/${profile_name}/exclude"
--relative
# perform trial run, make no changes
--dry-run
# source, e.g.
/home/joe
# destination, e.g.
/mnt/usb_drive/joes_backup
```
Now we can edit, add or remove rsync options (for details see `man rsync`) as needed.

If we want to exclude some files or directories in `joe`'s home from rsync transfer, we can update `exclude` file, that looks like this:
```# `exclude' template
#
# Lines starting with # or ; are ignored. For details see man rsync,
# section FILTER RULES.
#
```
Add following lines:
```
- /home/joe/.local/share/Trash
- /home/joe/Downloads
- /home/joe/not_importatnt
```
Joe's directories `Trash`, `Downloads` and `not_importatnt` will not be transfered by rsync to the destination. (Excluded patterns can be much more complex. See `man rsync`, section FILTER RULES).

Now we are ready to run start rsync transfer by typing
`rpf backup`

That's it.

For additional `rpf` options see `rpf --help`.
