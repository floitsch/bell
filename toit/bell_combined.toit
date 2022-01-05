import .bell_trigger as trigger
import .bell as bell

main:
  task:: trigger.main

  task::
    while true:
      bell.listen --blocking
