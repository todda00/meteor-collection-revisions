root = exports ? this

CollectionRevisions.restore = (collectionName, documentId, revision) ->

  check(collectionName, String)
  check(documentId, String)
  check(revision, Match.OneOf(String, Object))

  #Load the collection
  collection = root[collectionName]
  return false if !collection?

  #Grab the document
  doc = collection.findOne({_id:documentId})
  return false if !doc?

  #Find out what field is in use for the revisions
  revisionField = CollectionRevisions[collectionName].field

  #grab the revision if the revison is just an ID
  if typeof revision is 'string'
    revision = _.find doc[revisionField], (rev) ->
      return rev.revisionId is revision
    return false if !revision?

  #remove the revisionID
  delete revision.revisionId

  #update the document with the revision revision data

  collection.update({_id:doc._id},{$set:revision})
  return