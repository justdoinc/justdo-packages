import { checkNpmVersions } from "meteor/tmeasday:check-npm-versions"

checkNpmVersions({
  'aws-sdk': '2.x.x'
}, 'justdoinc:justdo-aws-base')

aws_sdk = require "aws-sdk"
# Note
#
# We require "aws-sdk" but don't make use of it. We do it so when building
# Meteor will make this npm package available for this Meteor package.
#
# Without this, checkNpmVersions above won't work and it'll seem that the
# package doesn't exist
#
# XXX not clear if really doesn't exists/available or just not recognized by
# the peer dependency.

S3 = require "aws-sdk/clients/s3"

env = process.env

APP.aws =
  sdk: aws_sdk
  meta: new aws_sdk.MetadataService()

if not _.isEmpty(env.AWS_ACCESS_KEY_ID) and not _.isEmpty(env.AWS_SECRET_ACCESS_KEY)
  APP.logger.debug "[aws-base] Enabled"

  APP.aws.enabled = true
  APP.aws.S3 = new S3({apiVersion: '2006-03-01'})

else
  APP.logger.debug "[aws-base] Disabled"

  APP.aws.enabled = false
