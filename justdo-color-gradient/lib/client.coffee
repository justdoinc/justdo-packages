settings =
  segments:
    [ # Alg assumes segments are sorted by end_point asc

      #
      # Take 3
      #

      # Gray
      {
        start_color: [237, 237, 237]
        end_color: [194, 194, 194]
        end_point: 15 # inclusive
      }
      {
        start_color: [194, 194, 194]
        end_color: [122, 122, 122]
        end_point: 24
      }

      # Yellow
      {
        start_color: [253, 230, 194]
        end_color: [245, 203, 136]
        end_point: 40
      }
      {
        start_color: [245, 203, 136]
        end_color: [237, 146, 81]
        end_point: 75
      }

      # Red
      {
        start_color: [244, 116, 115]
        end_color: [230, 76, 76]
        end_point: 85
      }
      {
        start_color: [230, 76, 76]
        end_color: [133, 0, 0]
        end_point: 100 # alg doesn't deal with case last end_point isn't 100
      }

      #
      # Take 2
      #

      # # Gray
      # {
      #   start_color: [237, 237, 237]
      #   end_color: [194, 194, 194]
      #   end_point: 15 # inclusive
      # }
      # {
      #   start_color: [194, 194, 194]
      #   end_color: [122, 122, 122]
      #   end_point: 25
      # }

      # # Green
      # {
      #   start_color: [169, 235, 196]
      #   end_color: [67, 212, 128]
      #   end_point: 35
      # }
      # {
      #   start_color: [67, 212, 128]
      #   end_color: [2, 158, 71]
      #   end_point: 50
      # }

      # # Yellow
      # {
      #   start_color: [253, 230, 194]
      #   end_color: [245, 203, 136]
      #   end_point: 65
      # }
      # {
      #   start_color: [245, 203, 136]
      #   end_color: [237, 146, 81]
      #   end_point: 75
      # }

      # # Red
      # {
      #   start_color: [255, 150, 150]
      #   end_color: [230, 76, 76]
      #   end_point: 85
      # }
      # {
      #   start_color: [230, 76, 76]
      #   end_color: [133, 0, 0]
      #   end_point: 100 # alg doesn't deal with case last end_point isn't 100
      # }

      #
      # Take 1
      #
      # {
      #   start_color: [237, 237, 237]
      #   end_color: [237, 237, 237]
      #   end_point: 1 # inclusive
      # }
      # {
      #   start_color: [249, 225, 156]
      #   end_color: [237, 145, 81]
      #   end_point: 50
      # }
      # {
      #   start_color: [237, 145, 81]
      #   end_color: [236, 87, 86]
      #   end_point: 100 # alg doesn't deal with case last end_point isn't 100
      # }

      #
      # Very old
      #
      # {
      #   start_color: [255, 255, 255]
      #   end_color: [250, 250, 180]
      #   end_point: 49 # inclusive
      # }
      # {
      #   start_color: [250, 250, 180]
      #   end_color: [250, 205, 155]
      #   end_point: 100
      # }
    ]

JustdoColorGradient =
  _segments_def:
    [
      {
        # Default, just gray.
        start_color: [237, 237, 237]
        end_color: [237, 237, 237]
      }
    ]
  _segments_quick_ref: null # might be premature optimizations, but felt right to me , -Daniel
  loadSegments: (segments_def) ->
    # No validations are done on segments_def, assumed to be well structured.
    # Take the settings.segemnets above as a reference for well structured
    # segments input

    new_segments_def = []
    new_segments_quick_ref = []

    last_end_point = -1
    for segment_def in segments_def
      segment_def = _.extend {}, segment_def # avoid changing original

      segment_def.start_point = last_end_point + 1

      segment_def.segments_points_count = (segment_def.end_point - segment_def.start_point) + 1 # + 1 since end_point is inclusive

      last_end_point = segment_def.end_point

      new_segments_def.push segment_def

      # Add to segments quick ref
      for i in [segment_def.start_point..segment_def.end_point]
        new_segments_quick_ref.push segment_def

    @_segments_def = new_segments_def
    @_segments_quick_ref = new_segments_quick_ref

    return

# Load default settings
JustdoColorGradient.loadSegments settings.segments

_.extend JustdoColorGradient,
  _getColor: (level) ->
    if not level? or level < 0
      level = 0
    if level > 100
      level = 100

    level = parseInt(level) # ensure integer.

    segment_def = JustdoColorGradient._segments_quick_ref[level]

    {start_color, end_color, segments_points_count} = segment_def

    normalized_level = level - segment_def.start_point

    level_percent = normalized_level / segments_points_count

    color = []
    for i in [0..2]
      direction = 1
      if start_color[i] > end_color[i]
        direction = -1

      segment_distance = Math.abs(end_color[i] - start_color[i])
      level_segment_distance = segment_distance * level_percent

      color.push Math.floor(start_color[i] + (level_segment_distance *  direction))

    return color

  getColorHex: (level) ->
    hex = "#"

    for color in @_getColor(level)
      color_hex = color.toString(16)
      hex += if color_hex.length == 1 then "0#{color_hex}" else color_hex

    return hex

  getColorRgbString: (level) -> "rgb(#{@_getColor(level).join(",")})"
