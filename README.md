# duke-authentication-oauth2-spec

Rspec Test specifications for any [Duke Authentication Service Oauth2 Implementation](https://github.com/Duke-Translational-Bioinformatics/duke-authentication-service)

This repository is meant to be [pulled into](#integration) any application that intends on acting
as an OAUTH2 Duke Authentication Service.

Integration
===
Your implementation must use ruby (>= 2.2.2) and rspec (version >= 3.3.1).
The tests in this repository are meant to be merged into your application
using a [git subtree merge](https://git-scm.com/book/en/v1/Git-Tools-Subtree-Merging)
involving just the spec [subdirectory](http://bneijt.nl/blog/post/merge-a-subdirectory-of-another-repository-with-git/) of this repository.

```
cd path/to/your-application
git remote add oauth2_spec git@github.com:Duke-Translational-Bioinformatics/duke-authentication-oauth2-spec.git
git fetch oauth2_spec
git checkout -b oauth2_spec oauth2_spec/master
# checkout a branch in your application
git checkout develop
# start a merge that stops and waits for you to add actual files to merge
git merge -s ours --no-commit oauth2_spec/master
# note, this should not have made any changes to your branch
git status
# read just the spec directory into your branch, this will change things
git read-tree --prefix=spec -u oauth2_spec/master:spec
# use git status to figure out what needs to be added/removed to your branch
git status
git add ...
git commit
```

**NOTE** Make sure that you include the oauth2_spec/master:spec in that read-tree,
otherwise, it will pull in and overwrite your README.md and/or LICENSE.

Any time changes are made to this repository, you should merge these changes into your
application, and run rspec to ensure that your implementation meets its specifications.

Giving Back
===
If you find that changes need to be made to the common OAUTH2 spec, you can create
a commit in a branch of your application repository which only includes changes
to one or more files in this repository (**do not** include changes to other files in
the commit). You can then do a [cherry-pick](https://git-scm.com/docs/git-cherry-pick) into the oauth2_spec branch in your repo.
Then you can either push these changes to the official repo, or you can push them to your
personal fork of this repository, and submit a pull request to the official repository.

Run the following after committing code to your repo in a branch
```
# get the latest commit hash
last_commit=`git log -1 --format="%H"`
git checkout oauth2_spec
git cherry-pick --no-commit --no-ff ${last_commit}
# make sure everything is as expected
git status
git add/rm
git commit
git push
```
