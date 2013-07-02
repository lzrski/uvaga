###

Stakeholders controller
=======================

This controlls /stakeholders/ urls, that are related to stakeholders (so called users), as you can guess.

###

Stakeholder = require "../models/Stakeholder"
Issue       = require "../models/Issue"
_           = require "underscore"
async       = require "async"
controller  = require "../access-control"
$           = require "../debug"

save = (slug) ->
  # Used in POST of /stakeholders/ and /stakeholders/:slug
  create = not slug?

  data = _.pick @req.body, [
    "name"
    "image"
    "telephone"
    "occupation"
    "groups"
  ]
  if typeof data.groups is "string"
    data.groups = data.groups.split /; ?/
  if create 
    data.email = @req.session.username
    $ "New stakeholder's data:"
    $ data
  else
    $ "Updating stakeholder #{slug} with new data" 
    $ data

  async.waterfall [
    (done) =>
      # 1. Retrive or create new stakeholder
      if create then Stakeholder.findOne
        email: @req.session.username,
        (error, stakeholder) =>
          # Make sure agent is not trying to create new stakeholder document, while one exists already
          if stakeholder? then done new Error """ 
              This e-mail (#{stakeholder.email}) is already in use.
              You cannot create more then one profile.
              Would you rather
              <a href='/stakeholders/#{stakeholder.slug}'>
              make changes to the one you already have
              </a>?
            """
          done null, new Stakeholder data
      else Stakeholder.findOne { slug }, (error, stakeholder) ->
        if not stakeholder? then done new Error """
          No such stakeholder: #{slug}.
          Stakeholder update requested, but wrong url was used.
        """          
        for attribute, value of data
          stakeholder[attribute] = value
        done null, stakeholder

    # 2. Save stakeholder's data
    (stakeholder, done) =>
      stakeholder.save (error) => 
        # Update session data
        if @req.session.stakeholder.slug is stakeholder.slug and not error
          @req.session.stakeholder = stakeholder
        done error
  ], (error) =>
    if error
      $ "Error saving stakeholder's document"
      $ error
      if error.name is "ValidationError"
        for field of error.errors
          @res.message "#{field} was missing.", "error"
      else
        @res.message "There was an error. Sorry !( <br />" + error.message, "error"
      # @bind stakeholder with error data
      return @res.redirect (
        if create then  "/stakeholders/__new"
        else            "/stakeholders/#{slug}"
      )

    # if everything is fine
    $ "New stakeholder document saved"
    @res.message "Thank you! You are good to go."
    @res.redirect "/"

module.exports = 
  "/stakeholders":
    get: ->
      Stakeholder.find (error, stakeholders) =>
        if error then throw error
        @bind "stakeholders", { stakeholders, title: "Stakeholders" }

    post: controller save
    
    "/__new":
      get: -> 
        data = 
          suggestions : {}
          scripts     : [
            "/assets/scripts/app/stakeholder.js"
          ]

        async.parallel [
          (done) ->
            Stakeholder
            .find()
            .distinct "groups", (error, groups) ->
              _.extend data.suggestions, { groups }
              done error
        ], (error) =>
          if error then throw error
          @bind "profile", data

        # Only let authenticated users in
        # if @req.session?.username? then 
        #   @bind "stakeholder"
        # else 
        #   @res.statusCode = 401
        #   @res.end "Not authenticated."

    "/:slug":
      get: controller (slug) ->
        async.waterfall [
          (done) =>
            # get stakeholder
            Stakeholder.findOne { slug }, (error, stakeholder) =>
              if stakeholder then done error, stakeholder
              else
                @res.statusCode = 404
                @bind "not-found", "Nobody at this address."
          (stakeholder, done) =>
            # get related issues
            Issue.aggregate [
              { $unwind: "$relations" }
              { $match: 
                "relations._id": stakeholder._id
                $or: [
                  {"relations.committed": true},
                  {"relations.affected" : true},
                  {"relations.concerned": true}
                ] 
              }
              { $sort: importance: -1 }
            ], (error, related) -> done error, { stakeholder, issues: { related } }
          # TODO: try to mark them in one aggregate call
          # http://docs.mongodb.org/manual/reference/aggregation/#exp._S_cond ?
          # (data, done) =>
          #   # get common issues
          #   agent = @req.session.stakeholder
          #   rids  = _.pluck data.related, '_id'
          #   Issue.aggregate [
          #     # Only those that are related to a stakeholder from previous step
          #     { $match: _id: $in: rids }
          #     { $unwind: "$relations" }
          #     # and that are related to acting stakeholder (agent)
          #     { $match: 
          #       "relations._id": agent._id
          #       $or: [
          #         {"relations.committed": true},
          #         {"relations.affected" : true},
          #         {"relations.concerned": true}
          #       ] 
          #     }
          #     { $sort: importance: -1 }
        ], (error, data) =>
          if error then throw error
          $ "Stakeholder data"
          $ data
          @bind "stakeholder", data

      "/profile":
        get: (slug) -> 
          # Try to DRY here. See `/__new`
          data = 
            suggestions: {}
            scripts     : [
              "/assets/scripts/app/stakeholder.js"
            ]

          async.parallel [
            
            # Get stakeholder
            (done) ->
              Stakeholder.findOne { slug }, (error, stakeholder) =>
                if stakeholder then _.extend data, { stakeholder }
                else
                  @res.statusCode = 404
                  @bind "not-found", "Nobody at this address."

                done error
            
            # get group suggestions
            (done) ->
              Stakeholder
              .find()
              .distinct "groups", (error, groups) ->
                _.extend data.suggestions, { groups }
                done error
          ], (error) =>
            if error then throw error
            @bind "profile", data

      post: controller save
