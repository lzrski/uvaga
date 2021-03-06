# Stakeholder view
# ================
#
# Differs a lot depending on context.
#
# It can be used to
# 1. Create a new profile in `/stakeholders/__new`
# 2. Update own profile
# 3. View / update someone elses profile
#
# TODO: make this form a helper and control it with attributes.
# 

module.exports = -> 

  # No `@stakeholder` indicates that we are in `/stakeholders/__new`
  # TODO: Unite it! Anybody can edit anybody's profile, but before the changes will be saved, stakeholder must aggree for them.  

  if @stakeholder
    @form_context = @stakeholder
    if @stakeholder.email is @username
      mode        = "update"
      form_title  = translate "Your profile"
    else
      mode        = "view"
      form_title  = translate "Profile of #{@stakeholder.name}" 
  else # We are in `/stakeholders/__new`
    @form_context = { email: @username }
    mode          = "create"
    form_title    = translate "Your profile"
    div class: "hero-unit", ->
      h1 translate "Hello! Thanks for authenticating."
      p  translate "It seems to be your first time here. Please fill your profile beolw. We need at least your name, so that we know how to address you :)"

  form {
    class: "profile #{mode} form-horizontal"
    method: "post"
    action: if mode is "create" then "/stakeholders" else "/stakeholders/" + @form_context.slug
  }, ->
    fieldset ->
      legend form_title
      
      # ## Mandatory info
      #
      # * E-mail address
      # This is for information only.
      # It will be filtered out in controller anyway. (?)
      # 
      if mode is "create" then div class: "control-group", ->

        label
          class: "control-label"
          for: "email"
          translate "E-mail"
        div class: "controls", ->
          textbox
            name: "email"
            disabled: true
            class: "span3"

      # * Name
      # The only thing we really need to begin
      # 
      div class: "control-group", ->
        label
          class: "control-label"
          for: "name"
          translate "Name"
        div class: "controls", ->
          textbox
            name      : "name"
            class     : "span3"
            required  : true
            autofocus : true

      # ## Optional info
      #
      if mode is "create"
        div class: "controls", ->
          p class: "help-block", ->
            strong translate "That's all we really need to begin."
            do br
            translate "Would you like to tell us more?"

      # ## Image
      #
      div class: "control-group", ->
        label
          class: "control-label"
          for: "image"
          translate "Image"
        div class: "controls", ->
          image = if mode is "create" then @suggestions.image else @stakeholder.image
          div style: "float: left", ->
            select
              id    : "shape"
              name  : "shape"
              title : translate "Symbol"
              ->
                for shape in @suggestions.shapes
                  option
                    selected: shape is image.shape
                    shape 
                  
            do br

            select
              id    : "color"
              name  : "color"
              title : translate "Color"
              ->
                for color in @suggestions.colors
                  option
                    selected: color is image.color
                    color
            do br

            select
              id    : "background"
              name  : "background"
              title : translate "Background"
              ->
                for color in @suggestions.colors
                  option
                    selected: color is image.background
                    color

          img id: "avatar", width: 200, heigh: 200, style: "float: left"



      # * Telephone
      #
      div class: "control-group", ->
        label
          class: "control-label"
          for: "telephone"
          translate "Telephone"
        div class: "controls", ->
          textbox
            name: "telephone"
            class: "span3"

      # * Occupation
      #
      div class: "control-group", ->
        label
          class: "control-label"
          for: "occupation"
          translate "Occupation"
        div class: "controls", ->
          textbox
            name: "occupation"
            class: "span3"

      # * Groups
      # Organisations, companies, institutions, departments etc.
      #
      div class: "control-group", ->
        label
          class: "control-label"
          for: "groups"
          translate "Groups"
        div class: "controls", ->
          select
            id          : "groups"
            name        : "groups"
            placeholder : translate "Select one or more groups..."
            multiple    : true
            class       : "span3"
            ->
              for group in @suggestions.groups
                option 
                  value: group
                  selected: @form_context.groups? and group in @form_context.groups
                  group 

      div class: "control-group", ->
        div class: "controls", ->
          button
            type  : "submit"
            class : "btn btn-success"
            ->
              i class: "icon-ok-sign", " "
              translate "Done!"
          if mode is "create" then a
            class           : "btn"
            "data-signout"  : true
            ->
              i class: "icon-remove-sign", " "
              translate "No thanks."


    