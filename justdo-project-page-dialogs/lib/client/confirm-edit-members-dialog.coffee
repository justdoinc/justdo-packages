Template.confirm_edit_members_dialog.helpers
  usersText: (member_ids) ->
    html = ""
    i = 0
    for member_id in member_ids
      if i == 3
        html += " and another #{member_id.length - 3} users"
        break

      if i != 0
        html += ", "
        
      html += JustdoHelpers.displayName member_id
      i = i + 1

    return html
