os = require("os")

_.extend JustdoHelpers,
  getAllCpuCoresAverageUtilizationPercent: (cb) ->
    # Based on https://gist.github.com/bag-man/5570809

    cpuAverage = ->
      # Initialise sum of idle and time of cores and fetch CPU info
      totalIdle = 0
      totalTick = 0

      cpus = os.cpus()

      # Loop through CPU cores
      i = 0
      len = cpus.length
      while i < len
        # Select CPU core
        cpu = cpus[i]

        # Total up the time in the cores tick
        for type of cpu.times
          totalTick += cpu.times[type]

        # Total up the idle time of the core
        totalIdle += cpu.times.idle
        i++

      # Return the average Idle and Tick times
      return {
        idle: totalIdle / cpus.length
        total: totalTick / cpus.length
      }

    # Grab first CPU Measure
    startMeasure = cpuAverage()

    # Set delay for second Measure

    setTimeout ->
      # Grab second Measure
      endMeasure = cpuAverage()

      # Calculate the difference in idle and total time between the measures
      idleDifference = endMeasure.idle - (startMeasure.idle)
      totalDifference = endMeasure.total - (startMeasure.total)

      # Calculate the average percentage CPU usage
      percentageCPU = 100 - (~ ~(100 * idleDifference / totalDifference))

      cb(percentageCPU)

      return
    , 100

    return