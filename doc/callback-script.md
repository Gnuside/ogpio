Callback script
===============

Definition & purpose
--------------------

The callback script is the one defined by the --update-script parameter
of ogpio.

The script will be called each time the watched values change.

The script is run in a child process with no blocking between
successive execution. That means that if two occurences of the
script take many time, their execution can overlap.

Execution environment
---------------------

The callback script is executed with the same execution environment
as the main process, with the following added variables :

~~~
OGPIO_FILE_${gpio_id}_VALUE    : int (GPIO value)
OGPIO_FILE_${gpio_id}_DURATION : int (Interval between current change and previous change in milliseconds)
~~~

Where :

 - ${gpio_id} is the ID of the GPIO
