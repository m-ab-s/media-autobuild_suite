Updating the suite
====

There are two methods for keeping the suite updated, neither are
fully automated but one is maybe easier to do.
Either one you use, it's highly recommended you do them *before*
running the suite since issues are probably fixed in newer versions.

## Using snapshots from Github


The simpler way but harder to keep track of your changes.
Just click [Download ZIP](https://github.com/jb-alvarado/media-autobuild_suite/archive/master.zip)
in the homepage of the repository in Github and replace all files
inside the suite directory with the new ones.

If you have changes you have to keep track of them manually.

## Using git


#### If you didn't already use git clone to get this repository
 - 1. Open mintty using the shortcut
 - 2. Go to `/trunk/build` and run `git clone https://github.com/jb-alvarado/media-autobuild_suite.git`
 - 3. Run `mv media-autobuild_suite/.git /trunk/`

You should now be able to `cd /trunk` and something should show up when doing `git status`
You have now turned your copy into a copy of the repository!

If you had modified the files in any way it's probably best to check with `git diff` and maybe export the
changes to a file using `git diff > mychanges.diff`

After exporting the diff you can now use `git reset --hard origin/master`
to get the most updated version of the repository files.

The diff may contain more than your changes so if you want to apply them again,
create a new branch by running `git checkout -b mychanges`. This command also changed the current branch
to `mychanges` so you can now add your changes again.

After reapplying the changes, run `git commit` so your changes are kept in that branch.

Now everytime you want to update the suite, all you'll have to do is:
 - 1. `git checkout master`
 - 2. `git pull origin master`
 - 3. If you had changes:
  - 1. `git checkout mychanges`
  - 2. `git rebase master`
  - 3. If it worked, your branch is now updated and with your changes
  - 4. If it didn't, check online for the problem.

I recommend reading Github's git guides to learn how to use it, it's a very powerful tool.