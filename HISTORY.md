HISTORY.md

### v0.3.2
  - Fixed issue when callback option was not defined - it should be allowed to be undefined/null.
  - Code cleanup

### v0.3.1
  - Added export for CollectionRevisions, fixed references when using export

### v0.3.0
  - Fixed bug for restoring revision when revisions field is not set for collection
  - Added a revision prune feature which will remove restored revision and all revisions after it
  - Added feature for callbacks

### v0.2.1
  - Add required dependencies to package.js

### v0.2.0
  - Changed restore logic to unset fields present in the current revision when restoring an older revision without those fields.

### v0.1.0
  - Initial Package
