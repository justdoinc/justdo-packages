contact_request_recipients = ["info@justdo.com"]

#
# Schema
#

Schema =
  name:
    label: "Name"
    type: String
    min: 1
    max: 100
  email:
    label: "Email"
    type: String
    regEx: JustdoHelpers.common_regexps.email
    min: 1
    max: 100
  message:
    label: "Message"
    type: String
    optional: true
    max: 10000
  tz:
    label: "User time zone"
    type: String
    optional: true
    max: 50
  version:
    type: String
    optional: true
  root_url:
    type: String
    optional: true
  campaign:
    type: String
    optional: true
  source_template: 
    type: String
    optional: true
  tel:
    type: String
    optional: true
  signed_legal_docs:
      optional: true
      type: Object
    "signed_legal_docs.terms_conditions":
      optional: true
      type: JustdoAccounts.standard_legal_doc_structure
    "signed_legal_docs.privacy_policy":
      optional: true
      type: JustdoAccounts.standard_legal_doc_structure
  createdAt:
    label: "Created"

    type: Date
    autoValue: ->
      if this.isInsert
        return new Date
      else if this.isUpsert
        return {$setOnInsert: new Date}
      else
        this.unset()
  updatedAt:
    label: "Modified"

    type: Date
    denyInsert: true
    optional: true
    autoValue: ->
      if this.isUpdate
        return new Date()

DemoRequests = new Mongo.Collection "demo_requests"

DemoRequests.attachSchema Schema

APP.collections.DemoRequests = DemoRequests

#
# Main
#

DemoDetailsSchema =
  JustdoHelpers.getCollectionSchema APP.collections.DemoRequests,
    without_keys: ["createdAt", "updatedAt"]

Meteor.methods
  "contactRequest": (request_details) ->
    # <LEGAL DOCS PROCESSING> (for case we'll bring the checkbox back)
    #
    # legal_docs_signed = request_details.legal_docs_signed_names

    # delete request_details.legal_docs_signed_names

    # if "terms_conditions" not in legal_docs_signed
    #   throw new Meteor.Error("invalid-argument", "Terms and conditions must be approved to send a contact request")

    # if "privacy_policy" not in legal_docs_signed
    #   throw new Meteor.Error("invalid-argument", "Privacy policy must be approved to send a contact request")

    # # check legal docs exist
    # check(legal_docs_signed, [String])
    # for legal_doc_name in legal_docs_signed
    #   if not (JustdoLegalDocsVersions[legal_doc_name])?
    #     throw new Meteor.Error("unknown-legal-doc", "Unknown legal doc #{legal_doc_name}")
    
    # new_signed_legal_docs = {}
    # for legal_doc_name in legal_docs_signed
    #   # Note Including the legal doc issuance date as part of the info saved to
    #   # the user doc, instead of the version alone as a string val is an historical
    #   # mistake, that we endure for now.
    #   version = _.pick JustdoLegalDocsVersions[legal_doc_name], "version", "date"

    #   new_signed_legal_docs[legal_doc_name] =
    #     datetime_signed: new Date()
    #     version: version
    
    # request_details.signed_legal_docs = new_signed_legal_docs
    #
    # </LEGAL DOCS PROCESSING>

    if not process.env.MAIL_URL
      throw new Meteor.Error("smtp-not-set", "This environment doesn't have email server (smtp) configured. Please reach out to us using the emails below.")

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        DemoDetailsSchema,
        request_details,
        {throw_on_error: true}
      )

    request_details = cleaned_val

    _.extend request_details, {version: process.env.APP_VERSION, root_url: process.env.ROOT_URL}

    previous_requests = APP.collections.DemoRequests.find({}, {sort: {createdAt: -1}, limit: 5}).fetch()
    _id = APP.collections.DemoRequests.insert(request_details)

    template_data = _.extend {}, request_details, {previous_requests, _id}

    subject = "New contact request"

    if (message = request_details.message)?
      subject += ": #{request_details.message.substr(0,80)}"

    for email in contact_request_recipients
      JustdoEmails.buildAndSend
        to: email
        template: "contact-request"
        template_data: template_data
        subject: subject

    return true