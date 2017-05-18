root = exports ? this

root.CollectionRevisions.restore = (collectionName, documentId, revision, cb) ->

  check(collectionName, String)
  check(documentId, String)
  check(revision, Match.OneOf(String, Object))

  # backwards compatibility
  if typeof Mongo is "undefined"
    mongo = {}
    mongo.Collection = Meteor.Collection
  else
    mongo = Mongo

  #Load the collection
  collection = mongo.Collection.get(collectionName)
  return false if !collection?

  #Grab the document
  doc = collection.findOne({_id:documentId})
  return false if !doc?

  #Load options
  opts = root.CollectionRevisions[collectionName] || {}
  _.defaults(opts, root.CollectionRevisions.defaults)

  #grab the revision if the revison is just an ID
  if typeof revision is 'string'
    revision = _.find doc[opts.field], (rev) ->
      return rev.revisionId is revision
    return false if !revision?

  #remove the revisionID
  delete revision.revisionId

  #get all document fields
  docKeys = _.keys(doc)
  #remove _id and revisions fields
  docKeys = _.without(docKeys,'_id',opts.field)

  #get all revision fields
  revKeys = _.keys(revision)

  #find keys that are present in the document that are not in the revision
  #these will be unset
  unsetFields = _.difference(docKeys,revKeys)

  #Tee up the modifier
  modifier = {}
  if !_.isEmpty revision
    modifier.$set = revision

  if unsetFields.length > 0
    modifier.$unset = {}
    _.each unsetFields, (field) ->
      modifier.$unset[field] = ""

  #update the document with the revision data and provide callback
  collection.update({_id:doc._id},modifier,cb)
  return