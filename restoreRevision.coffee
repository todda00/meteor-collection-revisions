root = exports ? this

root.CollectionRevisions.restore = (collectionName, documentId, revision) ->

  check(collectionName, String)
  check(documentId, String)
  check(revision, Match.OneOf(String, Object))

  #Load the collection
  collection = root[collectionName]
  return false if !collection?

  #Grab the document
  doc = collection.findOne({_id:documentId})
  return false if !doc?

  #Load options
  opts = CollectionRevisions[collectionName] || {}
  _.defaults(opts, CollectionRevisions.defaults)

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

  #update the document with the revision data
  collection.update({_id:doc._id},modifier)
  return