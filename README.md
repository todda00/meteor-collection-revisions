Collection Revisions for Meteor
------------------------
The main purpose of this package is to retain revisions of collection documents and allow for the restore of those revisions.

Features
------------------------
- Saves a revision of the entire document when updates are made to it.
- Revisions are stored within a field of the document, so no extra publications or subscriptions are needed to get the revisions.
- Can specify how many revisions to keep per document, or keep unlimited
- Can specify to not create revisions for updates made within a certain amount of time since the last revision (helpful for autoform with autosave triggering multiple updates)
- Prune foregoing revisions upon restore
- Callback function that provides two parameters - the revision and modifier objects before the collection update. Returning false in the callback will cancel the creation of a revision.

Installation
------------------------
This uses some features in Mongo 2.6 and above, so Meteor 1.0.4+ is required.
```
meteor add nicklozon:collection-revisions
```

Usage
------------------------

After you define your collection with something like:
```
Collection = new Mongo.Collection("collection");
```

You can use CollectionRevisions a few different ways: (Foo is our collection)

#### Package Default options
```
Foo.attachCollectionRevisions();
```
This will use all defaults, either by your code in CollectionRevisions.defaults or the package defaults.

#### Define Global default options
```
CollectionRevisions.defaults.keep = 10;
CollectionRevisions.defaults.debug = true;
... define whatever options you want to override the package defaults
```
These will be used for all collections you attach the CollectionRevisions to.

#### Include any collection specific options
```
CollectionRevisions.Foo = {
  keep:10
  ignoreWithin: 1
  ignoreWithinUnit: 'minutes'
  ... define whatever options you want to override the global or package defaults
}

Foo.attachCollectionRevisions(CollectionRevisions.Foo);
```

Options
------------------------

Option | Default | Description
--- | --- | ---
field | 'revisions' | name of the field which will hold the document's revisions within itself  *String*
lastModifiedField | 'lastModified' | Name of the field storing the date / time the document was last modified *String*
ignoreWithin | false | If an update occurs within this timeframe since the last update, a new revision will not be created. Keep as false to capture all updates (no unit needed if false). *false or Number*
ignoreWithinUnit | 'minutes' | the unit that goes along with the ignoreWithin number. Ignored if ignoreWithin is false *(seconds/minutes/hours/etc)*
keep | true | Specify a number if you wish to only retain a limited number of revisions per document. True = retain all revisions. *Number or Boolean*
prune | false | Will delete the restored revision and all subsequent revisions. *Boolean* 
debug | false | Turn to true to get console debug messages.
callback | undefined | Allows custom code to be executed against the revision and modifier objects before updating the collection. Takes two parameters: ``function(error, result)``. Refer to the [node mongodb driver documentation](http://mongodb.github.io/node-mongodb-native/2.2/api/Collection.html#update).


Restoring a Revision
------------------------
A revision can be restored by calling CollectionRevisions.restore from either the client, server, or both. It will follow the same allow / deny permissions for an update, or use your own permissions and call CollectionRevisions.restore within a method call. If you want the simulation to run correctly on the client, the document needs to be published and the revisions field present.
```
CollectionRevisions.restore(collectionName, documentId, revision);
```
Parameter | Type | Description
--- | --- | ---
collectionName | String | This is the string name of your collection, ("Foo")
documentId | String | the _id of the document you want to restore
revision | revisionId or Object | Simplest form is to provide the revisionId stored within the revision, if you want to use specific data to restore, you can provide the revision object, overriding any fields you want to update the document to.
callback | Function | Callback function that is executed when the update is completed.

Showing a list of Revisions
------------------------
Example template code: (bootstrap)
```
*Inside of Document Context*
<ul class="list-group">
  <li class='list-group-item'>
    <div class='col-xs-12 col-sm-6'>
      {{moment lastModified 'dddd, MMMM Do YYYY, h:mm:ss a'}}
    </div>
    <div class='col-xs-12 col-sm-6'>
      <button type="button" class="btn btn-default btn-success btn-xs pull-right">
        Current Revision
      </button>
    </div>
    <div class='clearfix'></div>
  </li>
  {{#each revisions}}
    <li class='list-group-item'>
      <div class='col-xs-12 col-sm-6'>
        {{moment lastModified 'dddd, MMMM Do YYYY, h:mm:ss a'}}
      </div>
      <div class='col-xs-12 col-sm-6'>
        <button type="button" class="btn btn-default btn-primary btn-xs pull-right revertFoo">
          <i class="fa fa-undo"></i> Revert
        </button>
      </div>
      <div class='clearfix'></div>
    </li>
  {{/each}}
</ul>
```
This is also using a global helper I have for moment: (coffeescript)
```
Template.registerHelper 'moment', (date, format) ->
  date = moment(date)
  return date.format format
```

Example template event code: (coffeescript)
```
Template.fooRevisions.events
  'click .revertFoo': (e,t) ->
    #get the foo document _id
    foo = Template.parentData()

    #restore the revision
    CollectionRevisions.restore('Foo', foo._id, @revisionId) 
```

Callbacks
------------------------
Callback format is ``function(revision, modifier)``.

This can be used to make changes to the revision before it is saved. Example:
```js
CollectionRevisions.Employee = {
  callback: function(revision, modifier) {
    // This allows a custom field be inserted into the revision
    revision.dateTermination = modifier.$set.dateEffective;
  }
}
```

This can also be used to allow custom logic that negates creating a revision by returning false:
```js
CollectionRevisions.Employee = {
  callback: function(revision, modifier) {
    // Do no create a revision if the effective date did not change 
    if(revision.dateEffective.getTime() === modifier.$set.dateEffective.getTime())
        return false;
  }
}
```

Updates Using multi=true
------------------------
This package will not create revisions for Documents when an update is for multiple documents (multi=true)
