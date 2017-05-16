Package.describe({
  name: 'nicklozon:collection-revisions',
  version: '0.3.2',
  // Brief, one-line summary of the package.
  summary: 'Keep revision history for collection documents and provide restore functionality.',
  // URL to the Git repository containing the source code for this package.
  git: 'https://github.com/nicklozon/meteor-collection-revisions.git',
  // By default, Meteor will default to using README.md for documentation.
  // To avoid submitting documentation, set this field to null.
  documentation: 'README.md'
});

Package.onUse(function(api) {
  api.use(['underscore', 'check', 'coffeescript@1.0.5','random@1.0.2','matb33:collection-hooks@0.7.6','momentjs:moment@2.9.0']);
  api.versionsFrom('1.0.4');
  api.addFiles(['collectionRevisions.coffee','restoreRevision.coffee']);
  api.export(['CollectionRevisions'], ['client', 'server']);
});
