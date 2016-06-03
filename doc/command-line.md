Ocaml GPIO: watch value changes in GPIO
=======================================

Mandatory arguments
-------------------

### --gpio: Number of a GPIO device (ex: 42)

Mandatory, no default value. Can accept multiple devices.

Optional arguments
------------------

### --update-script: The path to a callback script

The callback script will receive environment variables for measure values. Please read ```doc/callback-script.md```

Default: ```/etc/ogpio/hook.sh```
