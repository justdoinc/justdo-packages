# Mergeable Environment Variables Configuration
#
# Defines which environment variables can be merged when testing
# multiple packages together, and how to merge them.
#
# Example:
#   Package A: BESPOKE_PACKS=zim
#   Package B: BESPOKE_PACKS=chat
#   Merged:    BESPOKE_PACKS=zim,chat
#
# Variables not listed here will cause a conflict error if two
# packages try to set them to different values.

@MERGEABLE_ENV_VARS =
  # BESPOKE_PACKS is comma-separated and can be merged
  BESPOKE_PACKS:
    type: "comma-separated"
    merge: (a, b) ->
      # Split both values, merge uniquely, filter empty strings
      partsA = if a then a.split(",").map((s) -> s.trim()).filter((s) -> s) else []
      partsB = if b then b.split(",").map((s) -> s.trim()).filter((s) -> s) else []
      
      # Combine uniquely
      combined = []
      for part in partsA
        combined.push(part) unless part in combined
      for part in partsB
        combined.push(part) unless part in combined
      
      combined.join(",")

  # Add other mergeable vars here as needed
  # Example:
  # FEATURE_FLAGS:
  #   type: "comma-separated"
  #   merge: (a, b) -> ...
