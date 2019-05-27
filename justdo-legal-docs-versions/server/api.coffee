_.extend JustdoLegalDocsVersionsApi,
    getLegalDocsReportForUserDoc: (user_doc) ->
      # Returns an object with two properties: status, docs
      #
      # status is either true or false - false means some of the required legal docs
      # haven't been signed or need re-signing due to update. True means
      # all is docs were signed and are up-to-date.
      # 
      # The docs sub-object provides more details about the status.
      # It'll have legal docs ids as properties. The
      # value for each doc can be one of:
      #
      # "NOT-SIGNED" - the doc was never signed
      # "SIGNED" - Signed
      # "OUT-DATED" - Old version of this doc signed, user need to sign this document again

      # Init a report object.
      report =
        status: false
        docs: {}

      for doc_id, doc_info of JustdoLegalDocsVersions
        report.docs[doc_id] = "NOT-SIGNED"

      if not (signed_legal_docs = user_doc?.signed_legal_docs)?
        # User didn't sign any doc
        return report

      all_required_docs_signed_and_up_to_date = true
      for doc_id of report.docs
        if not (signed_doc = signed_legal_docs[doc_id])?
          if JustdoLegalDocsVersions[doc_id].signature_required == true
            # User didn't sign this required document but signature is required
            all_required_docs_signed_and_up_to_date = false

          continue

        if not signed_doc.version?
          # Very old documents might have different format for the signed_legal_docs sub-document.
          # In such case, we don't try to parse the old format, we regard the docs as not signed.
          # The user will have to sign them again.

          continue      

        if signed_doc.version.version == JustdoLegalDocsVersions[doc_id].version
          report.docs[doc_id] = "SIGNED"
        else
          # Due to issue discovered on Android, we report falsely that all docs are
          # up to date. Un-comment the line below somewhere around mid-march 2019.
          # Remove the report.docs[doc_id] = "SIGNED" line.
          #
          # all_required_docs_signed_and_up_to_date = false

          # report.docs[doc_id] = "OUT-DATED"

          report.docs[doc_id] = "SIGNED"

      report.status = all_required_docs_signed_and_up_to_date

      return report