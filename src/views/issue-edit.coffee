# Issue editor view
# =================
#
# Differs a lot depending on context.
#
# It can be used to
# 1. Create a new issue in `/issues/__new`
# 2. Update an issue
#

module.exports = -> 

  # No `@issue` indicates that we are in `/issues/__new`

  # Are we in /issues/__new?
  create = not @issue?

  if create then  @form_context = {}
  else            @form_context = @issue

  div class: "page-header", ->
    h1 -> 
      if create
        i class: "icon-asterisk"
        text " New"
      else
        text "# " + @form_context.number

      small ->
        text " issue "
        unless create
          div class: "pull-right", ->
            # Configure counters of affected, concerned and committed stakeholders
            for counter in [
              {
                name  : "affected"
                icon  : "group"
                class : "warning"
                tip   : "number of affected stakeholders."
              }
              { 
                name  : "concerned"
                icon  : "warning-sign"
                class : "important"
                tip   : "number of stakeholders who consider this issue important."
              }
              { 
                name  : "committed"
                icon  : "eye-open"
                class : "info"
                tip   : "number of stakeholders commited to work on that."
              }
            ]
              a 
                href  : "#"
                class : "badge " + (if @relation[counter.name] then "badge-" + counter.class)
                data  :
                  toggle: "tooltip"
                  title : counter.tip
                ->
                  i class: "icon-#{counter.icon}", " "
                  text @form_context[counter.name]
              text " "


  div class: "row", ->
    div class: "span9", id: "form", ->
      form
        class: "issue form"
        method: "post"
        action: if create then "/issues" else "/issues/#{@issue.number}"
        ->

          div class: "row", ->
            div class: "span9", ->
              textarea
                name: "description"
                class: "span9"
                style: "resize: vertical",
                @form_context.description

          ###
          Scopes
          
          What is the scope of this issue? E.g. 
              * Whole organisation
              * A place
              * A process
              * A group of people

          Use it like tags.
          ###
          div class: "row", ->
            div class: "span9", ->
              label
                class: "control-label"
                for: "groups"
                "scopes"
              select
                id          : "scopes"
                name        : "scopes"
                placeholder : "Select one or more scopes of this issue..."
                multiple    : true
                class       : "span9"
                ->
                  for scope in @suggestions.scopes
                    option 
                      value: scope
                      selected: @form_context.scopes? and scope in @form_context.scopes
                      scope

          div class: "row", ->
            div class: "span9", style: "margin-top: 10px", ->
              button
                type  : "submit"
                class : "btn btn-success"
                ->
                  i class: "icon-ok-sign"
                  " Done!"
              text " "
              a
                class           : "btn"
                href            : if create then "/" else "/issues/#{@issue.number}"
                ->
                  i class: "icon-remove-sign"
                  " Cancel."

      unless create
        for comment in @issue.comments.reverse()
          div class: "media well", id: "comment-#{comment.id}", ->
            a class: "pull-left", ->
              img
                class: "media-object"
                style: "max-width: 64px; max-heigh: 64px"
                # TODO: Author can be null, if corresponding stakeholder document was removed from db. Take care of that in model or controller
                src: comment.author?.image ? "//fillmurray.com/64/64"
            div class: "media-body", ->
              h6 ->
                text comment.author.name + " "
                small class: "muted", comment._id.getTimestamp().toLocaleDateString()
              p comment.content

    unless create
      div class: "span3", id: "aside", ->
        h4 "Commited stakeholders"
        # TODO: Author can be null, if corresponding stakeholder document was removed from db. Take care of that in model or controller
        for stakeholder in @commitee when stakeholder?
          div class: "media well", id: "commited-stakeholder-#{stakeholder.id}", ->
            a class: "pull-left", ->
              img
                class: "media-object"
                style: "max-width: 48px; max-heigh: 48px"
                src: stakeholder.image ? "//fillmurray.com/48/48"
            div class: "media-body", ->
              p ->
                strong -> a
                  href  : "/stakeholders/" + stakeholder.slug
                  title : stakeholder.name
                  stakeholder.name
                do br
                small ([stakeholder.occupation].concat stakeholder.groups).join ", "
              p ->
                for label, field of {
                  "phone-sign": "telephone"
                  "envelope"  : "email"
                }
                  if stakeholder[field]? 
                    small ->
                      i class: "icon-#{label}", " "
                      text stakeholder[field]
                    do br
