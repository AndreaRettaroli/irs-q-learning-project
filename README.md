# irs-q-learning-project

To run this project you need to use [ARGoS](https://www.argos-sim.info/) 
To install ARGoS follow [this steps](https://www.argos-sim.info/core.php) 

Ensure that your machine or virtual machine has all the necessary packages specified [here](https://github.com/ilpincy/argos3).

In my case i used Ubuntu 20.04 LTS 64bit virtual machine.

To run train you need to create Qtable 

```
    lua ./create_Q-table.lua Qtable-circuit.csv 256 3
``` 

This 3 params are specific for this code, 253 3 are Qtable dimensions, Qtable-circuit.csv is the filename, if you change it you need to change it also in your code.

```
    ./train-script.sh -f ./circuit-learning.argos -e 100
```
params e is epochs number
```
    ./test-script.sh -a ./circuit-testing.argos -s test-results.txt -e 100
```

test-results.txt is the name of the output file of results.
params e is epochs number.