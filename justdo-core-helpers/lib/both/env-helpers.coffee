_.extend JustdoCoreHelpers,
  isBespokePackageEnabled: (env, bespoke_package_id) ->
    enabled_bespoke_packs = JustdoHelpers.getNonEmptyValuesFromCsv env.BESPOKE_PACKS
    return bespoke_package_id in enabled_bespoke_packs