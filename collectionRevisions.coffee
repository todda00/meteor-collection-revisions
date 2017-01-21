root = exports ? this
root.CollectionRevisions = {}

#Setup defaults
CollectionRevisions.defaults =
  field:'revisions' 
  lastModifiedField: 'lastModified'
  ignoreWithin: false
  ignoreWithinUnit: 'minutes'
  keep: true
  debug: false
  prune: false

# backwards compatibility
if typeof Mongo is "undefined"
  Mongo = {}
  Mongo.Collection = Meteor.Collection

Mongo.Collection.prototype.attachCollectionRevisions = (opts = {}) ->
  collection = @

  _.defaults(opts, CollectionRevisions.defaults)

  #Convert Keep = true to -1
  if opts.keep is true
    opts.keep = -1

  #Convert ignoreWithin = false to 0
  if opts.ignoreWithin is false
    opts.ignoreWithin = 0

  fields =
    field:String 
    lastModifiedField: String
    ignoreWithin: Number
    ignoreWithinUnit: String
    keep: Number
    debug: Boolean
    prune: Boolean

  check(opts,Match.ObjectIncluding(fields))

  collection.before.insert (userId, doc) ->
    crDebug(opts,'Begin before.insert')
    doc[opts.lastModifiedField] = new Date()

  collection.before.update (userId, doc, fieldNames, modifier, options) ->
    crDebug(opts,'Begin before.update')
    crDebug(opts,opts, 'Defined options')

    #Don't do anything if this is a multi doc update
    options = options || {}
    if options.multi
      crDebug(opts,"multi doc update attempted, can't create revisions this way, leaving.")
      return true

    modifier = modifier || {}
    modifier.$set = modifier.$set || {}

    #Unset the revisions field and _id from the doc before saving to the revisions
    delete doc[opts.field]
    delete doc._id
    doc.revisionId = Random.id()

    #See if this update occured more than the ignored time window since the last one
    #or the option is set to not ignore within
    #or the lastModified field is not present (collection created before this package was added)
    if moment(doc[opts.lastModifiedField]).isBefore(moment().subtract(opts.ignoreWithin,opts.ignoreWithinUnit)) or opts.ignoreWithin is 0 or !doc[opts.lastModifiedField]?
      #If so, add a new revision
      crDebug(opts,'Is past ignore window, creating revision')

      #Create new revision and set the last Modified date if pruning is not
      #enabled or the last Modified date is not already set
      if not opts.prune or not modifier.$set[opts.lastModifiedField]
        modifier.$set[opts.lastModifiedField] = new Date()
        modifier.$push = modifier.$push || {}
        modifier.$push[opts.field] = {$each: [doc], $position: 0}

        #See if we are limiting how many to keep
        if opts.keep > -1
          modifier.$push[opts.field].$slice = opts.keep

      #Pruning is enabled and the lastModifiedField is set which indicates a
      #restore is occuring, so prune the revision being restored and all
      #revisions after
      else
        modifier.$pull = modifier.$pull || {}
        modifier.$pull[opts.field] = modifier.$pull[opts.field] || {}
        modifier.$pull[opts.field][opts.lastModifiedField] = {
          $gte: modifier.$set[opts.lastModifiedField]
        }

      crDebug(opts,modifier,'Final Modifier')
    else
      crDebug(opts,"Didn't create a new revision")
    return    

  crDebug = (opts, item, label = '')->
    return if !opts.debug
    if typeof item is 'object'
      console.log "collectionRevisions DEBUG: " + label + '↓'
      console.log item
    else
      console.log "collectionRevisions DEBUG: " + label + '= ' + item
